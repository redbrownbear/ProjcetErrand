import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { encode } from '../../src/route/geohash';
import { DEFAULT_MATCH, extraMinutes, isQuiet, pointToSegmentKm, windowBefore } from '../../src/route/match';

// 2026-10-22(목) 한국 시간 기준 시각 만들기
const kst = (d: number, h: number, m = 0) => new Date(Date.UTC(2026, 9, d, h - 9, m));

const route = (extra: Record<string, unknown> = {}) => ({
  from: { cell6: encode(37.4814, 126.9976) }, // 방배역
  to: { cell6: encode(37.4979, 127.0276) }, // 강남역
  days: [1, 2, 3, 4, 5],
  window: { start: '08:00', end: '09:00' },
  mode: 'transit',
  ...extra,
});

describe('동선 추천 계산', () => {
  test('점–선분 거리: 선분 위면 0에 가깝고, 끝 너머면 끝점까지', () => {
    assert.ok(pointToSegmentKm(37.49, 127.01, 37.48, 127.0, 37.5, 127.02) < 0.2);
    assert.ok(Math.abs(pointToSegmentKm(37.5, 127.0, 37.5, 127.01, 37.5, 127.02) - 0.88) < 0.05);
  });

  test('추가 소요: 동선 위 교대역은 짧고, 시청은 길다 · 걸어가면 더 길다', () => {
    const near = extraMinutes(route(), 37.4934, 127.0145)!; // 교대역
    const far = extraMinutes(route(), 37.5665, 126.978)!; // 시청
    assert.ok(near <= 5, `교대역 ${near}분`);
    assert.ok(far > DEFAULT_MATCH.extraMinutes, `시청 ${far}분`);
    assert.ok(extraMinutes(route({ mode: 'walk' }), 37.505, 127.01)! > extraMinutes(route({ mode: 'car' }), 37.505, 127.01)!);
  });

  test('시간대: 평일 아침 동선은 목요일 밤에 올라온 "내일 낮까지" 부탁에 맞고, "오늘 밤까지"엔 안 맞는다', () => {
    const now = kst(22, 21); // 목 21시
    assert.equal(windowBefore(route(), now, kst(23, 12)), true); // 금 8시 동선 < 금 12시 마감
    assert.equal(windowBefore(route(), now, kst(22, 23)), false);
    assert.equal(windowBefore(route({ days: [6, 7] }), now, kst(23, 12)), false); // 주말 동선
    assert.equal(windowBefore(route(), kst(22, 8, 30), kst(22, 10)), true); // 지금 시간대 안
    assert.equal(windowBefore(route(), now, null), true); // 마감 없으면 하루 안
  });

  test('조용한 시간: 밤 9시 ~ 아침 8시', () => {
    assert.equal(isQuiet(kst(22, 21), DEFAULT_MATCH), true);
    assert.equal(isQuiet(kst(22, 7, 59), DEFAULT_MATCH), true);
    assert.equal(isQuiet(kst(22, 8), DEFAULT_MATCH), false);
    assert.equal(isQuiet(kst(22, 20, 59), DEFAULT_MATCH), false);
  });
});
