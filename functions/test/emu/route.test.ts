/**
 * 정기 동선 격자 계산(W6 · A02, Firestore 에뮬레이터): 처음 계산, 바뀐 것만 다시, 개수 상한, 잘못된 격자
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import { Timestamp } from 'firebase-admin/firestore';

import { encode } from '../../src/route/geohash';
import { computeRouteCells, MAX_ROUTES } from '../../src/route/core';
import { adminDb, clearDb } from './helpers';

const db = adminDb();
const UID = 'walker';
const col = () => db.collection('users').doc(UID).collection('routes');
const A = encode(37.4814, 126.9976, 6);
const B = encode(37.4979, 127.0276, 6);
const route = (i: number, extra: Record<string, unknown> = {}) => ({
  name: `동선${i}`,
  from: { label: '방배역', cell6: A },
  to: { label: '강남역', cell6: B },
  days: [1, 2, 3, 4, 5],
  window: { start: '08:00', end: '09:00' },
  mode: 'transit',
  radiusM: 500,
  active: true,
  createdAt: Timestamp.fromMillis(1_760_000_000_000 + i * 1000),
  ...extra,
});

beforeEach(clearDb);

describe('정기 동선 격자', () => {
  test('처음 만들면 격자를 붙이고, 같은 값으로 다시 불려도 다시 계산하지 않는다', async () => {
    await col().doc('r0').set(route(0));
    const after = (await col().doc('r0').get()).data()!;
    const cells = await computeRouteCells(db, UID, 'r0', undefined, after);
    assert.ok(cells && cells.includes(A) && cells.includes(B));
    const saved = (await col().doc('r0').get()).data()!;
    assert.deepEqual(saved.cells, cells);
    assert.equal(await computeRouteCells(db, UID, 'r0', after, saved), null);
    // 반경을 바꾸면 다시
    const wider = { ...saved, radiusM: 3000 };
    const again = await computeRouteCells(db, UID, 'r0', saved, wider);
    assert.ok(again && again.length > cells!.length);
  });

  test(`${MAX_ROUTES}개를 넘긴 동선은 격자를 비우고 표시한다`, async () => {
    for (let i = 0; i <= MAX_ROUTES; i++) await col().doc(`r${i}`).set(route(i));
    const last = (await col().doc(`r${MAX_ROUTES}`).get()).data()!;
    assert.deepEqual(await computeRouteCells(db, UID, `r${MAX_ROUTES}`, undefined, last), []);
    assert.equal((await col().doc(`r${MAX_ROUTES}`).get()).get('overLimit'), true);
  });

  test('격자가 아니면 빈 목록', async () => {
    await col().doc('bad').set(route(0, { from: { label: '집', cell6: 'zzz' } }));
    const d = (await col().doc('bad').get()).data()!;
    assert.deepEqual(await computeRouteCells(db, UID, 'bad', undefined, d), []);
  });
});
