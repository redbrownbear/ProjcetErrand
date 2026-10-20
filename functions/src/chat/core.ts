/**
 * 최소 채팅 (결정 5) — 거래 당사자 두 사람만, 텍스트만.
 * 메시지는 서버가 가리기(mask.ts)를 거쳐 trades/{tradeId}/messages 에 쓴다. 앱은 직접 쓰지 못한다(보안 규칙 v2).
 */
import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { deliver, PushSender } from '../notify/deliver';
import { maskContact } from './mask';

export const MAX_MESSAGE = 1000;

export async function sendMessage(db: Firestore, uid: string, data: unknown, push?: PushSender) {
  const input = (typeof data === 'object' && data !== null ? data : {}) as Record<string, unknown>;
  const tradeId = input.tradeId;
  if (typeof tradeId !== 'string' || !tradeId || tradeId.includes('/') || tradeId.length > 128) {
    throw new HttpsError('invalid-argument', 'tradeId 값이 올바르지 않아요.');
  }
  const raw = typeof input.text === 'string' ? input.text.trim() : '';
  if (!raw) throw new HttpsError('invalid-argument', '메시지를 입력해 주세요.');
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

    const now = Timestamp.now();
    const msgRef = tradeRef.collection('messages').doc();
    tx.create(msgRef, { senderUid: uid, text, masked, createdAt: now });
    tx.update(tradeRef, {
      lastMessage: { text: text.slice(0, 60), by: uid, at: now },
      [`unread.${uid === requesterUid ? helperUid : requesterUid}`]: FieldValue.increment(1),
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
      { to: sent.to, kind: 'chat.message', title: `"${sent.title}" 새 메시지`, body: text.slice(0, 80), requestId: sent.requestId, tradeId },
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
  await ref.update({ [`unread.${uid}`]: 0 });
  return { ok: true };
}
