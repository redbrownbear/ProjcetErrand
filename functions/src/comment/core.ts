/**
 * 부탁 글 댓글 — 모든 부탁(동네·해외·가는 김에)에 공개 댓글을 단다.
 * "이것도 부탁돼요?" · "몇 시쯤 가세요?" 같은 질문을 지원·신청 전에 주고받는 곳이다.
 *
 * 앱은 댓글을 직접 못 쓴다(보안 규칙). 이 함수가 연락처(전화번호·계좌·이메일·링크)를 가리고 저장한 뒤 알린다.
 *  - 남이 댓글 → 글쓴이에게
 *  - 글쓴이가 댓글 → 이 글에 댓글을 단 다른 사람들에게(최대 10명)
 */
import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { maskContact } from '../chat/mask';
import { deliver, PushSender } from '../notify/deliver';
import { blockedMessage, findBlocked, loadPolicy } from '../safety/policy';
import { assertNotBlocked, assertNotSuspended, nicknameOf, userRef } from '../shared/guards';
import { docId, fields } from '../shared/input';
import { C } from '../shared/paths';

export const MAX_COMMENT = 300;
const MAX_NOTIFY = 10;

export async function addComment(db: Firestore, uid: string, data: unknown, push?: PushSender) {
  const input = fields(data);
  const rid = docId(input.requestId, 'requestId');
  const raw = typeof input.text === 'string' ? input.text.trim() : '';
  if (!raw) throw new HttpsError('invalid-argument', '댓글을 입력해 주세요.');
  if (raw.length > MAX_COMMENT) throw new HttpsError('invalid-argument', `댓글은 ${MAX_COMMENT}자까지예요.`);

  // 댓글로 금지 품목을 부탁하는 것도 막는다(A20)
  const word = findBlocked(raw, await loadPolicy(db));
  if (word) throw new HttpsError('invalid-argument', blockedMessage(word));

  const reqRef = db.collection(C.requests).doc(rid);
  const { text, masked } = maskContact(raw);

  const saved = await db.runTransaction(async (tx) => {
    const [req, me] = await Promise.all([tx.get(reqRef), tx.get(userRef(db, uid))]);
    if (!req.exists) throw new HttpsError('not-found', '글을 찾을 수 없어요.');
    assertNotSuspended(me);
    const ownerUid = req.get('ownerUid') as string;
    if (ownerUid !== uid) await assertNotBlocked(tx, db, ownerUid, uid, '이 글에는 댓글을 남길 수 없어요.');
    const author = nicknameOf(me);
    const ref = reqRef.collection(C.comments).doc();
    tx.create(ref, { uid, author, text, masked, createdAt: Timestamp.now() });
    tx.update(reqRef, { commentCount: FieldValue.increment(1) });
    return { id: ref.id, ownerUid, author, title: (req.get('title') as string) || '부탁' };
  });

  if (push) {
    const short = saved.title.length > 20 ? saved.title.slice(0, 20) + '…' : saved.title;
    let to: string[];
    if (saved.ownerUid !== uid) {
      to = [saved.ownerUid];
    } else {
      const prev = await reqRef.collection(C.comments).orderBy('createdAt', 'desc').limit(50).get();
      to = [...new Set(prev.docs.map((d) => d.get('uid') as string).filter((u) => u && u !== uid))].slice(0, MAX_NOTIFY);
    }
    await Promise.all(
      to.map((who) =>
        deliver(
          db,
          push,
          { to: who, kind: 'request.comment', title: `"${short}"에 새 댓글`, body: `${saved.author}: ${text.slice(0, 60)}`, requestId: rid },
          `comment_${saved.id}_${who}`,
        ),
      ),
    );
  }
  return { id: saved.id, masked };
}
