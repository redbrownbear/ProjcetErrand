/**
 * 정기 동선(설계 W6 · 개발 To-do A02). 앱은 `users/{uid}/routes/{id}`에 출발 · 도착 격자(geohash 6자리)와
 * 요일 · 시간대 · 이동수단 · 반경만 쓴다(정확한 좌표 없음, 규칙이 막는다).
 * 매칭용 격자 목록 `cells`는 이 트리거가 계산해 붙인다 — 앱이 보낸 격자는 믿지 않는다.
 * 한 사람당 [MAX_ROUTES]개까지. 넘친 동선은 격자를 비우고 `overLimit`로 표시한다(매칭에서 빠진다).
 */
import { Firestore, Timestamp } from 'firebase-admin/firestore';

import { corridorCells, isGeohash } from './geohash';
import { C } from '../shared/paths';

export const MAX_ROUTES = 6;
export const MIN_RADIUS_M = 100;
export const MAX_RADIUS_M = 8000;
export const DEFAULT_RADIUS_M = 500;

type Doc = Record<string, unknown> | undefined;

const cellOf = (p: unknown) => (p && typeof p === 'object' ? (p as Record<string, unknown>).cell6 : undefined);

/** 다시 계산해야 하는 변경인가(격자 · 반경이 바뀌었거나 아직 없음) */
function needsCells(before: Doc, after: Doc): boolean {
  if (!after) return false;
  if (!before) return true;
  return cellOf(before.from) !== cellOf(after.from) || cellOf(before.to) !== cellOf(after.to) || before.radiusM !== after.radiusM || !Array.isArray(after.cells);
}

export async function computeRouteCells(db: Firestore, uid: string, routeId: string, before: Doc, after: Doc): Promise<string[] | null> {
  if (!needsCells(before, after)) return null;
  const ref = db.collection(C.users).doc(uid).collection(C.routes).doc(routeId);
  const from = cellOf(after!.from), to = cellOf(after!.to);
  if (!isGeohash(from) || !isGeohash(to)) {
    await ref.update({ cells: [], cellsAt: Timestamp.now() });
    return [];
  }
  // 한 사람당 개수 제한: 만든 순서로 MAX_ROUTES개 안에 들어야 매칭에 쓴다
  const all = await db.collection(C.users).doc(uid).collection(C.routes).orderBy('createdAt').limit(MAX_ROUTES + 1).get();
  const rank = all.docs.findIndex((d) => d.id === routeId);
  if (rank < 0 || rank >= MAX_ROUTES) {
    await ref.update({ cells: [], overLimit: true, cellsAt: Timestamp.now() });
    return [];
  }
  const r = typeof after!.radiusM === 'number' ? after!.radiusM : DEFAULT_RADIUS_M;
  const radiusM = Math.min(MAX_RADIUS_M, Math.max(MIN_RADIUS_M, r));
  const cells = corridorCells(from, to, radiusM / 1000);
  await ref.update({ cells, overLimit: false, cellsAt: Timestamp.now() });
  return cells;
}
