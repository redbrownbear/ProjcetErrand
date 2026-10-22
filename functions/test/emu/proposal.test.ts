/**
 * 제안하기(A15) 서버 함수 테스트 (Firestore 에뮬레이터). 알림은 가짜 전송기로 받는다.
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import * as core from '../../src/errand/core';
import * as chat from '../../src/chat/core';
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

describe('자리 예약(A30)', () => {
  const doc = async (id: string) => (await db.collection('proposals').doc(id).get()).data()!;
  const join = async (id: string, uid: string) => (await db.collection('proposals').doc(id).collection('joins').doc(uid).get()).get('status');

  test('정원이 차면 대기 예약 · 취소하면 맨 앞 대기자가 이어받음', async () => {
    const { proposalId: id } = await p.createProposal(db, 'owner', input({ max: 1 }));
    await p.joinProposal(db, 'a', { proposalId: id }, send);
    await rejectsWith(p.joinProposal(db, 'b', { proposalId: id }, send), 'failed-precondition');
    const r = await p.joinProposal(db, 'b', { proposalId: id, wait: true }, send, Date.now());
    assert.equal(r.waiting, true);
    await p.joinProposal(db, 'b', { proposalId: id, wait: true }, send); // 두 번 눌러도 한 줄
    await p.joinProposal(db, 'c', { proposalId: id, wait: true }, send, Date.now() + 1000);
    assert.equal((await doc(id)).waitCount, 2);
    assert.equal((await doc(id)).joinedCount, 1);

    await p.leaveProposal(db, 'a', { proposalId: id }, send);
    assert.equal(await join(id, 'b'), 'joined');
    assert.equal(await join(id, 'c'), 'waiting');
    assert.equal((await doc(id)).joinedCount, 1);
    assert.equal((await doc(id)).waitCount, 1);
    assert.deepEqual(await notices('b'), ['proposal.promoted']);

    // 대기 취소는 자리와 상관없이
    await p.leaveProposal(db, 'c', { proposalId: id }, send);
    assert.equal((await doc(id)).waitCount, 0);
    assert.ok((await notices('owner')).includes('proposal.wait'));
  });

  test('제안자가 정원을 늘리면 먼저 온 순서로 자동 참여', async () => {
    const { proposalId: id } = await p.createProposal(db, 'owner', input({ max: 1 }));
    await p.joinProposal(db, 'a', { proposalId: id }, send);
    await p.joinProposal(db, 'c', { proposalId: id, wait: true }, send, Date.now());
    await p.joinProposal(db, 'b', { proposalId: id, wait: true }, send, Date.now() + 1000);
    await rejectsWith(p.raiseProposalMax(db, 'a', { proposalId: id, max: 3 }, send), 'permission-denied');
    await rejectsWith(p.raiseProposalMax(db, 'owner', { proposalId: id, max: 1 }, send), 'invalid-argument');
    const r = await p.raiseProposalMax(db, 'owner', { proposalId: id, max: 2 }, send);
    assert.equal(r.promoted, 1);
    assert.equal(await join(id, 'c'), 'joined');
    assert.equal(await join(id, 'b'), 'waiting');
    await p.raiseProposalMax(db, 'owner', { proposalId: id, max: 0 }, send); // 제한 없음 → 모두
    const d = await doc(id);
    assert.equal(d.max, 0);
    assert.equal(d.joinedCount, 3);
    assert.equal(d.waitCount, 0);
  });

  test('지금 인원으로 진행하면 대기는 끝나고 알림', async () => {
    const { proposalId: id } = await p.createProposal(db, 'owner', input({ max: 1 }));
    await p.joinProposal(db, 'a', { proposalId: id }, send);
    await p.joinProposal(db, 'b', { proposalId: id, wait: true }, send);
    await p.decideProposal(db, 'owner', { proposalId: id, action: 'proceed' }, send);
    assert.equal(await join(id, 'b'), 'cancelled');
    assert.equal((await doc(id)).waitCount, 0);
    assert.deepEqual(await notices('b'), ['proposal.waitClosed']);
    assert.deepEqual(await notices('a'), ['proposal.proceed']);
  });
});

describe('다른 걸 부탁(A29)', () => {
  test('따로 부탁 → 수락하면 채팅되는 거래, 단계 · 취소는 거래만 바꾼다', async () => {
    const { proposalId } = await p.createProposal(db, 'owner', input());
    await p.askProposer(db, 'a', { proposalId, item: '여수 돌산 갓 2kg', est: 20000, note: '가능하면요' }, send);
    // 기다리는 동안 다시 보내면 내용만 고친다(알림은 한 번)
    await p.askProposer(db, 'a', { proposalId, item: '여수 돌산 갓 3kg', est: 25000 }, send);
    const ask = (await db.collection('proposals').doc(proposalId).collection('asks').doc('a').get()).data()!;
    assert.equal(ask.item, '여수 돌산 갓 3kg');
    assert.equal(ask.status, 'pending');
    assert.deepEqual(await notices('owner'), ['proposal.ask']);

    await rejectsWith(p.answerProposerAsk(db, 'a', { proposalId, askerUid: 'a', accept: true }), 'permission-denied');
    const r = await p.answerProposerAsk(db, 'owner', { proposalId, askerUid: 'a', accept: true }, send);
    assert.equal(r.status, 'accepted');
    const t = (await db.collection('trades').doc(r.tradeId!).get()).data()!;
    assert.equal(t.mode, 'proposal');
    assert.equal(t.requestId, `proposal:${proposalId}`);
    assert.equal(t.requesterUid, 'a');
    assert.equal(t.helperUid, 'owner');
    assert.equal(t.status, 'matched');
    assert.deepEqual(await notices('a'), ['proposal.askAccepted']);
    await rejectsWith(p.answerProposerAsk(db, 'owner', { proposalId, askerUid: 'a', accept: false }), 'failed-precondition');
    await rejectsWith(p.askProposer(db, 'a', { proposalId, item: '하나 더' }), 'failed-precondition');

    // 채팅 · 단계 · 시작 전 취소가 부탁 글 없이도 된다
    await chat.sendMessage(db, 'a', { tradeId: r.tradeId, text: '언제쯤 될까요?' });
    await core.advanceTrade(db, 'owner', { tradeId: r.tradeId, action: 'cancel' });
    assert.equal((await db.collection('trades').doc(r.tradeId!).get()).get('status'), 'cancelled');
  });

  test('거절 · 다시 보내기, 내 제안 · 금지 품목 · 상한 · 취소된 제안 · 차단은 거부', async () => {
    const { proposalId } = await p.createProposal(db, 'owner', input());
    await p.askProposer(db, 'b', { proposalId, item: '갓김치 2kg' }, send);
    await p.answerProposerAsk(db, 'owner', { proposalId, askerUid: 'b', accept: false }, send);
    assert.deepEqual(await notices('b'), ['proposal.askRejected']);
    await p.askProposer(db, 'b', { proposalId, item: '갓김치 1kg' }, send);
    assert.equal((await db.collection('proposals').doc(proposalId).collection('asks').doc('b').get()).get('status'), 'pending');

    await rejectsWith(p.askProposer(db, 'owner', { proposalId, item: '무엇' }), 'failed-precondition');
    await rejectsWith(p.askProposer(db, 'c', { proposalId, item: '안동 소주' }), 'invalid-argument');
    await rejectsWith(p.askProposer(db, 'c', { proposalId, item: '갓', est: 60000 }), 'invalid-argument');
    await rejectsWith(p.askProposer(db, 'c', { proposalId, item: '' }), 'invalid-argument');
    await db.collection('users').doc('owner').collection('blocks').doc('c').set({});
    await rejectsWith(p.askProposer(db, 'c', { proposalId, item: '갓' }), 'permission-denied');
    await p.decideProposal(db, 'owner', { proposalId, action: 'cancel' });
    await rejectsWith(p.askProposer(db, 'a', { proposalId, item: '갓' }), 'failed-precondition');
  });
});
