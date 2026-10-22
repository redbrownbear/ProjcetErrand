/**
 * 부탁 · 지원 · 거래의 서버 로직.
 *
 * 여기 함수들은 Cloud Functions 런타임 없이 Firestore 인스턴스만 받아 동작한다.
 * 그래서 에뮬레이터에 붙여 그대로 테스트할 수 있다(`test/emu/core.test.ts`).
 * onCall 껍데기는 `callables.ts`에 있다.
 *
 * 모든 상태 변경은 트랜잭션 안에서 "지금 상태를 다시 읽고 → 허용되는지 확인 → 쓴다".
 * 같은 요청이 두 번 와도 두 번째는 상태가 이미 바뀌어 있어 거부된다.
 *
 * 부탁 종류(mode)
 *  - ask · sea · together : 글쓴이가 **도움을 요청**한다. 지원한 사람이 수행자(helper), 한 명만 수락하면 모집이 닫힌다.
 *  - going('가는 김에 · 제가 가요') : 글쓴이가 **도움을 준다**. 신청한 사람이 요청자(requester)가 되고, 글쓴이가 수행자다.
 *    가는 길에 여러 명 부탁을 받을 수 있어 수락해도 모집이 열려 있고, 거래마다 따로 진행·완료된다.
 *  지원서 문서 id는 언제나 **신청한 사람 uid**다(필드 이름 helperUid는 예전 그대로 = 신청자). 거래에는 applicantUid로 남긴다.
 */
import { FieldValue, Firestore, Timestamp, Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { blockedMessage, findBlocked, loadPolicy } from '../safety/policy';
import { advance, isFinished, isTradeAction, TradeRole, TradeStatus } from '../domain/tradeMachine';

/** hidden: 금지 품목 · 물건값 상한에 걸려 서버가 내린 글(safety/screen.ts) */
export type RequestStatus = 'open' | 'matched' | 'done' | 'cancelled' | 'expired' | 'hidden';
export type ApplicationStatus = 'pending' | 'accepted' | 'rejected' | 'withdrawn' | 'cancelled';

export const LIMITS = {
  maxOfferPrice: 10_000_000,
  maxMsg: 300,
  maxSpot: 20,
} as const;


// ── 입력 검사 ─────────────────────────────────────────────────────────────

function id(v: unknown, field: string): string {
  if (typeof v !== 'string' || v.length === 0 || v.length > 128 || v.includes('/')) {
    throw new HttpsError('invalid-argument', `${field} 값이 올바르지 않아요.`);
  }
  return v;
}

function optPrice(v: unknown): number | undefined {
  if (v === undefined || v === null) return undefined;
  if (typeof v !== 'number' || !Number.isInteger(v) || v < 0 || v > LIMITS.maxOfferPrice) {
    throw new HttpsError('invalid-argument', '제안 금액이 올바르지 않아요.');
  }
  return v;
}

function optMsg(v: unknown): string | undefined {
  if (v === undefined || v === null || v === '') return undefined;
  if (typeof v !== 'string' || v.length > LIMITS.maxMsg) {
    throw new HttpsError('invalid-argument', `메시지는 ${LIMITS.maxMsg}자까지예요.`);
  }
  return v.trim();
}

function obj(data: unknown): Record<string, unknown> {
  if (typeof data !== 'object' || data === null) throw new HttpsError('invalid-argument', '요청 형식이 올바르지 않아요.');
  return data as Record<string, unknown>;
}

// ── 공통 조회 ─────────────────────────────────────────────────────────────

const paths = {
  user: (db: Firestore, uid: string) => db.collection('users').doc(uid),
  block: (db: Firestore, owner: string, target: string) => db.collection('users').doc(owner).collection('blocks').doc(target),
  request: (db: Firestore, rid: string) => db.collection('requests').doc(rid),
  application: (db: Firestore, rid: string, helperUid: string) =>
    db.collection('requests').doc(rid).collection('applications').doc(helperUid),
  trade: (db: Firestore, tid: string) => db.collection('trades').doc(tid),
};

async function assertActive(tx: Transaction, db: Firestore, uid: string, who = '내'): Promise<void> {
  const snap = await tx.get(paths.user(db, uid));
  if (snap.get('suspended') === true) {
    throw new HttpsError('permission-denied', `${who} 계정은 지금 이용이 제한돼 있어요.`);
  }
}

async function assertNotBlocked(tx: Transaction, db: Firestore, a: string, b: string): Promise<void> {
  const [ab, ba] = await Promise.all([tx.get(paths.block(db, a, b)), tx.get(paths.block(db, b, a))]);
  if (ab.exists || ba.exists) throw new HttpsError('permission-denied', '차단 관계인 사용자와는 거래할 수 없어요.');
}

/** 글쓴이가 도움을 주는 글인가(신청자가 요청자가 된다) */
export function isGiving(mode: unknown): boolean {
  return mode === 'going';
}

function deadlinePassed(deadline: unknown, now: Timestamp): boolean {
  return deadline instanceof Timestamp && deadline.toMillis() < now.toMillis();
}

// ── 지원 ──────────────────────────────────────────────────────────────────

export async function applyToRequest(db: Firestore, uid: string, data: unknown) {
  const input = obj(data);
  const rid = id(input.requestId, 'requestId');
  const offerPrice = optPrice(input.offerPrice);
  const msg = optMsg(input.msg);
  // 가는 김에 '어! 나도': 예상 물건값·받는 곳 (일반 지원에는 없다)
  const est = input.est === undefined || input.est === null ? undefined : optPrice(input.est);
  const spot = typeof input.spot === 'string' && input.spot.trim() ? input.spot.trim().slice(0, LIMITS.maxSpot) : undefined;
  const policy = await loadPolicy(db);

  return db.runTransaction(async (tx) => {
    const now = Timestamp.now();
    const reqRef = paths.request(db, rid);
    const appRef = paths.application(db, rid, uid);
    const [req, app] = await Promise.all([tx.get(reqRef), tx.get(appRef)]);
    if (!req.exists) throw new HttpsError('not-found', '부탁을 찾을 수 없어요.');
    const owner = req.get('ownerUid') as string;
    if (owner === uid) throw new HttpsError('failed-precondition', '내가 올린 글에는 신청할 수 없어요.');
    const giving = isGiving(req.get('mode'));
    if (giving) {
      if (!msg || msg.length < 2) throw new HttpsError('invalid-argument', '무엇을 부탁할지 적어 주세요.');
      const word = findBlocked(msg, policy);
      if (word) throw new HttpsError('invalid-argument', blockedMessage(word));
      if (est !== undefined && est > policy.maxItemPrice) {
        throw new HttpsError('invalid-argument', `물건값은 건당 ${policy.maxItemPrice.toLocaleString('ko-KR')}원까지 부탁할 수 있어요.`);
      }
      if (req.get('closed') === true) throw new HttpsError('failed-precondition', '부탁 접수가 마감됐어요.');
      const cap = req.get('capacity');
      if (typeof cap === 'number' && (req.get('acceptedCount') ?? 0) >= cap) {
        throw new HttpsError('failed-precondition', '자리가 다 찼어요.');
      }
    }
    if (req.get('status') !== 'open' || deadlinePassed(req.get('deadline'), now)) {
      throw new HttpsError('failed-precondition', '모집이 끝난 부탁이에요.');
    }
    const me = await tx.get(paths.user(db, uid));
    if (me.get('suspended') === true) throw new HttpsError('permission-denied', '내 계정은 지금 이용이 제한돼 있어요.');
    await assertNotBlocked(tx, db, uid, owner);

    const prev = app.exists ? (app.get('status') as ApplicationStatus) : null;
    if (prev === 'pending' || prev === 'accepted') throw new HttpsError('already-exists', giving ? '이미 부탁을 보냈어요.' : '이미 지원한 부탁이에요.');
    if (prev === 'rejected') throw new HttpsError('failed-precondition', giving ? '이 글에는 다시 부탁할 수 없어요.' : '이 부탁에는 다시 지원할 수 없어요.');

    const nickname = me.get('nickname');
    tx.set(appRef, {
      helperUid: uid,
      // 요청자가 '받은 지원'을 한 번에 조회할 수 있게(collectionGroup) 남기는 사본
      requesterUid: owner,
      helperName: typeof nickname === 'string' && nickname.trim() ? nickname.trim().slice(0, 20) : '이웃',
      requestTitle: req.get('title') ?? '',
      requestId: rid,
      requestMode: req.get('mode') ?? 'ask',
      offerPrice: offerPrice ?? null,
      msg: msg ?? null,
      ...(giving ? { est: est ?? null, spot: spot ?? null } : {}),
      status: 'pending',
      createdAt: app.exists ? app.get('createdAt') : now,
      updatedAt: now,
    });
    tx.update(reqRef, { applicantCount: FieldValue.increment(1), updatedAt: now });
    return { status: 'pending' as const };
  });
}

export async function withdrawApplication(db: Firestore, uid: string, data: unknown) {
  const rid = id(obj(data).requestId, 'requestId');
  return db.runTransaction(async (tx) => {
    const now = Timestamp.now();
    const appRef = paths.application(db, rid, uid);
    const app = await tx.get(appRef);
    if (!app.exists || app.get('status') !== 'pending') {
      throw new HttpsError('failed-precondition', '취소할 수 있는 지원이 없어요.');
    }
    tx.update(appRef, { status: 'withdrawn', updatedAt: now });
    tx.update(paths.request(db, rid), { applicantCount: FieldValue.increment(-1), updatedAt: now });
    return { status: 'withdrawn' as const };
  });
}

// ── 요청자: 수락 · 거절 · 모집 취소 ─────────────────────────────────────────

export async function acceptApplication(db: Firestore, uid: string, data: unknown) {
  const input = obj(data);
  const rid = id(input.requestId, 'requestId');
  const helperUid = id(input.helperUid, 'helperUid');

  return db.runTransaction(async (tx) => {
    const now = Timestamp.now();
    const reqRef = paths.request(db, rid);
    const appRef = paths.application(db, rid, helperUid);
    const [req, app] = await Promise.all([tx.get(reqRef), tx.get(appRef)]);
    if (!req.exists) throw new HttpsError('not-found', '부탁을 찾을 수 없어요.');
    if (req.get('ownerUid') !== uid) throw new HttpsError('permission-denied', '내가 올린 부탁만 수락할 수 있어요.');
    if (req.get('status') !== 'open') throw new HttpsError('failed-precondition', '모집 중인 글이 아니에요.');
    if (!app.exists || app.get('status') !== 'pending') throw new HttpsError('failed-precondition', '수락할 수 있는 신청이 아니에요.');
    const applicant = helperUid; // 지원서 id = 신청자
    await assertActive(tx, db, uid);
    await assertActive(tx, db, applicant, '상대방');
    await assertNotBlocked(tx, db, uid, applicant);
    const giving = isGiving(req.get('mode'));
    if (giving) {
      const cap = req.get('capacity');
      if (typeof cap === 'number' && (req.get('acceptedCount') ?? 0) >= cap) {
        throw new HttpsError('failed-precondition', '받기로 한 건수가 다 찼어요.');
      }
    }
    const others = giving ? null : await tx.get(reqRef.collection('applications').where('status', '==', 'pending'));

    const tradeRef = db.collection('trades').doc();
    const offer = app.get('offerPrice');
    const msg = app.get('msg');
    tx.set(tradeRef, {
      requestId: rid,
      mode: req.get('mode') ?? 'ask',
      // 도움을 주는 글(going)은 신청자가 요청자, 글쓴이가 수행자
      requesterUid: giving ? applicant : uid,
      helperUid: giving ? uid : applicant,
      applicantUid: applicant,
      applicantName: app.get('helperName') ?? '이웃',
      title: req.get('title') ?? '',
      ...(giving && typeof msg === 'string' && msg ? { ask: msg } : {}),
      ...(giving ? { est: app.get('est') ?? null, spot: app.get('spot') ?? null } : {}),
      price: typeof offer === 'number' ? offer : (req.get('price') ?? 0),
      status: 'matched' satisfies TradeStatus,
      history: [{ status: 'matched', by: uid, at: now }],
      createdAt: now,
      updatedAt: now,
    });
    if (giving) {
      // 가는 길에 여러 부탁을 받는다: 모집은 그대로 열어 둔다
      tx.update(reqRef, { applicantCount: FieldValue.increment(-1), acceptedCount: FieldValue.increment(1), updatedAt: now });
    } else {
      tx.update(reqRef, { status: 'matched', helperUid: applicant, tradeId: tradeRef.id, applicantCount: 0, updatedAt: now });
      for (const d of others!.docs) {
        if (d.id !== applicant) tx.update(d.ref, { status: 'rejected', updatedAt: now });
      }
    }
    tx.update(appRef, { status: 'accepted', tradeId: tradeRef.id, updatedAt: now });
    return { tradeId: tradeRef.id };
  });
}

export async function rejectApplication(db: Firestore, uid: string, data: unknown) {
  const input = obj(data);
  const rid = id(input.requestId, 'requestId');
  const helperUid = id(input.helperUid, 'helperUid');
  return db.runTransaction(async (tx) => {
    const now = Timestamp.now();
    const reqRef = paths.request(db, rid);
    const appRef = paths.application(db, rid, helperUid);
    const [req, app] = await Promise.all([tx.get(reqRef), tx.get(appRef)]);
    if (!req.exists) throw new HttpsError('not-found', '부탁을 찾을 수 없어요.');
    if (req.get('ownerUid') !== uid) throw new HttpsError('permission-denied', '내가 올린 부탁만 처리할 수 있어요.');
    if (!app.exists || app.get('status') !== 'pending') throw new HttpsError('failed-precondition', '거절할 수 있는 신청이 아니에요.');
    tx.update(appRef, { status: 'rejected', updatedAt: now });
    tx.update(reqRef, { applicantCount: FieldValue.increment(-1), updatedAt: now });
    return { status: 'rejected' as const };
  });
}

export async function cancelRequest(db: Firestore, uid: string, data: unknown) {
  const rid = id(obj(data).requestId, 'requestId');
  return db.runTransaction(async (tx) => {
    const now = Timestamp.now();
    const reqRef = paths.request(db, rid);
    const req = await tx.get(reqRef);
    if (!req.exists) throw new HttpsError('not-found', '부탁을 찾을 수 없어요.');
    if (req.get('ownerUid') !== uid) throw new HttpsError('permission-denied', '내가 올린 부탁만 취소할 수 있어요.');
    if (req.get('status') !== 'open') {
      throw new HttpsError('failed-precondition', '모집 중일 때만 취소할 수 있어요. 진행 중인 거래는 거래 화면에서 취소해 주세요.');
    }
    const pending = await tx.get(reqRef.collection('applications').where('status', '==', 'pending'));
    tx.update(reqRef, { status: 'cancelled', applicantCount: 0, updatedAt: now });
    for (const d of pending.docs) tx.update(d.ref, { status: 'rejected', updatedAt: now });
    return { status: 'cancelled' as const };
  });
}

// ── 거래 단계 ─────────────────────────────────────────────────────────────

export async function advanceTrade(db: Firestore, uid: string, data: unknown) {
  const input = obj(data);
  const tid = id(input.tradeId, 'tradeId');
  if (!isTradeAction(input.action)) throw new HttpsError('invalid-argument', 'action 값이 올바르지 않아요.');
  const action = input.action;

  return db.runTransaction(async (tx) => {
    const now = Timestamp.now();
    const tradeRef = paths.trade(db, tid);
    const trade = await tx.get(tradeRef);
    if (!trade.exists) throw new HttpsError('not-found', '거래를 찾을 수 없어요.');
    const requesterUid = trade.get('requesterUid') as string;
    const helperUid = trade.get('helperUid') as string;
    const role: TradeRole | null = uid === requesterUid ? 'requester' : uid === helperUid ? 'helper' : null;
    if (!role) throw new HttpsError('permission-denied', '이 거래의 당사자가 아니에요.');

    const current = trade.get('status') as TradeStatus;
    const res = advance(current, action, role);
    if (!res.ok) {
      throw res.reason === 'wrong-role'
        ? new HttpsError('permission-denied', '이 단계는 상대방이 진행해요.')
        : new HttpsError('failed-precondition', '지금 단계에서는 할 수 없는 동작이에요.', { current });
    }
    const next = res.next;
    const rid = trade.get('requestId') as string;
    const reqRef = paths.request(db, rid);
    const giving = isGiving(trade.get('mode'));
    const applicant = (trade.get('applicantUid') as string | undefined) ?? helperUid;
    // 도움을 주는 글은 거래 하나가 끝나도 글(모집)은 그대로 둔다
    const req = (isFinished(next) && !giving) || next === 'completed' ? await tx.get(reqRef) : null;

    tx.update(tradeRef, {
      status: next,
      history: FieldValue.arrayUnion({ status: next, by: uid, at: now, action }),
      updatedAt: now,
      ...(next === 'completed' ? { completedAt: now } : {}),
      ...(next === 'cancelled' ? { cancelledBy: role } : {}),
    });

    if (next === 'completed' && req?.exists && !giving) {
      tx.update(reqRef, { status: 'done', updatedAt: now });
    }
    if (next === 'completed' && req?.exists) {
      // 공개 완료 기록(A23, LIVE 보드 티커) — 누가 · 무엇을은 빼고 동네 · 종류 · 시각만
      tx.set(db.collection('activity').doc(tid), completionRecord(req, now));
    }
    if (next === 'cancelled' && req?.exists) {
      // 시작 전 취소: 부탁을 다시 모집 중으로 돌린다(마감이 지났으면 만료). 정책은 1차 기본값.
      const reopened: RequestStatus = deadlinePassed(req.get('deadline'), now) ? 'expired' : 'open';
      tx.update(reqRef, { status: reopened, helperUid: FieldValue.delete(), tradeId: FieldValue.delete(), updatedAt: now });
    }
    if (next === 'cancelled') {
      tx.update(paths.application(db, rid, applicant), { status: 'cancelled', updatedAt: now });
      // 가는 김에: 자리 하나를 돌려준다
      if (giving) tx.update(reqRef, { acceptedCount: FieldValue.increment(-1), updatedAt: now });
    }
    return { status: next };
  });
}

/** 완료된 거래의 공개 기록. 이름 · 제목 · 금액 · 정확한 위치는 넣지 않는다 */
export function completionRecord(req: { get(field: string): unknown }, at: Timestamp) {
  const text = (k: string, max: number) => {
    const v = req.get(k);
    return typeof v === 'string' ? v.slice(0, max) : '';
  };
  return {
    kind: 'done',
    mode: text('mode', 10) || 'ask',
    cat: text('cat', 30),
    area: text('area', 40),
    cc: text('cc', 2),
    at,
  };
}

// ── 예약 실행: 마감 지난 모집 정리 ──────────────────────────────────────────

export async function expireOpenRequests(db: Firestore, now = Timestamp.now(), batchLimit = 300): Promise<number> {
  const due = await db
    .collection('requests')
    .where('status', '==', 'open')
    .where('deadline', '<', now)
    .limit(batchLimit)
    .get();
  let n = 0;
  for (const doc of due.docs) {
    const changed = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (fresh.get('status') !== 'open') return false; // 그사이 수락·취소됨
      const pending = await tx.get(doc.ref.collection('applications').where('status', '==', 'pending'));
      tx.update(doc.ref, { status: 'expired', applicantCount: 0, updatedAt: now });
      for (const d of pending.docs) tx.update(d.ref, { status: 'rejected', updatedAt: now });
      return true;
    });
    if (changed) n++;
  }
  return n;
}
