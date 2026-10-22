/**
 * 동선 추천(W7 · A13, Firestore 에뮬레이터): 후보 · 시간대 · 거리 · 차단 · 글쓴이 제외, 공개 격자, 푸시 하루 상한 · 밤 금지
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import { Timestamp } from 'firebase-admin/firestore';

import { PushMessage } from '../../src/notify/deliver';
import { corridorCells, encode } from '../../src/route/geohash';
import { matchRequest, resetMatchCache } from '../../src/route/match';
import { adminDb, clearDb, seedRequest } from './helpers';

const db = adminDb();
const RID = '1760000000100';
const kst = (d: number, h: number, m = 0) => new Date(Date.UTC(2026, 9, d, h - 9, m));
const NOW = kst(22, 14); // 목 14시
const GYODAE = [37.4934, 127.0145] as const; // 교대역 — 방배→강남 동선 위

async function addRoute(uid: string, id: string, extra: Record<string, unknown> = {}) {
  const from = encode(37.4814, 126.9976), to = encode(37.4979, 127.0276);
  await db.collection('users').doc(uid).collection('routes').doc(id).set({
    name: '퇴근',
    from: { label: '방배역', cell6: from },
    to: { label: '강남역', cell6: to },
    days: [1, 2, 3, 4, 5],
    window: { start: '18:00', end: '19:00' },
    mode: 'transit',
    radiusM: 500,
    active: true,
    cells: corridorCells(from, to, 0.5),
    ...extra,
  });
}

const sent: PushMessage[] = [];
const push = async (m: PushMessage) => {
  sent.push(m);
  return [] as string[];
};
const tokens = (uid: string) => db.collection('users').doc(uid).collection('fcmTokens').doc('t').set({});

beforeEach(async () => {
  await clearDb();
  resetMatchCache();
  sent.length = 0;
  await seedRequest(db, RID, 'owner', { title: '교대역 편의점 택배', deadline: Timestamp.fromDate(kst(22, 22)), area: '서초동' });
});

describe('동선 추천', () => {
  test('길 위 · 시간 맞는 사람만 목록에 넣고 알림, 공개 문서엔 격자만', async () => {
    await addRoute('a', 'r1'); // 맞음
    await addRoute('b', 'r1', { days: [6, 7] }); // 주말만
    await addRoute('c', 'r1', { active: false }); // 꺼 둠
    await addRoute('owner', 'r1'); // 글쓴이 본인
    await tokens('a');
    const r = (await matchRequest(db, RID, ...GYODAE, push, NOW))!;
    assert.deepEqual(r.matched, ['a']);
    assert.deepEqual(r.pushed, ['a']);
    const m = (await db.collection('users').doc('a').collection('matches').doc(RID).get()).data()!;
    assert.equal(m.routeName, '퇴근');
    assert.ok(m.extraMin <= 5);
    const req = (await db.collection('requests').doc(RID).get()).data()!;
    assert.equal(req.cell, encode(...GYODAE, 6));
    assert.equal(req.lat, undefined);
    assert.equal(sent.length, 1);
  });

  test('차단 관계 · 마감 지난 부탁 · 가는 김에 글은 빼고, 밤에는 목록만', async () => {
    await addRoute('a', 'r1');
    await addRoute('d', 'r1');
    await db.collection('users').doc('owner').collection('blocks').doc('a').set({});
    await db.collection('users').doc('d').collection('blocks').doc('owner').set({});
    assert.deepEqual((await matchRequest(db, RID, ...GYODAE, push, NOW))!.matched, []);

    await addRoute('e', 'r1');
    const night = (await matchRequest(db, RID, ...GYODAE, push, kst(22, 21, 30)))!;
    assert.deepEqual(night.matched, []); // 21:30이면 퇴근길(18~19시)이 마감(22시) 전에 없다
    await db.collection('requests').doc(RID).update({ deadline: Timestamp.fromDate(kst(23, 20)) });
    const late = (await matchRequest(db, RID, ...GYODAE, push, kst(22, 21, 30)))!;
    assert.deepEqual(late.matched, ['e']);
    assert.deepEqual(late.pushed, []); // 밤 9시 이후라 알림 없음

    await db.collection('requests').doc(RID).update({ mode: 'going' });
    assert.deepEqual((await matchRequest(db, RID, ...GYODAE, push, NOW))!.matched, []);
  });

  test('푸시는 하루 상한까지(기본 3), 설정으로 바꾼다', async () => {
    await addRoute('a', 'r1');
    await tokens('a');
    for (let i = 0; i < 4; i++) {
      const id = `176000000020${i}`;
      await seedRequest(db, id, 'owner', { deadline: Timestamp.fromDate(kst(22, 22)) });
      await matchRequest(db, id, ...GYODAE, push, NOW);
    }
    assert.equal(sent.length, 3);
    assert.equal((await db.collection('users').doc('a').collection('matches').get()).size, 4);

    await db.collection('config').doc('matching').set({ extraMinutes: 1 });
    resetMatchCache();
    await addRoute('f', 'r1');
    const r = (await matchRequest(db, RID, 37.505, 127.0, push, NOW))!; // 길에서 조금 떨어진 곳
    assert.ok(!r.matched.includes('f'));
  });
});
