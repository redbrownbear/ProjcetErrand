/**
 * 포인트 서버 이전(B09) 테스트 (Firestore 에뮬레이터).
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import * as pts from '../../src/points/core';
import { adminDb, clearDb, rejectsWith } from './helpers';

const db = adminDb();
const DAY = 86_400_000;
const T0 = Date.UTC(2026, 9, 23, 3); // 2026-10-23 12시(한국)
const user = (uid: string) => db.collection('users').doc(uid);
const ledger = async (uid: string) => (await user(uid).collection('pointLedger').get()).docs.map((d) => ({ id: d.id, ...d.data() }) as Record<string, unknown>);

beforeEach(clearDb);

describe('적립(B09)', () => {
  test('출석: 금액은 서버가 · 하루 한 번 · 이전 잔액을 원장 첫 줄로', async () => {
    await user('a').set({ nickname: '에이', points: 30 });
    const r = await pts.earnPoints(db, 'a', { kind: 'attend', amount: 9999 }, T0);
    assert.deepEqual([r.amount, r.balance, r.key], [1, 31, 'benefit:attend:2026-10-23']);
    const again = await pts.earnPoints(db, 'a', { kind: 'attend' }, T0 + 3600_000);
    assert.deepEqual([again.amount, again.balance], [0, 31]);
    const rows = await ledger('a');
    assert.deepEqual(rows.map((x) => [x.id, x.amount, x.left]).sort(), [
      ['benefit:attend:2026-10-23', 1, 1],
      ['opening', 30, 30],
    ]);
    assert.equal((await user('a').get()).get('points'), 31);

    // 이레째 연속이면 +10
    for (let d = 1; d <= 5; d++) await pts.earnPoints(db, 'a', { kind: 'attend' }, T0 + d * DAY);
    const seventh = await pts.earnPoints(db, 'a', { kind: 'attend' }, T0 + 6 * DAY);
    assert.equal(seventh.amount, 11);
  });

  test('광고 · 그 밖의 적립은 아직 받지 않음, 정지 계정 거부', async () => {
    await user('a').set({ nickname: '에이' });
    await rejectsWith(pts.earnPoints(db, 'a', { kind: 'ad' }, T0), 'failed-precondition');
    await rejectsWith(pts.earnPoints(db, 'a', { kind: 'mission', id: 'm1' }, T0), 'failed-precondition');
    await user('b').set({ suspended: true });
    await rejectsWith(pts.earnPoints(db, 'b', { kind: 'attend' }, T0), 'permission-denied');
  });
});

describe('교환 · 쿠폰 · 소멸(B09)', () => {
  test('교환은 config/points.shopOpen이 켜져야 · 잔액 부족 거부 · 먼저 쌓인 것부터 차감', async () => {
    await user('a').set({ points: 3000 });
    await rejectsWith(pts.redeemPoints(db, 'a', { productId: 'r3' }, T0), 'failed-precondition');
    await db.collection('config').doc('points').set({ shopOpen: true });
    await rejectsWith(pts.redeemPoints(db, 'a', { productId: 'r1' }, T0), 'failed-precondition'); // 4500P
    await rejectsWith(pts.redeemPoints(db, 'a', { productId: 'nope' }, T0), 'invalid-argument');
    await pts.earnPoints(db, 'a', { kind: 'attend' }, T0);
    const r = await pts.redeemPoints(db, 'a', { productId: 'r3' }, T0 + 1000); // 2000P
    assert.equal(r.balance, 1001);
    const rows = Object.fromEntries((await ledger('a')).map((x) => [x.id, x]));
    assert.equal(rows.opening.left, 1000);
    assert.equal(rows['benefit:attend:2026-10-23'].left, 1);
    assert.equal(rows[`spend_${r.couponId}`].amount, -2000);
    const c = (await user('a').collection('coupons').doc(r.couponId).get()).data()!;
    assert.deepEqual([c.name, c.code, c.status, c.used, c.exp], ['아메리카노', '', 'issuing', false, '2027.10.23']);

    await pts.useCoupon(db, 'a', { couponId: r.couponId });
    assert.equal((await user('a').collection('coupons').doc(r.couponId).get()).get('used'), true);
    await rejectsWith(pts.useCoupon(db, 'a', { couponId: '123' }), 'not-found');
  });

  test('소멸: 기본은 꺼짐, 켜면 유효기간 지난 적립분의 남은 양만', async () => {
    await user('a').set({ points: 0 });
    await pts.earnPoints(db, 'a', { kind: 'attend' }, T0);
    await pts.earnPoints(db, 'a', { kind: 'attend' }, T0 + 200 * DAY);
    assert.equal(await pts.expirePoints(db, T0 + 200 * DAY), 0);
    await db.collection('config').doc('points').set({ expireDays: 180 });
    assert.equal(await pts.expirePoints(db, T0 + 200 * DAY), 1);
    assert.equal(await pts.expirePoints(db, T0 + 200 * DAY), 0); // 두 번 돌아도 한 번
    assert.equal((await user('a').get()).get('points'), 1);
    const rows = await ledger('a');
    assert.ok(rows.some((x) => x.type === 'expire' && x.amount === -1));
  });
});
