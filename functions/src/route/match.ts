/**
 * 동선 기반 부탁 추천 v0 (설계 W7 · 개발 To-do A13).
 *
 * 부탁의 정확한 위치(`requests/{id}/private/detail`의 lat · lng)가 저장될 때 **한 번만** 계산한다. 주기적 전체 스캔은 없다.
 *  1. 후보 = 매칭 격자(`cells`)에 부탁 격자가 든 정기 동선(collectionGroup 'routes', array-contains). 켜진 것만, 글쓴이 · 차단 관계 제외
 *  2. 시간 = 동선 요일 · 시작 시각이 지금부터 부탁 마감 전 사이에 한 번이라도 있음(한국 시간)
 *  3. 추가 소요 = 부탁 지점과 동선 선분(출발 격자 → 도착 격자)의 거리 × 2 ÷ 이동수단 평균 속도. 설정값(기본 15분) 이하만
 *  4. 결과는 `users/{uid}/matches/{requestId}`('내 동선에 맞는 부탁' 목록). 푸시는 사람당 하루 상한(기본 3) · 밤(21~8시) 금지
 * 외부 경로 API는 쓰지 않는다(직선거리 추정, v1에서 실제 경로로).
 * 부탁의 공개 문서에는 약 1km 격자(`cell`)만 붙인다 — 지도 핀을 동네 칸에 찍을 때 쓴다(A31).
 */
import { Firestore, Timestamp } from 'firebase-admin/firestore';

import { deliver, PushSender } from '../notify/deliver';
import { decode, encode } from './geohash';

export interface MatchPolicy {
  extraMinutes: number;
  dailyPushLimit: number;
  quietStart: number; // 시(한국 시간) — 이 시각부터
  quietEnd: number; // 이 시각 전까지 푸시 안 함
  maxCandidates: number;
}

export const DEFAULT_MATCH: MatchPolicy = { extraMinutes: 15, dailyPushLimit: 3, quietStart: 21, quietEnd: 8, maxCandidates: 200 };

/** 이동수단 평균 속도(km/h) — 직선거리로 우회 시간을 어림하는 데만 쓴다 */
export const SPEED_KMH: Record<string, number> = { walk: 4.5, bike: 15, transit: 20, car: 25 };

const KST = 9 * 3600 * 1000;

let cache: { at: number; policy: MatchPolicy } | null = null;
export function resetMatchCache() {
  cache = null;
}

export async function loadMatchPolicy(db: Firestore): Promise<MatchPolicy> {
  if (cache && Date.now() - cache.at < 5 * 60 * 1000) return cache.policy;
  let policy = DEFAULT_MATCH;
  try {
    const d = (await db.collection('config').doc('matching').get()).data();
    const num = (v: unknown, lo: number, hi: number, dflt: number) => (typeof v === 'number' && v >= lo && v <= hi ? v : dflt);
    if (d) {
      policy = {
        extraMinutes: num(d.extraMinutes, 1, 120, DEFAULT_MATCH.extraMinutes),
        dailyPushLimit: num(d.dailyPushLimit, 0, 20, DEFAULT_MATCH.dailyPushLimit),
        quietStart: num(d.quietStart, 0, 23, DEFAULT_MATCH.quietStart),
        quietEnd: num(d.quietEnd, 0, 23, DEFAULT_MATCH.quietEnd),
        maxCandidates: num(d.maxCandidates, 1, 1000, DEFAULT_MATCH.maxCandidates),
      };
    }
  } catch {
    // 기본값으로
  }
  cache = { at: Date.now(), policy };
  return policy;
}

/** 점에서 선분까지 거리(km) — 짧은 거리라 평면으로 근사 */
export function pointToSegmentKm(pLat: number, pLng: number, aLat: number, aLng: number, bLat: number, bLng: number): number {
  const kx = 111.32 * Math.cos((pLat * Math.PI) / 180), ky = 111.32;
  const ax = (aLng - pLng) * kx, ay = (aLat - pLat) * ky, bx = (bLng - pLng) * kx, by = (bLat - pLat) * ky;
  const dx = bx - ax, dy = by - ay;
  const len2 = dx * dx + dy * dy;
  const t = len2 === 0 ? 0 : Math.max(0, Math.min(1, -(ax * dx + ay * dy) / len2));
  return Math.hypot(ax + t * dx, ay + t * dy);
}

/** 동선을 따라가다 부탁 지점에 들렀다 돌아오는 추가 시간(분) 어림 */
export function extraMinutes(route: Record<string, unknown>, lat: number, lng: number): number | null {
  const f = (route.from as Record<string, unknown> | undefined)?.cell6, t = (route.to as Record<string, unknown> | undefined)?.cell6;
  if (typeof f !== 'string' || typeof t !== 'string') return null;
  const a = decode(f), b = decode(t);
  const km = pointToSegmentKm(lat, lng, a.lat, a.lng, b.lat, b.lng);
  const speed = SPEED_KMH[route.mode as string] ?? SPEED_KMH.transit;
  return Math.round(((km * 2) / speed) * 60);
}

/** 지금(now)부터 마감(deadline) 사이에 동선 시간대가 한 번이라도 있는가. 한국 시간 기준 */
export function windowBefore(route: Record<string, unknown>, now: Date, deadline: Date | null): boolean {
  const days = Array.isArray(route.days) ? (route.days as unknown[]).filter((d): d is number => typeof d === 'number') : [];
  const w = route.window as { start?: unknown; end?: unknown } | undefined;
  if (!days.length || typeof w?.start !== 'string' || typeof w?.end !== 'string') return false;
  const [sh, sm] = w.start.split(':').map(Number);
  const [eh, em] = w.end.split(':').map(Number);
  const until = deadline ?? new Date(now.getTime() + 24 * 3600 * 1000);
  const nowK = new Date(now.getTime() + KST);
  for (let i = 0; i <= 7; i++) {
    const day = new Date(Date.UTC(nowK.getUTCFullYear(), nowK.getUTCMonth(), nowK.getUTCDate() + i));
    const dow = ((day.getUTCDay() + 6) % 7) + 1; // 월 1 ~ 일 7
    if (!days.includes(dow)) continue;
    const start = new Date(day.getTime() + (sh * 60 + sm) * 60000 - KST);
    const end = new Date(day.getTime() + (eh * 60 + em) * 60000 - KST);
    if (end.getTime() <= now.getTime()) continue; // 오늘 이미 지난 시간대
    if (start.getTime() < until.getTime()) return true;
    return false; // 다음 시간대가 마감 뒤
  }
  return false;
}

function kstHour(d: Date) {
  return new Date(d.getTime() + KST).getUTCHours();
}
function kstDay(d: Date) {
  return new Date(d.getTime() + KST).toISOString().slice(0, 10);
}
export function isQuiet(now: Date, p: MatchPolicy): boolean {
  const h = kstHour(now);
  return p.quietStart > p.quietEnd ? h >= p.quietStart || h < p.quietEnd : h >= p.quietStart && h < p.quietEnd;
}

export interface MatchResult {
  cell: string;
  matched: string[]; // 추천을 받은 uid
  pushed: string[];
}

/**
 * 부탁 하나를 동선과 맞춘다. [lat]·[lng]는 private/detail의 정확한 위치(밖으로 내보내지 않는다).
 */
export async function matchRequest(
  db: Firestore,
  requestId: string,
  lat: number,
  lng: number,
  push?: PushSender,
  now = new Date(),
): Promise<MatchResult | null> {
  const reqRef = db.collection('requests').doc(requestId);
  const req = (await reqRef.get()).data();
  if (!req || req.status !== 'open') return null;
  const cell = encode(lat, lng, 6);
  // 공개 문서엔 격자만(지도 핀용). 이미 같으면 쓰지 않는다
  if (req.cell !== cell) await reqRef.update({ cell });
  // 도움을 '요청'하는 동네 부탁만 동선 추천 대상이다(가는 김에는 글쓴이가 수행자, 해외는 동선과 무관)
  if (req.mode !== 'ask') return { cell, matched: [], pushed: [] };

  const policy = await loadMatchPolicy(db);
  const owner = req.ownerUid as string;
  const deadline = req.deadline instanceof Timestamp ? req.deadline.toDate() : null;
  if (deadline && deadline.getTime() <= now.getTime()) return { cell, matched: [], pushed: [] };

  const snap = await db.collectionGroup('routes').where('cells', 'array-contains', cell).limit(policy.maxCandidates).get();
  // 사람마다 가장 짧게 들르는 동선 하나
  const best = new Map<string, { routeId: string; name: string; extra: number }>();
  for (const d of snap.docs) {
    const uid = d.ref.parent.parent?.id;
    const r = d.data();
    if (!uid || uid === owner || r.active === false || r.overLimit === true) continue;
    if (!windowBefore(r, now, deadline)) continue;
    const extra = extraMinutes(r, lat, lng);
    if (extra === null || extra > policy.extraMinutes) continue;
    const cur = best.get(uid);
    if (!cur || extra < cur.extra) best.set(uid, { routeId: d.id, name: typeof r.name === 'string' ? r.name : '내 동선', extra });
  }
  if (!best.size) return { cell, matched: [], pushed: [] };

  // 차단 관계 빼기: 글쓴이가 막은 사람, 글쓴이를 막은 사람
  const ownerBlocks = new Set((await db.collection('users').doc(owner).collection('blocks').get()).docs.map((d) => d.id));
  const matched: string[] = [];
  const pushed: string[] = [];
  const quiet = isQuiet(now, policy);
  const day = kstDay(now);
  const title = typeof req.title === 'string' && req.title ? req.title : '부탁';
  const short = title.length > 20 ? title.slice(0, 20) + '…' : title;

  for (const [uid, m] of best) {
    if (ownerBlocks.has(uid)) continue;
    const user = db.collection('users').doc(uid);
    if ((await user.collection('blocks').doc(owner).get()).exists) continue;
    await user.collection('matches').doc(requestId).set({
      requestId,
      title,
      price: typeof req.price === 'number' ? req.price : 0,
      area: typeof req.area === 'string' ? req.area : (typeof req.region === 'string' ? req.region : ''),
      routeId: m.routeId,
      routeName: m.name,
      extraMin: m.extra,
      deadline: req.deadline ?? null,
      createdAt: Timestamp.fromDate(now),
    });
    matched.push(uid);

    if (!push || quiet || policy.dailyPushLimit <= 0) continue;
    // 하루 상한 — 사람별 카운터를 트랜잭션으로 올린다
    const meta = user.collection('meta').doc('matchPush');
    const ok = await db.runTransaction(async (tx) => {
      const cur = (await tx.get(meta)).data();
      const count = cur?.day === day && typeof cur?.count === 'number' ? cur.count : 0;
      if (count >= policy.dailyPushLimit) return false;
      tx.set(meta, { day, count: count + 1 });
      return true;
    });
    if (!ok) continue;
    await deliver(
      db,
      push,
      {
        to: uid,
        kind: 'match.route',
        title: '내 동선에 맞는 부탁이 있어요',
        body: `"${short}" · ${m.name} 길에서 약 ${Math.max(1, m.extra)}분 더`,
        requestId,
      },
      `match_${requestId}_${uid}`,
    );
    pushed.push(uid);
  }
  return { cell, matched, pushed };
}

