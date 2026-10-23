/**
 * 최소 채팅 (결정 5) — 거래 당사자 두 사람만, 텍스트와 사진(A38).
 * 메시지는 서버가 가리기(mask.ts)를 거쳐 trades/{tradeId}/messages 에 쓴다. 앱은 직접 쓰지 못한다(보안 규칙 v2).
 * 사진은 앱이 Storage `trades/{tradeId}/{uid}/{파일}`(거래 사진과 같은 폴더 · 같은 규칙)에 올리고 경로만 보낸다.
 */
import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { deliver, PushSender } from '../notify/deliver';
import { maskContact } from './mask';

export const MAX_MESSAGE = 1000;
/** 거래마다 채팅 사진 상한 */
export const CHAT_PHOTO_LIMIT = 30;

export async function sendMessage(db: Firestore, uid: string, data: unknown, push?: PushSender) {
  const input = (typeof data === 'object' && data !== null ? data : {}) as Record<string, unknown>;
  const tradeId = input.tradeId;
  if (typeof tradeId !== 'string' || !tradeId || tradeId.includes('/') || tradeId.length > 128) {
    throw new HttpsError('invalid-argument', 'tradeId 값이 올바르지 않아요.');
  }
  const raw = typeof input.text === 'string' ? input.text.trim() : '';
  const photoPath = input.photoPath;
  if (photoPath !== undefined && photoPath !== null) {
    // 내 폴더에 올린 파일만(남의 사진 경로를 끌어오지 못하게) — addTradePhoto와 같은 검사
    const prefix = `trades/${tradeId}/${uid}/`;
    if (
      typeof photoPath !== 'string' ||
      !photoPath.startsWith(prefix) ||
      photoPath.length > 300 ||
      photoPath.slice(prefix.length).includes('/') ||
      photoPath.includes('..')
    ) {
      throw new HttpsError('invalid-argument', '사진 경로가 올바르지 않아요.');
    }
  }
  const photo = typeof photoPath === 'string' ? photoPath : null;
  if (!raw && !photo) throw new HttpsError('invalid-argument', '메시지를 입력해 주세요.');
  if (raw.length > MAX_MESSAGE) throw new HttpsError('invalid-argument', `메시지는 ${MAX_MESSAGE}자까지예요.`);

  const tradeRef = db.collection('trades').doc(tradeId);
  const { text, masked } = maskContact(raw);

  const sent = await db.runTransaction(async (tx) => {
    const [trade, me] = await Promise.all([tx.get(tradeRef), tx.get(db.collection('users').doc(uid))]);
    if (!trade.exists) throw new HttpsError('not-found', '거래를 찾을 수 없어요.');
    const requesterUid = trade.get('requesterUid') as string;
    const helperUid = trade.get('helperUid') as string;
    if (uid !== requesterUid && uid !== helperUid) throw new HttpsError('permission-denied', '이 거래의 당사자만 대화할 수 있어요.');
    if (trade.get('status') === 'cancelled') throw new HttpsError('failed-precondition', '취소된 거래에는 메시지를 보낼 수 없어요.');
    if (me.get('suspended') === true) throw new HttpsError('permission-denied', '내 계정은 지금 이용이 제한돼 있어요.');

    if (photo && ((trade.get('chatPhotoCount') as number | undefined) ?? 0) >= CHAT_PHOTO_LIMIT) {
      throw new HttpsError('resource-exhausted', `채팅 사진은 거래마다 ${CHAT_PHOTO_LIMIT}장까지예요.`);
    }

    const now = Timestamp.now();
    const msgRef = tradeRef.collection('messages').doc();
    tx.create(msgRef, { senderUid: uid, text, masked, ...(photo ? { photoPath: photo } : {}), createdAt: now });
    tx.update(tradeRef, {
      lastMessage: { text: text ? text.slice(0, 60) : '사진', by: uid, at: now },
      [`unread.${uid === requesterUid ? helperUid : requesterUid}`]: FieldValue.increment(1),
      ...(photo ? { chatPhotoCount: FieldValue.increment(1) } : {}),
    });
    return {
      id: msgRef.id,
      to: uid === requesterUid ? helperUid : requesterUid,
      title: (trade.get('title') as string) || '부탁',
      requestId: (trade.get('requestId') as string) ?? '',
    };
  });

  if (push) {
    // 채팅은 알림함에 쌓지 않고 푸시만 보낸다(대화마다 알림함이 넘치지 않게)
    await deliver(
      db,
      push,
      { to: sent.to, kind: 'chat.message', title: `"${sent.title}" 새 메시지`, body: text ? text.slice(0, 80) : '사진을 보냈어요', requestId: sent.requestId, tradeId },
      `chat_${sent.id}`,
      { store: false },
    );
  }
  return { id: sent.id, masked };
}

/** 내가 읽었음을 표시 — 상대 메시지 개수 표시를 0으로 */
export async function markChatRead(db: Firestore, uid: string, data: unknown) {
  const tradeId = (data as Record<string, unknown> | null)?.tradeId;
  if (typeof tradeId !== 'string' || !tradeId || tradeId.includes('/')) throw new HttpsError('invalid-argument', 'tradeId 값이 올바르지 않아요.');
  const ref = db.collection('trades').doc(tradeId);
  const trade = await ref.get();
  if (!trade.exists) throw new HttpsError('not-found', '거래를 찾을 수 없어요.');
  if (uid !== trade.get('requesterUid') && uid !== trade.get('helperUid')) throw new HttpsError('permission-denied', '이 거래의 당사자가 아니에요.');
  // 이미 0이면 쓰지 않는다 — 거래 문서가 바뀌면 두 사람의 구독과 onTradeWrite가 모두 깨어난다
  const unread = (trade.get('unread') as Record<string, unknown> | undefined)?.[uid];
  if (typeof unread !== 'number' || unread === 0) return { ok: true };
  await ref.update({ [`unread.${uid}`]: 0 });
  return { ok: true };
}
