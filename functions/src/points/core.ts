/**
 * 포인트 서버 이전(개발 To-do B09, 설계: docs/백엔드_연결.md §10).
 *
 * 원장이 원본이고 잔액은 원장에서 나온 값이다. 쓰기는 서버만 한다(보안 규칙: 앱은 읽기만).
 *
 * users/{uid}
 *   points           잔액 사본(화면 표시용)
 *   pointsOpenedAt   서버 원장을 시작한 시각. 그 전 잔액은 원장 첫 줄 '이전 잔액'(id opening)으로 옮긴다
 *   attend           { last: 'YYYY-MM-DD', streak, month: 'YYYY-MM', monthCount } — 출석 보상 계산용(한국 날짜)
 * users/{uid}/pointLedger/{id}   append-only
 *   type  earn | spend | expire     amount  +적립 / −차감     label · ref · at
 *   earn  은 key(= 문서 id, 같은 보상 두 번 막기) · kind · day · left(아직 쓰지 않고 남은 양 — 먼저 쌓인 것부터 쓴다)
 *
 * 금액은 앱이 보낸 값을 믿지 않고 서버 표(catalog.json)로 정한다. 지금 서버가 주는 적립은 출석뿐이다 —
 * 광고는 광고 회사의 시청 확인 콜백, 제휴 미션 · 오퍼월은 제휴사 결과가 서버에 붙은 뒤 [grant]로 연다.
 * 교환(redeem)과 소멸(expire)은 config/points로 켠다(기본 꺼짐 — 상품권 제휴 · 약관의 유효기간이 정해진 뒤).
 */
import { DocumentReference, Firestore, Timestamp, Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { assertNotSuspended } from '../shared/guards';
import { fields } from '../shared/input';
import { kstDay } from '../shared/kst';
import catalog from './catalog.json';
import { C } from '../shared/paths';

const DAY_MS = 86_400_000;

export const ATTEND = catalog.attend;
export const PRODUCTS = catalog.products;

/** 한국 날짜 'YYYY-MM-DD' (다른 모듈 · 테스트가 여기서도 가져다 쓴다) */
export { kstDay };
const prevDay = (day: string) => new Date(Date.parse(`${day}T00:00:00Z`) - DAY_MS).toISOString().slice(0, 10);

export interface AttendState {
  last: string;
  streak: number;
  month: string;
  monthCount: number;
}

/** 오늘 출석하면 받는 포인트와 바뀐 출석 상태. 앱 Attendance.todayReward와 같은 규칙. 이미 했으면 null */
export function attendReward(prev: AttendState | null, today: string): { amount: number; next: AttendState } | null {
  if (prev?.last === today) return null;
  const streak = (prev?.last === prevDay(today) ? prev.streak : 0) + 1;
  const month = today.slice(0, 7);
  const before = prev?.month === month ? prev.monthCount : 0;
  let amount = ATTEND.daily;
  if (streak % ATTEND.streakEvery === 0) amount += ATTEND.streakBonus;
  if (before === ATTEND.monthTarget - 1) amount += ATTEND.monthBonus;
  return { amount, next: { last: today, streak, month, monthCount: before + 1 } };
}

export interface PointPolicy {
  /** 적립 후 N일이 지나면 남은 양이 소멸한다. 0 = 소멸 없음 */
  expireDays: number;
  /** 포인트 교환을 받을지 */
  shopOpen: boolean;
}

export async function loadPointPolicy(db: Firestore): Promise<PointPolicy> {
  const d = (await db.collection(C.config).doc('points').get()).data() ?? {};
  const days = d.expireDays;
  return {
    expireDays: typeof days === 'number' && Number.isInteger(days) && days > 0 ? days : 0,
    shopOpen: d.shopOpen === true,
  };
}

const userRef = (db: Firestore, uid: string) => db.collection(C.users).doc(uid);
const ledgerRef = (db: Firestore, uid: string) => userRef(db, uid).collection(C.pointLedger);

type Lot = { ref: DocumentReference; left: number; at: number };

/** 먼저 쌓인 적립분부터 쓸 수 있게 남은 양이 있는 적립을 읽는다(트랜잭션 안, 쓰기 전에) */
async function lots(tx: Transaction, db: Firestore, uid: string): Promise<Lot[]> {
  const snap = await tx.get(ledgerRef(db, uid).where('left', '>', 0));
  return snap.docs
    .map((d) => ({ ref: d.ref, left: d.get('left') as number, at: (d.get('at') as Timestamp | undefined)?.toMillis() ?? 0 }))
    // 이전 잔액(opening)은 서버 원장보다 먼저 쌓인 것이라 맨 앞
    .map((l) => (l.ref.id === 'opening' ? { ...l, at: 0 } : l))
    .sort((a, b) => a.at - b.at || (a.ref.id < b.ref.id ? -1 : 1));
}

/**
 * 서버 원장을 처음 쓰는 계정이면 지금 잔액을 '이전 잔액' 한 줄로 옮긴다(옮기는 순서 2).
 * 읽기를 모두 끝낸 뒤 부른다. 옮긴 줄이 있으면 쓸 수 있는 적립분으로 돌려준다
 */
function openLedger(tx: Transaction, db: Firestore, uid: string, user: FirebaseFirestore.DocumentSnapshot, at: Timestamp): Lot[] {
  if (user.get('pointsOpenedAt')) return [];
  const bal = typeof user.get('points') === 'number' ? Math.max(0, Math.floor(user.get('points') as number)) : 0;
  tx.set(userRef(db, uid), { pointsOpenedAt: at }, { merge: true });
  if (bal === 0) return [];
  const ref = ledgerRef(db, uid).doc('opening');
  tx.set(ref, { type: 'earn', kind: 'opening', key: 'opening', amount: bal, left: bal, label: '이전 잔액', at });
  return [{ ref, left: bal, at: 0 }];
}

const balanceOf = (user: FirebaseFirestore.DocumentSnapshot) =>
  typeof user.get('points') === 'number' ? Math.max(0, Math.floor(user.get('points') as number)) : 0;

/**
 * 서버가 확인한 적립 한 건. [key]가 같으면 한 번만 준다(문서 id). 출석 · 앞으로 붙을 광고 콜백 · 제휴사 결과가 이걸 쓴다.
 * 돌려주는 값: 새로 줬으면 { amount, balance }, 이미 받은 키면 { amount: 0, balance }
 */
export async function grant(
  db: Firestore,
  uid: string,
  e: { key: string; kind: string; label: string; amount: (tx: Transaction, user: FirebaseFirestore.DocumentSnapshot) => { amount: number; extra?: Record<string, unknown> } | null; day?: string; ref?: string },
  now = Date.now(),
) {
  if (!e.key || e.key.includes('/') || e.key.length > 200) throw new HttpsError('invalid-argument', '적립 키가 올바르지 않아요.');
  return db.runTransaction(async (tx) => {
    const user = await tx.get(userRef(db, uid));
    const entry = await tx.get(ledgerRef(db, uid).doc(e.key));
    assertNotSuspended(user);
    // 원장을 처음 여는 계정도 잔액은 그대로다(이전 잔액이 원장 첫 줄이 된다)
    const base = balanceOf(user);
    if (entry.exists) return { amount: 0, balance: base };
    const r = e.amount(tx, user);
    if (!r || r.amount <= 0) return { amount: 0, balance: base };
    const at = Timestamp.fromMillis(now);
    openLedger(tx, db, uid, user, at);
    tx.set(entry.ref, {
      type: 'earn',
      kind: e.kind,
      key: e.key,
      amount: r.amount,
      left: r.amount,
      label: e.label,
      ...(e.day ? { day: e.day } : {}),
      ...(e.ref ? { ref: e.ref } : {}),
      at,
    });
    const balance = base + r.amount;
    tx.set(userRef(db, uid), { points: balance, ...(r.extra ?? {}), updatedAt: at }, { merge: true });
    return { amount: r.amount, balance };
  });
}

/** 앱이 부르는 적립. 지금은 출석(kind 'attend')만 받는다 */
export async function earnPoints(db: Firestore, uid: string, data: unknown, now = Date.now()) {
  const kind = fields(data).kind;
  if (kind === 'ad') throw new HttpsError('failed-precondition', '광고 적립은 광고 회사의 시청 확인이 서버에 붙은 뒤 열려요.');
  if (kind !== 'attend') throw new HttpsError('failed-precondition', '이 적립은 아직 서버에서 받지 않아요.');
  const today = kstDay(now);
  const key = `benefit:attend:${today}`;
  const res = await grant(
    db,
    uid,
    {
      key,
      kind: 'attend',
      label: '출석 적립',
      day: today,
      amount: (_tx, user) => {
        const prev = user.get('attend') as AttendState | undefined;
        const r = attendReward(prev ?? null, today);
        return r && { amount: r.amount, extra: { attend: r.next } };
      },
    },
    now,
  );
  return { key, day: today, ...res };
}

/** 쿠폰 유효기간 표기 'YYYY.MM.DD' (한국 날짜) */
const couponExp = (now: number) => kstDay(now + catalog.couponDays * DAY_MS).replace(/-/g, '.');

/**
 * 상품 교환. 값은 서버 표, 잔액이 모자라면 거절. 차감 원장 + 쿠폰 + 잔액을 한 트랜잭션으로.
 * 쿠폰 번호는 상품권 회사가 발급해야 해서 비워 두고 '발급 준비 중'(status issuing)으로 만든다.
 */
export async function redeemPoints(db: Firestore, uid: string, data: unknown, now = Date.now()) {
  const policy = await loadPointPolicy(db);
  if (!policy.shopOpen) throw new HttpsError('failed-precondition', '포인트 교환은 상품권 제휴가 붙은 뒤 열려요.');
  const id = fields(data).productId;
  const p = PRODUCTS.find((x) => x.id === id);
  if (!p) throw new HttpsError('invalid-argument', '상품을 찾을 수 없어요.');
  const couponId = String(now * 1000 + Math.floor(Math.random() * 1000));
  return db.runTransaction(async (tx) => {
    const user = await tx.get(userRef(db, uid));
    const have = await lots(tx, db, uid);
    assertNotSuspended(user);
    const balance = balanceOf(user);
    if (balance < p.points) throw new HttpsError('failed-precondition', '보유 포인트가 부족해요.');
    const at = Timestamp.fromMillis(now);
    const pool = [...openLedger(tx, db, uid, user, at), ...have];
    let need = p.points;
    for (const lot of pool) {
      if (need === 0) break;
      const use = Math.min(lot.left, need);
      tx.set(lot.ref, { left: lot.left - use }, { merge: true });
      need -= use;
    }
    tx.set(ledgerRef(db, uid).doc(`spend_${couponId}`), { type: 'spend', amount: -p.points, label: `${p.name} 교환`, ref: couponId, at });
    tx.set(userRef(db, uid).collection(C.coupons).doc(couponId), {
      id: Number(couponId),
      productId: p.id,
      brandK: p.brand,
      name: p.name,
      points: p.points,
      exp: couponExp(now),
      code: '',
      status: 'issuing',
      used: false,
      createdAt: at,
    });
    tx.set(userRef(db, uid), { points: balance - p.points, updatedAt: at }, { merge: true });
    return { couponId, balance: balance - p.points };
  });
}

/** 쿠폰 사용 완료 표시 */
export async function useCoupon(db: Firestore, uid: string, data: unknown, now = Date.now()) {
  const id = fields(data).couponId;
  if (typeof id !== 'string' || !/^\d{1,20}$/.test(id)) throw new HttpsError('invalid-argument', 'couponId 값이 올바르지 않아요.');
  const ref = userRef(db, uid).collection(C.coupons).doc(id);
  await db.runTransaction(async (tx) => {
    const c = await tx.get(ref);
    if (!c.exists) throw new HttpsError('not-found', '쿠폰을 찾을 수 없어요.');
    if (c.get('used') === true) return;
    tx.update(ref, { used: true, usedAt: Timestamp.fromMillis(now) });
  });
  return { couponId: id, used: true };
}

/** 소멸(매일 예약 실행). config/points.expireDays가 0이면 아무것도 안 한다. 한 번에 [limit]건까지. 소멸한 적립 수 */
export async function expirePoints(db: Firestore, now = Date.now(), limit = 500): Promise<number> {
  const { expireDays } = await loadPointPolicy(db);
  if (!expireDays) return 0;
  const cutoff = Timestamp.fromMillis(now - expireDays * DAY_MS);
  const old = await db.collectionGroup(C.pointLedger).where('type', '==', 'earn').where('at', '<', cutoff).limit(limit).get();
  let n = 0;
  for (const d of old.docs) {
    if (!((d.get('left') as number) > 0)) continue;
    const user = d.ref.parent.parent;
    if (!user) continue;
    const done = await db.runTransaction(async (tx) => {
      const [e, u] = await Promise.all([tx.get(d.ref), tx.get(user)]);
      const left = e.get('left') as number;
      if (!(left > 0)) return false;
      const at = Timestamp.fromMillis(now);
      tx.set(user.collection(C.pointLedger).doc(`expire_${d.id}`), { type: 'expire', amount: -left, label: '유효기간 지나 소멸', ref: d.id, at });
      tx.set(d.ref, { left: 0 }, { merge: true });
      tx.set(user, { points: Math.max(0, balanceOf(u) - left), updatedAt: at }, { merge: true });
      return true;
    });
    if (done) n++;
  }
  return n;
}
