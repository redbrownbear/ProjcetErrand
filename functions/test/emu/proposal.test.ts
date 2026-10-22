/**
 * 제안하기(A15) 서버 함수 테스트 (Firestore 에뮬레이터). 알림은 가짜 전송기로 받는다.
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import * as p from '../../src/proposal/core';
import { resetPolicyCache } from '../../src/safety/policy';
import { adminDb, clearDb, rejectsWith } from './helpers';

const db = adminDb();
const send = async () => [];
const day = (offsetDays: number) => p.kstToday(Date.now() + offsetDays * 86_400_000);
const input = (extra: Record<string, unknown> = {}) => ({
  abroad: false,
  from: '여수',
  to: '서울',
  item: '갓김치 1kg',
  price: 15000,
  fee: 3000,
  day: day(2),
  max: 2,
  delivery: 'meet',
  meetPlace: '강남역 11번 출구',
  meetTime: '저녁 7시',
  ...extra,
});

beforeEach(async () => {
  await clearDb();
  resetPolicyCache();
  await db.collection('users').doc('owner').set({ nickname: '여수댁' });
  await db.collection('users').doc('a').set({ nickname: '에이' });
  await db.collection('users').doc('b').set({ nickname: '비' });
  await db.collection('users').doc('c').set({ nickname: '씨' });
});

const notices = async (uid: string) =>
  (await db.collection('users').doc(uid).collection('notifications').get()).docs.map((d) => d.get('kind') as string).sort();

describe('제안 올리기', () => {
  test('검사: 같은 지역 · 금지 품목 · 물건값 상한 · 날짜 · 받는 장소', async () => {
    const { proposalId } = await p.createProposal(db, 'owner', input());
    const doc = (await db.collection('proposals').doc(proposalId).get()).data()!;
    assert.equal(doc.who, '여수댁');
    assert.equal(doc.status, 'open');
    assert.equal(doc.joinedCount, 0);
    assert.equal(doc.delivery, 'meet');

    await rejectsWith(p.createProposal(db, 'owner', input({ to: '여수' })), 'invalid-argument');
    await rejectsWith(p.createProposal(db, 'owner', input({ item: '안동 소주' })), 'invalid-argument');
    await rejectsWith(p.createProposal(db, 'owner', input({ price: 60000 })), 'invalid-argument');
    await p.createProposal(db, 'owner', input({ abroad: true, cc: 'JP', from: '도쿄', price: 60000, delivery: 'each' }));
    await rejectsWith(p.createProposal(db, 'owner', input({ day: day(-1) })), 'invalid-argument');
    await rejectsWith(p.createProposal(db, 'owner', input({ day: day(90) })), 'invalid-argument');
    await rejectsWith(p.createProposal(db, 'owner', input({ meetPlace: '' })), 'invalid-argument');
    await rejectsWith(p.createProposal(db, 'owner', input({ max: 99 })), 'invalid-argument');
  });
});

describe('신청 · 취소 · 제안자 결정', () => {
  test('정원 · 내 제안 · 중복 신청 · 취소하면 자리 반환, 제안자에게 알림', async () => {
    const { proposalId: id } = await p.createProposal(db, 'owner', input());
    await rejectsWith(p.joinProposal(db, 'owner', { proposalId: id }, send), 'failed-precondition');
    await p.joinProposal(db, 'a', { proposalId: id }, send);
    await p.joinProposal(db, 'a', { proposalId: id }, send); // 두 번 눌러도 한 자리
    await p.joinProposal(db, 'b', { proposalId: id }, send);
    await rejectsWith(p.joinProposal(db, 'c', { proposalId: id }, send), 'failed-precondition');
    assert.equal((await db.collection('proposals').doc(id).get()).get('joinedCount'), 2);

    await p.leaveProposal(db, 'b', { proposalId: id }, send);
    assert.equal((await db.collection('proposals').doc(id).get()).get('joinedCount'), 1);
    await p.joinProposal(db, 'c', { proposalId: id }, send);
    assert.deepEqual(await notices('owner'), ['proposal.join', 'proposal.join', 'proposal.join', 'proposal.leave']);
  });

  test('차단 · 정지 · 날짜 지남은 거부', async () => {
    const { proposalId: id } = await p.createProposal(db, 'owner', input());
    await db.collection('users').doc('owner').collection('blocks').doc('a').set({});
    await rejectsWith(p.joinProposal(db, 'a', { proposalId: id }, send), 'permission-denied');
    await db.collection('users').doc('b').set({ suspended: true }, { merge: true });
    await rejectsWith(p.joinProposal(db, 'b', { proposalId: id }, send), 'permission-denied');
    await rejectsWith(p.joinProposal(db, 'c', { proposalId: id }, send, Date.now() + 5 * 86_400_000), 'failed-precondition');
  });

  test('그래도 진행: 새 신청 막힘 · 취소 못 함 · 신청자에게 받는 곳 안내', async () => {
    const { proposalId: id } = await p.createProposal(db, 'owner', input({ max: 5 }));
    await p.joinProposal(db, 'a', { proposalId: id }, send);
    await rejectsWith(p.decideProposal(db, 'a', { proposalId: id, action: 'proceed' }, send), 'permission-denied');
    await p.decideProposal(db, 'owner', { proposalId: id, action: 'proceed' }, send);
    assert.equal((await db.collection('proposals').doc(id).get()).get('status'), 'proceeding');
    await rejectsWith(p.joinProposal(db, 'b', { proposalId: id }, send), 'failed-precondition');
    await rejectsWith(p.leaveProposal(db, 'a', { proposalId: id }, send), 'failed-precondition');
    const n = await db.collection('users').doc('a').collection('notifications').get();
    assert.equal(n.docs[0].get('kind'), 'proposal.proceed');
    assert.match(n.docs[0].get('body'), /강남역 11번 출구/);
    assert.equal(n.docs[0].get('proposalId'), id);
  });

  test('취소: 신청이 모두 취소되고 알림', async () => {
    const { proposalId: id } = await p.createProposal(db, 'owner', input({ max: 0 }));
    await p.joinProposal(db, 'a', { proposalId: id }, send);
    await p.joinProposal(db, 'b', { proposalId: id }, send);
    await p.decideProposal(db, 'owner', { proposalId: id, action: 'cancel' }, send);
    const doc = (await db.collection('proposals').doc(id).get()).data()!;
    assert.equal(doc.status, 'cancelled');
    assert.equal(doc.joinedCount, 0);
    const joins = await db.collection('proposals').doc(id).collection('joins').get();
    assert.deepEqual(joins.docs.map((d) => d.get('status')), ['cancelled', 'cancelled']);
    assert.deepEqual(await notices('b'), ['proposal.cancelled']);
    await rejectsWith(p.decideProposal(db, 'owner', { proposalId: id, action: 'cancel' }, send), 'failed-precondition');
  });
});
