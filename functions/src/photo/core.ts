/**
 * 거래 사진 — 완료 인증 사진 · 영수증(개발 To-do A37).
 *
 * 앱이 Storage `trades/{tradeId}/{uid}/{파일}`에 올리고(storage.rules: 거래 당사자만, 이미지 5MB까지), 이 함수로 거래에 붙인다.
 * 거래 문서는 서버만 쓰므로(Firestore 규칙) 사진 목록 `trades/{id}/photos`도 여기서만 만든다.
 *  - kind 'proof'   완료 인증 사진(전달 · 구매 결과)
 *  - kind 'receipt' 영수증 + 금액(원). 국내 현금 직접 송금 흐름(영수증 → 송금 요청 → 보냈어요 → 입금 확인)의 바탕이다
 * 상대방에게 알림(trade.photo). 사진은 거래가 끝나기 전(취소 · 완료 전)에만 올린다.
 */
import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { deliver, PushSender } from '../notify/deliver';
import { docId, fields, ownPhotoPath } from '../shared/input';
import { C } from '../shared/paths';

export const PHOTO_LIMIT = 20;
const MAX_NOTE = 100;
const MAX_AMOUNT = 10_000_000;
const OPEN = new Set(['matched', 'working', 'confirmation']);

export async function addTradePhoto(db: Firestore, uid: string, data: unknown, push?: PushSender) {
  const input = fields(data);
  const tid = docId(input.tradeId, 'tradeId');
  const kind = input.kind;
  if (kind !== 'proof' && kind !== 'receipt') throw new HttpsError('invalid-argument', 'kind 값이 올바르지 않아요.');
  const path = ownPhotoPath(input.path, tid, uid);
  let amount: number | null = null;
  if (kind === 'receipt') {
    const a = input.amount;
    if (typeof a !== 'number' || !Number.isInteger(a) || a <= 0 || a > MAX_AMOUNT) {
      throw new HttpsError('invalid-argument', '영수증 금액을 원 단위로 적어 주세요.');
    }
    amount = a;
  }
  const note = typeof input.note === 'string' ? input.note.trim().slice(0, MAX_NOTE) : '';

  const tradeRef = db.collection(C.trades).doc(tid);
  const saved = await db.runTransaction(async (tx) => {
    const trade = await tx.get(tradeRef);
    if (!trade.exists) throw new HttpsError('not-found', '거래를 찾을 수 없어요.');
    const requesterUid = trade.get('requesterUid') as string;
    const helperUid = trade.get('helperUid') as string;
    const role = uid === requesterUid ? 'requester' : uid === helperUid ? 'helper' : null;
    if (!role) throw new HttpsError('permission-denied', '이 거래의 당사자가 아니에요.');
    if (!OPEN.has(trade.get('status') as string)) throw new HttpsError('failed-precondition', '끝난 거래에는 사진을 올릴 수 없어요.');
    const count = (trade.get('photoCount') as number | undefined) ?? 0;
    if (count >= PHOTO_LIMIT) throw new HttpsError('resource-exhausted', `사진은 거래마다 ${PHOTO_LIMIT}장까지예요.`);
    const now = Timestamp.now();
    const ref = tradeRef.collection(C.photos).doc();
    tx.create(ref, { uid, role, kind, path, amount, note, createdAt: now });
    tx.update(tradeRef, { photoCount: FieldValue.increment(1), lastPhotoAt: now });
    return {
      id: ref.id,
      to: role === 'requester' ? helperUid : requesterUid,
      requestId: trade.get('requestId') as string,
      title: (trade.get('title') as string) || '부탁',
    };
  });

  if (push && saved.to) {
    const short = saved.title.length > 20 ? saved.title.slice(0, 20) + '…' : saved.title;
    await deliver(
      db,
      push,
      {
        to: saved.to,
        kind: 'trade.photo',
        title: kind === 'receipt' ? '영수증이 올라왔어요' : '완료 사진이 올라왔어요',
        body: kind === 'receipt' ? `"${short}" 영수증 ${amount!.toLocaleString('ko-KR')}원` : `"${short}" 사진을 확인해 보세요`,
        requestId: saved.requestId,
        tradeId: tid,
      },
      `photo_${saved.id}`,
    );
  }
  return { id: saved.id };
}
