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
 *   status: open(모집 중) · proceeding(진행 — 새 신청 받지 않음) · cancelled. waitCount = 대기 인원(A30)
 * proposals/{id}/joins/{uid}  { uid, name, proposalId, status: joined | waiting | left | cancelled, waitedAt, createdAt, updatedAt }
 *
 * 자리 예약(A30): 정원이 찬 제안엔 대기 예약(joinProposal wait: true). 누가 취소하면 맨 앞 대기자가,
 * 제안자가 정원을 늘리면(raiseProposalMax) 늘어난 만큼 먼저 온 순서로 자동 참여하고 알림을 받는다.
 *
 * 다른 걸 부탁(A29): 제안 목록에 없는 물건을 그 제안자에게 따로 부탁한다(askProposer, 한 사람당 한 건 — 다시 보내면 고침).
 * 제안자가 수락하면(answerProposerAsk) 두 사람의 거래(mode 'proposal', 채팅 · 사진 · 단계)가 생기고, 거절하면 끝.
 * proposals/{id}/asks/{uid}  { uid, name, proposalId, item, est, note, status: pending | accepted | rejected, tradeId, createdAt, updatedAt }
 */
import { FieldValue, Firestore, Timestamp, Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { deliver, PushSender } from '../notify/deliver';
import { blockedMessage, findBlocked, loadPolicy } from '../safety/policy';
import { activeUser, assertNotBlocked, nicknameOf } from '../shared/guards';
import { docId, fields } from '../shared/input';
import { KST_MS, kstDay } from '../shared/kst';

export const MAX_PEOPLE = 15;
export const MAX_FEE = 100_000;
export const MAX_DAYS_AHEAD = 60;
export type Delivery = 'each' | 'meet';

/** 한국 날짜 'YYYY-MM-DD'의 끝(23:59:59.999 KST) */
export function dayEnd(day: string): Timestamp {
  const [y, m, d] = day.split('-').map(Number);
  return Timestamp.fromMillis(Date.UTC(y, m - 1, d + 1) - KST_MS - 1);
}

/** 지금의 한국 날짜 */
export function kstToday(now = Date.now()): string {
  return kstDay(now);
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
const askRef = (db: Firestore, id: string, uid: string) => proposalRef(db, id).collection('asks').doc(uid);

/** 정지 확인 + 닉네임 */
async function nickname(tx: Transaction, db: Firestore, uid: string): Promise<string> {
  return nicknameOf(await activeUser(tx, db, uid));
}

/** 제안 올리기. 성공하면 새 제안 id(숫자 문자열) */
export async function createProposal(db: Firestore, uid: string, data: unknown, now = Date.now()) {
  const input = fields(data);
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

/** 대기 예약 줄 (A30). 이보다 길면 받지 않는다 */
export const MAX_WAIT = 15;

type Waiter = { uid: string; at: number };

/** 대기 중인 사람을 먼저 온 순서로 (트랜잭션 안에서, 쓰기 전에 읽는다) */
async function waiters(tx: Transaction, db: Firestore, id: string): Promise<Waiter[]> {
  const snap = await tx.get(proposalRef(db, id).collection('joins').where('status', '==', 'waiting'));
  const at = (v: unknown) => (v instanceof Timestamp ? v.toMillis() : 0);
  return snap.docs.map((d) => ({ uid: d.id, at: at(d.get('waitedAt')) })).sort((a, b) => a.at - b.at || (a.uid < b.uid ? -1 : 1));
}

/** 대기자를 [seats]명까지 참여로 올린다. 올린 사람 uid */
function promote(tx: Transaction, db: Firestore, id: string, line: Waiter[], seats: number, at: Timestamp): string[] {
  const up = line.slice(0, Math.max(0, seats)).map((w) => w.uid);
  for (const uid of up) tx.update(joinRef(db, id, uid), { status: 'joined', waitedAt: null, updatedAt: at });
  return up;
}

async function notifyPromoted(db: Firestore, push: PushSender | undefined, id: string, item: unknown, uids: string[], now: number) {
  if (!push) return;
  await Promise.all(
    uids.map((uid) =>
      deliver(
        db,
        push,
        { to: uid, kind: 'proposal.promoted', title: '대기하던 제안에 자리가 났어요', body: `${quote(item)} 제안에 구매 요청이 들어갔어요`, requestId: '', proposalId: id },
        `ppromote_${id}_${uid}_${now}`,
      ),
    ),
  );
}

/**
 * '저 구매할래요!' — 자리 하나를 잡는다. 정원 · 날짜 · 차단 · 정지를 확인한다.
 * 정원이 찼을 때 wait: true면 대기 예약(A30) — 자리가 나거나 제안자가 정원을 늘리면 먼저 온 순서로 자동 참여.
 */
export async function joinProposal(db: Firestore, uid: string, data: unknown, push?: PushSender, now = Date.now()) {
  const input = fields(data);
  const id = pid(input.proposalId);
  const wait = input.wait === true;
  const ref = proposalRef(db, id);
  const res = await db.runTransaction(async (tx) => {
    const p = await tx.get(ref);
    if (!p.exists) throw new HttpsError('not-found', '제안을 찾을 수 없어요.');
    const owner = p.get('ownerUid') as string;
    if (owner === uid) throw new HttpsError('failed-precondition', '내가 올린 제안이에요.');
    if (p.get('status') !== 'open') throw new HttpsError('failed-precondition', '모집이 끝난 제안이에요.');
    const end = p.get('dayEnd');
    if (end instanceof Timestamp && end.toMillis() < now) throw new HttpsError('failed-precondition', '날짜가 지난 제안이에요.');
    await assertNotBlocked(tx, db, owner, uid);
    const jr = joinRef(db, id, uid);
    const j = await tx.get(jr);
    const was = j.exists ? j.get('status') : null;
    if (was === 'joined') return null; // 이미 신청함
    const max = p.get('max') as number;
    const count = (p.get('joinedCount') as number) || 0;
    const waiting = (p.get('waitCount') as number) || 0;
    const full = max > 0 && count >= max;
    if (full && was === 'waiting') return null; // 이미 대기 중
    if (full && !wait) throw new HttpsError('failed-precondition', '정원이 찼어요.');
    if (full && waiting >= MAX_WAIT) throw new HttpsError('failed-precondition', '대기 인원도 다 찼어요.');
    const name = await nickname(tx, db, uid);
    const at = Timestamp.fromMillis(now);
    const createdAt = j.exists ? j.get('createdAt') : at;
    if (full) {
      tx.set(jr, { uid, name, proposalId: id, status: 'waiting', waitedAt: at, createdAt, updatedAt: at });
      tx.update(ref, { waitCount: FieldValue.increment(1), updatedAt: at });
      return { owner, name, item: p.get('item'), count, max, waiting: waiting + 1 };
    }
    tx.set(jr, { uid, name, proposalId: id, status: 'joined', waitedAt: null, createdAt, updatedAt: at });
    tx.update(ref, {
      joinedCount: FieldValue.increment(1),
      ...(was === 'waiting' ? { waitCount: FieldValue.increment(-1) } : {}),
      updatedAt: at,
    });
    return { owner, name, item: p.get('item'), count: count + 1, max, waiting: 0 };
  });
  if (res && push) {
    const ev = res.waiting
      ? { kind: 'proposal.wait' as const, title: '대기 예약이 생겼어요', body: `${res.name}님이 ${quote(res.item)} 자리를 기다려요 · 대기 ${res.waiting}명` }
      : {
          kind: 'proposal.join' as const,
          title: '구매 요청이 왔어요',
          body: `${res.name}님이 ${quote(res.item)}을 원해요${res.max > 0 ? ` · ${res.count}/${res.max}명` : ` · ${res.count}명`}`,
        };
    await deliver(db, push, { to: res.owner, ...ev, requestId: '', proposalId: id }, `pjoin_${id}_${uid}_${now}`);
  }
  return { proposalId: id, joined: !res?.waiting, waiting: !!res?.waiting };
}

/** 구매 요청 · 대기 취소. 구매 요청은 모집 중일 때만, 빈자리는 맨 앞 대기자가 이어받는다 */
export async function leaveProposal(db: Firestore, uid: string, data: unknown, push?: PushSender, now = Date.now()) {
  const id = pid(fields(data).proposalId);
  const ref = proposalRef(db, id);
  const res = await db.runTransaction(async (tx) => {
    const [p, j] = await Promise.all([tx.get(ref), tx.get(joinRef(db, id, uid))]);
    if (!p.exists) throw new HttpsError('not-found', '제안을 찾을 수 없어요.');
    const was = j.exists ? j.get('status') : null;
    const at = Timestamp.fromMillis(now);
    if (was === 'waiting') {
      tx.update(j.ref, { status: 'left', waitedAt: null, updatedAt: at });
      tx.update(ref, { waitCount: FieldValue.increment(-1), updatedAt: at });
      return { waiting: true, owner: '', name: '', item: p.get('item'), promoted: [] as string[] };
    }
    if (was !== 'joined') return null;
    if (p.get('status') !== 'open') throw new HttpsError('failed-precondition', '진행이 정해진 제안은 채팅으로 제안자와 이야기해 주세요.');
    const line = await waiters(tx, db, id);
    tx.update(j.ref, { status: 'left', updatedAt: at });
    const promoted = promote(tx, db, id, line, 1, at);
    tx.update(ref, {
      joinedCount: FieldValue.increment(promoted.length - 1),
      ...(promoted.length ? { waitCount: FieldValue.increment(-promoted.length) } : {}),
      updatedAt: at,
    });
    return { waiting: false, owner: p.get('ownerUid') as string, name: j.get('name') as string, item: p.get('item'), promoted };
  });
  if (res && !res.waiting && push) {
    const next = res.promoted.length ? ' · 대기하던 이웃이 자리를 이어받았어요' : '';
    await deliver(
      db,
      push,
      { to: res.owner, kind: 'proposal.leave', title: '구매 요청이 취소됐어요', body: `${res.name}님이 ${quote(res.item)} 요청을 취소했어요${next}`, requestId: '', proposalId: id },
      `pleave_${id}_${uid}_${now}`,
    );
  }
  if (res) await notifyPromoted(db, push, id, res.item, res.promoted, now);
  return { proposalId: id, joined: false, waiting: false };
}

/** 제안자가 정원을 늘린다(A30). 0이면 제한 없음. 대기자는 먼저 온 순서로 늘어난 자리만큼 참여한다 */
export async function raiseProposalMax(db: Firestore, uid: string, data: unknown, push?: PushSender, now = Date.now()) {
  const input = fields(data);
  const id = pid(input.proposalId);
  const next = int(input.max, '모집 인원', 0, MAX_PEOPLE);
  const ref = proposalRef(db, id);
  const res = await db.runTransaction(async (tx) => {
    const p = await tx.get(ref);
    if (!p.exists) throw new HttpsError('not-found', '제안을 찾을 수 없어요.');
    if (p.get('ownerUid') !== uid) throw new HttpsError('permission-denied', '제안한 사람만 할 수 있어요.');
    if (p.get('status') !== 'open') throw new HttpsError('failed-precondition', '모집 중인 제안만 정원을 늘릴 수 있어요.');
    const max = p.get('max') as number;
    if (max === 0 || (next !== 0 && next <= max)) throw new HttpsError('invalid-argument', '지금보다 많은 인원으로 골라 주세요.');
    const count = (p.get('joinedCount') as number) || 0;
    const line = await waiters(tx, db, id);
    const at = Timestamp.fromMillis(now);
    const promoted = promote(tx, db, id, line, next === 0 ? line.length : next - count, at);
    tx.update(ref, {
      max: next,
      joinedCount: FieldValue.increment(promoted.length),
      waitCount: FieldValue.increment(-promoted.length),
      updatedAt: at,
    });
    return { item: p.get('item'), promoted };
  });
  await notifyPromoted(db, push, id, res.item, res.promoted, now);
  return { proposalId: id, max: next, promoted: res.promoted.length };
}

/**
 * 제안자의 결정. proceed: 지금 인원으로 진행(새 신청을 받지 않음), cancel: 제안 취소(신청은 모두 취소).
 * 둘 다 신청한 사람 모두에게 알린다. 대기하던 사람은 어느 쪽이든 대기가 끝난다.
 */
export async function decideProposal(db: Firestore, uid: string, data: unknown, push?: PushSender, now = Date.now()) {
  const input = fields(data);
  const id = pid(input.proposalId);
  const action = input.action;
  if (action !== 'proceed' && action !== 'cancel') throw new HttpsError('invalid-argument', 'action 값이 올바르지 않아요.');
  const ref = proposalRef(db, id);
  const all = await ref.collection('joins').where('status', 'in', ['joined', 'waiting']).get();
  const joins = all.docs.filter((d) => d.get('status') === 'joined');
  const waits = all.docs.filter((d) => d.get('status') === 'waiting');
  const res = await db.runTransaction(async (tx) => {
    const p = await tx.get(ref);
    if (!p.exists) throw new HttpsError('not-found', '제안을 찾을 수 없어요.');
    if (p.get('ownerUid') !== uid) throw new HttpsError('permission-denied', '제안한 사람만 할 수 있어요.');
    const status = p.get('status');
    if (status === 'cancelled') throw new HttpsError('failed-precondition', '이미 취소한 제안이에요.');
    if (action === 'proceed' && status !== 'open') return null;
    const at = Timestamp.fromMillis(now);
    for (const w of waits) tx.update(w.ref, { status: 'cancelled', waitedAt: null, updatedAt: at });
    if (action === 'cancel') {
      for (const j of joins) tx.update(j.ref, { status: 'cancelled', updatedAt: at });
      tx.update(ref, { status: 'cancelled', joinedCount: 0, waitCount: 0, updatedAt: at });
    } else {
      tx.update(ref, { status: 'proceeding', waitCount: 0, updatedAt: at });
    }
    return { item: p.get('item'), delivery: p.get('delivery'), meetPlace: p.get('meetPlace'), meetTime: p.get('meetTime') };
  });
  if (res && push) {
    const where = res.delivery === 'meet' ? ` 받는 곳: ${[res.meetPlace, res.meetTime].filter(Boolean).join(' · ')}` : ' 전달은 채팅으로 정해요.';
    const ev =
      action === 'cancel'
        ? { title: '제안이 취소됐어요', body: `${quote(res.item)} 제안을 제안자가 취소했어요.`, kind: 'proposal.cancelled' as const }
        : { title: '제안이 진행돼요', body: `${quote(res.item)} 제안자가 사 오기로 했어요.${where}`, kind: 'proposal.proceed' as const };
    const closed =
      action === 'cancel'
        ? ev
        : { title: '대기하던 제안이 마감됐어요', body: `${quote(res.item)} 제안이 지금 인원으로 진행돼요. 자리가 나지 않았어요.`, kind: 'proposal.waitClosed' as const };
    await Promise.all([
      ...joins.map((j) => deliver(db, push, { to: j.id, ...ev, requestId: '', proposalId: id }, `p${action}_${id}_${j.id}`)),
      ...waits.map((w) => deliver(db, push, { to: w.id, ...closed, requestId: '', proposalId: id }, `p${action}_${id}_${w.id}`)),
    ]);
  }
  return { proposalId: id, status: action === 'cancel' ? 'cancelled' : 'proceeding' };
}

/** 거래 문서의 requestId 자리 — 제안에서 생긴 거래는 부탁 글이 없어서 'proposal:{id}'로 둔다 */
export const proposalTradeKey = (id: string) => `proposal:${id}`;

/**
 * 다른 걸 부탁(A29) — 제안자에게 제안 목록에 없는 물건을 따로 부탁한다. 취소되지 않은 제안이면 모집이 끝나도 된다.
 * 한 사람당 한 건: 기다리는 중이면 내용을 고치고, 거절된 뒤엔 다시 보낼 수 있다. 수락된 뒤엔 채팅으로.
 */
export async function askProposer(db: Firestore, uid: string, data: unknown, push?: PushSender, now = Date.now()) {
  const input = fields(data);
  const id = pid(input.proposalId);
  const item = str(input.item, '부탁할 물건', 1, 40);
  const note = str(input.note ?? '', '메모', 0, 200);
  const est = input.est === undefined || input.est === null ? null : int(input.est, '예상 물건값', 0, 10_000_000);
  const policy = await loadPolicy(db);
  const hit = findBlocked(`${item} ${note}`, policy);
  if (hit) throw new HttpsError('invalid-argument', blockedMessage(hit));
  const ref = proposalRef(db, id);
  const res = await db.runTransaction(async (tx) => {
    const p = await tx.get(ref);
    if (!p.exists) throw new HttpsError('not-found', '제안을 찾을 수 없어요.');
    const owner = p.get('ownerUid') as string;
    if (owner === uid) throw new HttpsError('failed-precondition', '내가 올린 제안이에요.');
    if (p.get('status') === 'cancelled') throw new HttpsError('failed-precondition', '취소된 제안이에요.');
    const end = p.get('dayEnd');
    if (end instanceof Timestamp && end.toMillis() < now) throw new HttpsError('failed-precondition', '날짜가 지난 제안이에요.');
    const cap = p.get('abroad') === true ? policy.maxItemPriceSea : policy.maxItemPrice;
    if (est !== null && est > cap) throw new HttpsError('invalid-argument', `물건값은 ${cap.toLocaleString('ko-KR')}원까지예요.`);
    await assertNotBlocked(tx, db, owner, uid);
    const ar = askRef(db, id, uid);
    const a = await tx.get(ar);
    if (a.exists && a.get('status') === 'accepted') throw new HttpsError('failed-precondition', '이미 수락된 부탁이 있어요. 채팅으로 이야기해 주세요.');
    const name = await nickname(tx, db, uid);
    const at = Timestamp.fromMillis(now);
    tx.set(ar, { uid, name, proposalId: id, item, est, note, status: 'pending', tradeId: null, createdAt: a.exists ? a.get('createdAt') : at, updatedAt: at });
    return { owner, name, fresh: !a.exists || a.get('status') !== 'pending', from: p.get('from') as string };
  });
  if (push && res.fresh) {
    await deliver(
      db,
      push,
      { to: res.owner, kind: 'proposal.ask', title: '따로 부탁이 왔어요', body: `${res.name}님이 ${quote(item)}도 사다 줄 수 있는지 물어요`, requestId: '', proposalId: id },
      `pask_${id}_${uid}_${now}`,
    );
  }
  return { proposalId: id, status: 'pending' };
}

/** 제안자가 따로 온 부탁을 수락(→ 두 사람의 거래 · 채팅)하거나 거절한다 */
export async function answerProposerAsk(db: Firestore, uid: string, data: unknown, push?: PushSender, now = Date.now()) {
  const input = fields(data);
  const id = pid(input.proposalId);
  const asker = docId(input.askerUid, 'askerUid');
  if (typeof input.accept !== 'boolean') throw new HttpsError('invalid-argument', 'accept 값이 올바르지 않아요.');
  const accept = input.accept;
  const ref = proposalRef(db, id);
  const res = await db.runTransaction(async (tx) => {
    const [p, a] = await Promise.all([tx.get(ref), tx.get(askRef(db, id, asker))]);
    if (!p.exists) throw new HttpsError('not-found', '제안을 찾을 수 없어요.');
    if (p.get('ownerUid') !== uid) throw new HttpsError('permission-denied', '제안한 사람만 할 수 있어요.');
    if (!a.exists || a.get('status') !== 'pending') throw new HttpsError('failed-precondition', '이미 답한 부탁이에요.');
    const at = Timestamp.fromMillis(now);
    const item = a.get('item') as string;
    if (!accept) {
      tx.update(a.ref, { status: 'rejected', updatedAt: at });
      return { item, tradeId: null as string | null };
    }
    await nickname(tx, db, uid); // 정지된 제안자는 수락하지 못한다
    const tradeRef = db.collection('trades').doc();
    const note = a.get('note') as string;
    tx.set(tradeRef, {
      requestId: proposalTradeKey(id),
      proposalId: id,
      mode: 'proposal',
      // 부탁한 사람이 요청자, 제안자가 사다 주는 사람(수행자)
      requesterUid: asker,
      helperUid: uid,
      applicantUid: asker,
      applicantName: a.get('name') ?? '이웃',
      title: item,
      ...(note ? { ask: note } : {}),
      est: a.get('est') ?? null,
      price: 0,
      status: 'matched',
      history: [{ status: 'matched', by: uid, at }],
      createdAt: at,
      updatedAt: at,
    });
    tx.update(a.ref, { status: 'accepted', tradeId: tradeRef.id, updatedAt: at });
    return { item, tradeId: tradeRef.id as string | null };
  });
  if (push) {
    await deliver(
      db,
      push,
      res.tradeId
        ? { to: asker, kind: 'proposal.askAccepted', title: '따로 부탁이 수락됐어요', body: `${quote(res.item)} 부탁을 제안자가 맡았어요. 채팅으로 정해 보세요`, requestId: '', proposalId: id, tradeId: res.tradeId }
        : { to: asker, kind: 'proposal.askRejected', title: '따로 부탁이 어렵대요', body: `제안자가 이번엔 ${quote(res.item)}을 사 오기 어렵다고 했어요`, requestId: '', proposalId: id },
      `panswer_${id}_${asker}_${now}`,
    );
  }
  return { proposalId: id, status: res.tradeId ? 'accepted' : 'rejected', tradeId: res.tradeId };
}
