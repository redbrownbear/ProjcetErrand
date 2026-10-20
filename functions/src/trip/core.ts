/**
 * '가는 김에' 글의 댓글 — 다른 이웃이 "이것 좀 부탁해요" / "제가 도와드릴게요"를 남기는 곳.
 *
 * 글(tripPosts/{id})은 앱이 직접 쓰고(보안 규칙 화이트리스트), 댓글은 이 함수만 쓴다.
 * 공개 댓글이라 채팅과 같은 가리기(전화번호·계좌·이메일·링크)를 거치고, 글쓴이에게 알림을 보낸다.
 */
import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { maskContact } from '../chat/mask';
import { deliver, PushSender } from '../notify/deliver';

export const MAX_COMMENT = 300;

export async function addTripComment(db: Firestore, uid: string, data: unknown, push?: PushSender) {
  const input = (typeof data === 'object' && data !== null ? data : {}) as Record<string, unknown>;
  const postId = input.postId;
  if (typeof postId !== 'string' || !postId || postId.includes('/') || postId.length > 64) {
    throw new HttpsError('invalid-argument', 'postId 값이 올바르지 않아요.');
  }
  const raw = typeof input.text === 'string' ? input.text.trim() : '';
  if (!raw) throw new HttpsError('invalid-argument', '댓글을 입력해 주세요.');
  if (raw.length > MAX_COMMENT) throw new HttpsError('invalid-argument', `댓글은 ${MAX_COMMENT}자까지예요.`);

  const postRef = db.collection('tripPosts').doc(postId);
  const { text, masked } = maskContact(raw);

  const saved = await db.runTransaction(async (tx) => {
    const [post, me] = await Promise.all([tx.get(postRef), tx.get(db.collection('users').doc(uid))]);
    if (!post.exists) throw new HttpsError('not-found', '글을 찾을 수 없어요. 지워졌을 수 있어요.');
    if (me.get('suspended') === true) throw new HttpsError('permission-denied', '내 계정은 지금 이용이 제한돼 있어요.');
    const ownerUid = post.get('ownerUid') as string;
    if (ownerUid !== uid) {
      const blocked = await tx.get(db.collection('users').doc(ownerUid).collection('blocks').doc(uid));
      if (blocked.exists) throw new HttpsError('permission-denied', '이 글에는 댓글을 남길 수 없어요.');
    }

    const nickname = me.get('nickname');
    const author = typeof nickname === 'string' && nickname.trim() ? nickname.trim().slice(0, 20) : '이웃';
    const ref = postRef.collection('comments').doc();
    tx.create(ref, { uid, author, text, masked, createdAt: Timestamp.now() });
    tx.update(postRef, { commentCount: FieldValue.increment(1) });
    return { id: ref.id, ownerUid, author, title: (post.get('title') as string) || '가는 김에' };
  });

  if (push && saved.ownerUid !== uid) {
    await deliver(
      db,
      push,
      { to: saved.ownerUid, kind: 'trip.comment', title: `"${saved.title}"에 댓글`, body: `${saved.author}: ${text.slice(0, 60)}`, requestId: '', tripId: postId },
      `trip_${saved.id}`,
    );
  }
  return { id: saved.id, masked };
}
