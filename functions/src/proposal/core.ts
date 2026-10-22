/**
 * 제안하기(개발 To-do A15) — "가는 김에 사다 드려요".
 *
 * 부탁과 반대 방향이다. 이동하는 이웃이 물건 · 1명당 금액 · 인원 · 날짜를 정해 올리고(createProposal),
 * 원하는 이웃이 '저 구매할래요!'로 자리를 잡는다(joinProposal · 취소 leaveProposal).
 * 전달 방식은 제안자가 올릴 때 고른다 — 구매자마다 따로 전달(each) / 정한 장소 · 시간에 한꺼번에 받기(meet).
 * 인원이 다 안 차도 자동으로 취소하지 않는다. 제안자가 '그래도 진행'(proceed)이나 '취소'(cancel)를 누르고 신청자에게 알린다.
 *
 * 앱 안의 결제는 없다. 금액은 만나서 주고받을 금액으로만 보여 준다.
 * 앱은 proposals · joins를 직접 못 쓴다(보안 규칙). 신청 목록은 제안자와 본인만 읽는다.
 *
 * proposals/{id}  { ownerUid, who, abroad, from, to, cc, item, spec, price, fee, day('YYYY-MM-DD', 한국 날짜), dayEnd,
 *                   max(0 = 제한 없음), joinedCount, delivery, meetPlace, meetTime, note, area, status, createdAt, updatedAt }
 *   status: open(모집 중) · proceeding(진행 — 새 신청 받지 않음) · cancelled
 * proposals/{id}/joins/{uid}  { uid, name, proposalId, status: joined | left | cancelled, createdAt, updatedAt }
 */
import { FieldValue, Firestore, Timestamp, Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { deliver, PushSender } from '../notify/deliver';
import { blockedMessage, findBlocked, loadPolicy } from '../safety/policy';

export const MAX_PEOPLE = 15;
export const MAX_FEE = 100_000;
export const MAX_DAYS_AHEAD = 60;
export type Delivery = 'each' | 'meet';

const KST_MS = 9 * 3600_000;

/** 한국 날짜 'YYYY-MM-DD'의 끝(23:59:59.999 KST) */
export function dayEnd(day: string): Timestamp {
  const [y, m, d] = day.split('-').map(Number);
  return Timestamp.fromMillis(Date.UTC(y, m - 1, d + 1) - KST_MS - 1);
}

/** 지금의 한국 날짜 */
export function kstToday(now = Date.now()): string {
  return new Date(now + KST_MS).toISOString().slice(0, 10);
}

function str(v: unknown, field: string, min: number, max: number): string {
  const s = typeof v === 'string' ? v.trim() : '';
  if (s.length < min || s.length > max) throw new HttpsError('invalid-argument', `${field}을(를) ${min ? `${min}~` : ''}${max}자로 적어 주세요.`);
  return s;
}

function int(v: unknown, field: string, min: number, max: number): number {
  if (typeof v !== 'number' || !Number.isInteger(v) || v < min || v > max) throw new HttpsError('invalid-argument', `${field} 값이 올바르지 않아요.`);
  return v;
}

function pid(v: unknown): string {
  if (typeof v !== 'string' || !/^\d{1,18}$/.test(v)) throw new HttpsError('invalid-argument', 'proposalId 값이 올바르지 않아요.');
  return v;
}

const proposalRef = (db: Firestore, id: string) => db.collection('proposals').doc(id);
const joinRef = (db: Firestore, id: string, uid: string) => proposalRef(db, id).collection('joins').doc(uid);

async function nickname(tx: Transaction, db: Firestore, uid: string): Promise<string> {
  const me = await tx.get(db.collection('users').doc(uid));
  if (me.get('suspended') === true) throw new HttpsError('permission-denied', '내 계정은 지금 이용이 제한돼 있어요.');
  const n = me.get('nickname');
  return typeof n === 'string' && n.trim() ? n.trim().slice(0, 20) : '이웃';
}

/** 제안 올리기. 성공하면 새 제안 id(숫자 문자열) */
export async function createProposal(db: Firestore, uid: string, data: unknown, now = Date.now()) {
  const input = (data ?? {}) as Record<string, unknown>;
  const abroad = input.abroad === true;
  const from = str(input.from, abroad ? '도시' : '출발 지역', 1, 30);
  const to = abroad ? '' : str(input.to, '도착 지역', 1, 30);
  if (!abroad && from === to) throw new HttpsError('invalid-argument', '국내 제안은 다른 지역으로 이동할 때만 올릴 수 있어요.');
  const cc = abroad ? str(input.cc, '나라', 2, 2).toLowerCase() : null;
  const item = str(input.item, '물건', 1, 40);
  const spec = str(input.spec ?? '', '규격', 0, 60);
  const note = str(input.note ?? '', '한마디', 0, 200);
  const area = str(input.area ?? '', '동네', 0, 40);

  const policy = await loadPolicy(db);
  const word = findBlocked([item, spec, note].join(' '), policy);
  if (word) throw new HttpsError('invalid-argument', blockedMessage(word));
  const cap = abroad ? policy.maxItemPriceSea : policy.maxItemPrice;
  const price = int(input.price, '물건값', 0, 10_000_000);
  if (price > cap) throw new HttpsError('invalid-argument', `물건값은 1명당 ${cap.toLocaleString('ko-KR')}원까지예요.`);
  const fee = int(input.fee ?? 0, '심부름료', 0, MAX_FEE);
  const max = int(input.max ?? 0, '모집 인원', 0, MAX_PEOPLE);

  const day = typeof input.day === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(input.day) ? input.day : '';
  if (!day) throw new HttpsError('invalid-argument', '이동하는 날을 골라 주세요.');
  const today = kstToday(now);
  const last = kstToday(now + MAX_DAYS_AHEAD * 86_400_000);
  if (day < today || day > last) throw new HttpsError('invalid-argument', `이동하는 날은 오늘부터 ${MAX_DAYS_AHEAD}일 안이에요.`);

  const delivery: Delivery = input.delivery === 'meet' ? 'meet' : 'each';
  const meetPlace = delivery === 'meet' ? str(input.meetPlace, '받는 장소', 1, 60) : null;
  const meetTime = delivery === 'meet' ? str(input.meetTime ?? '', '받는 시간', 0, 30) : null;

  const id = String(now * 1000 + Math.floor(Math.random() * 1000));
  const at = Timestamp.fromMillis(now);
  await db.runTransaction(async (tx) => {
    const who = await nickname(tx, db, uid);
    tx.create(proposalRef(db, id), {
      ownerUid: uid,
      who,
      abroad,
      from,
      to,
      cc,
      item,
      spec,
      price,
      fee,
      day,
      dayEnd: dayEnd(day),
      max,
      joinedCount: 0,
      delivery,
      meetPlace,
      meetTime,
      note,
      area,
      status: 'open',
      createdAt: at,
      updatedAt: at,
    });
  });
  return { proposalId: id };
}

const quote = (item: unknown) => {
  const s = typeof item === 'string' && item ? item : '제안';
  return `"${s.length > 20 ? s.slice(0, 20) + '…' : s}"`;
};

/** '저 구매할래요!' — 자리 하나를 잡는다. 정원 · 날짜 · 차단 · 정지를 확인한다 */
export async function joinProposal(db: Firestore, uid: string, data: unknown, push?: PushSender, now = Date.now()) {
  const id = pid((data as Record<string, unknown> | null)?.proposalId);
  const ref = proposalRef(db, id);
  const res = await db.runTransaction(async (tx) => {
    const p = await tx.get(ref);
    if (!p.exists) throw new HttpsError('not-found', '제안을 찾을 수 없어요.');
    const owner = p.get('ownerUid') as string;
    if (owner === uid) throw new HttpsError('failed-precondition', '내가 올린 제안이에요.');
    if (p.get('status') !== 'open') throw new HttpsError('failed-precondition', '모집이 끝난 제안이에요.');
    const end = p.get('dayEnd');
    if (end instanceof Timestamp && end.toMillis() < now) throw new HttpsError('failed-precondition', '날짜가 지난 제안이에요.');
    const [ab, ba] = await Promise.all([
      tx.get(db.collection('users').doc(owner).collection('blocks').doc(uid)),
      tx.get(db.collection('users').doc(uid).collection('blocks').doc(owner)),
    ]);
    if (ab.exists || ba.exists) throw new HttpsError('permission-denied', '차단 관계인 사용자와는 거래할 수 없어요.');
    const jr = joinRef(db, id, uid);
    const j = await tx.get(jr);
    if (j.exists && j.get('status') === 'joined') return null; // 이미 신청함
    const max = p.get('max') as number;
    const count = (p.get('joinedCount') as number) || 0;
    if (max > 0 && count >= max) throw new HttpsError('failed-precondition', '정원이 찼어요.');
    const name = await nickname(tx, db, uid);
    const at = Timestamp.fromMillis(now);
    tx.set(jr, { uid, name, proposalId: id, status: 'joined', createdAt: j.exists ? j.get('createdAt') : at, updatedAt: at });
    tx.update(ref, { joinedCount: FieldValue.increment(1), updatedAt: at });
    return { owner, name, item: p.get('item'), count: count + 1, max };
  });
  if (res && push) {
    const left = res.max > 0 ? ` · ${res.count}/${res.max}명` : ` · ${res.count}명`;
    await deliver(
      db,
      push,
      { to: res.owner, kind: 'proposal.join', title: '구매 요청이 왔어요', body: `${res.name}님이 ${quote(res.item)}을 원해요${left}`, requestId: '', proposalId: id },
      `pjoin_${id}_${uid}_${now}`,
    );
  }
  return { proposalId: id, joined: true };
}

/** 구매 요청 취소. 모집 중일 때만 */
export async function leaveProposal(db: Firestore, uid: string, data: unknown, push?: PushSender, now = Date.now()) {
  const id = pid((data as Record<string, unknown> | null)?.proposalId);
  const ref = proposalRef(db, id);
  const res = await db.runTransaction(async (tx) => {
    const [p, j] = await Promise.all([tx.get(ref), tx.get(joinRef(db, id, uid))]);
    if (!p.exists) throw new HttpsError('not-found', '제안을 찾을 수 없어요.');
    if (!j.exists || j.get('status') !== 'joined') return null;
    if (p.get('status') !== 'open') throw new HttpsError('failed-precondition', '진행이 정해진 제안은 채팅으로 제안자와 이야기해 주세요.');
    const at = Timestamp.fromMillis(now);
    tx.update(j.ref, { status: 'left', updatedAt: at });
    tx.update(ref, { joinedCount: FieldValue.increment(-1), updatedAt: at });
    return { owner: p.get('ownerUid') as string, name: j.get('name') as string, item: p.get('item') };
  });
  if (res && push) {
    await deliver(
      db,
      push,
      { to: res.owner, kind: 'proposal.leave', title: '구매 요청이 취소됐어요', body: `${res.name}님이 ${quote(res.item)} 요청을 취소했어요`, requestId: '', proposalId: id },
      `pleave_${id}_${uid}_${now}`,
    );
  }
  return { proposalId: id, joined: false };
}

/**
 * 제안자의 결정. proceed: 지금 인원으로 진행(새 신청을 받지 않음), cancel: 제안 취소(신청은 모두 취소).
 * 둘 다 신청한 사람 모두에게 알린다.
 */
export async function decideProposal(db: Firestore, uid: string, data: unknown, push?: PushSender, now = Date.now()) {
  const input = (data ?? {}) as Record<string, unknown>;
  const id = pid(input.proposalId);
  const action = input.action;
  if (action !== 'proceed' && action !== 'cancel') throw new HttpsError('invalid-argument', 'action 값이 올바르지 않아요.');
  const ref = proposalRef(db, id);
  const joins = await ref.collection('joins').where('status', '==', 'joined').get();
  const res = await db.runTransaction(async (tx) => {
    const p = await tx.get(ref);
    if (!p.exists) throw new HttpsError('not-found', '제안을 찾을 수 없어요.');
    if (p.get('ownerUid') !== uid) throw new HttpsError('permission-denied', '제안한 사람만 할 수 있어요.');
    const status = p.get('status');
    if (status === 'cancelled') throw new HttpsError('failed-precondition', '이미 취소한 제안이에요.');
    if (action === 'proceed' && status !== 'open') return null;
    const at = Timestamp.fromMillis(now);
    if (action === 'cancel') {
      for (const j of joins.docs) tx.update(j.ref, { status: 'cancelled', updatedAt: at });
      tx.update(ref, { status: 'cancelled', joinedCount: 0, updatedAt: at });
    } else {
      tx.update(ref, { status: 'proceeding', updatedAt: at });
    }
    return { item: p.get('item'), delivery: p.get('delivery'), meetPlace: p.get('meetPlace'), meetTime: p.get('meetTime') };
  });
  if (res && push) {
    const where = res.delivery === 'meet' ? ` 받는 곳: ${[res.meetPlace, res.meetTime].filter(Boolean).join(' · ')}` : ' 전달은 채팅으로 정해요.';
    const ev =
      action === 'cancel'
        ? { title: '제안이 취소됐어요', body: `${quote(res.item)} 제안을 제안자가 취소했어요.`, kind: 'proposal.cancelled' as const }
        : { title: '제안이 진행돼요', body: `${quote(res.item)} 제안자가 사 오기로 했어요.${where}`, kind: 'proposal.proceed' as const };
    await Promise.all(
      joins.docs.map((j) =>
        deliver(db, push, { to: j.id, ...ev, requestId: '', proposalId: id }, `p${action}_${id}_${j.id}`),
      ),
    );
  }
  return { proposalId: id, status: action === 'cancel' ? 'cancelled' : 'proceeding' };
}
