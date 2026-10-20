/**
 * 거래 흐름 통합 테스트 (Firestore 에뮬레이터).
 * 설계 문서 W3 검증 기준: 두 계정으로 지원→수락→시작→완료→확인, 역할·순서 위반 거부, 중복 호출 1회만 반영.
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import { Timestamp } from 'firebase-admin/firestore';

import * as core from '../../src/errand/core';
import { adminDb, clearDb, rejectsWith, seedRequest } from './helpers';

const db = adminDb();
const OWNER = 'owner-1';
const HELPER = 'helper-1';
const OTHER = 'helper-2';
const RID = '1760000000000';

async function req() {
  return (await db.collection('requests').doc(RID).get()).data()!;
}
async function app(uid: string) {
  return (await db.collection('requests').doc(RID).collection('applications').doc(uid).get()).data();
}
async function trade(tid: string) {
  return (await db.collection('trades').doc(tid).get()).data()!;
}

beforeEach(async () => {
  await clearDb();
  await seedRequest(db, RID, OWNER);
});

describe('정상 흐름', () => {
  test('지원 → 수락 → 시작 → 완료 → 확인', async () => {
    assert.deepEqual(await core.applyToRequest(db, HELPER, { requestId: RID, offerPrice: 4000, msg: '퇴근길에 갈게요' }), {
      status: 'pending',
    });
    assert.equal((await req()).applicantCount, 1);
    const a = (await app(HELPER))!;
    assert.equal(a.requesterUid, OWNER, '요청자 조회용 사본');
    assert.equal(a.requestTitle, '편의점 택배 찾아 주세요');
    assert.equal(a.helperName, '이웃', '닉네임이 없으면 이웃');

    const { tradeId } = await core.acceptApplication(db, OWNER, { requestId: RID, helperUid: HELPER });
    let t = await trade(tradeId);
    assert.equal(t.status, 'matched');
    assert.equal(t.price, 4000, '제안 금액이 합의 금액으로');
    assert.equal((await req()).status, 'matched');
    assert.equal((await req()).helperUid, HELPER);
    assert.equal((await app(HELPER))!.status, 'accepted');

    await core.advanceTrade(db, HELPER, { tradeId, action: 'start' });
    await core.advanceTrade(db, HELPER, { tradeId, action: 'finish' });
    await core.advanceTrade(db, OWNER, { tradeId, action: 'confirm' });
    t = await trade(tradeId);
    assert.equal(t.status, 'completed');
    assert.equal(t.history.length, 4);
    assert.equal((await req()).status, 'done');
  });

  test('보완 요청 → 다시 완료', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    const { tradeId } = await core.acceptApplication(db, OWNER, { requestId: RID, helperUid: HELPER });
    await core.advanceTrade(db, HELPER, { tradeId, action: 'start' });
    await core.advanceTrade(db, HELPER, { tradeId, action: 'finish' });
    await core.advanceTrade(db, OWNER, { tradeId, action: 'revise' });
    assert.equal((await trade(tradeId)).status, 'working');
    assert.equal((await trade(tradeId)).price, 3000, '제안이 없으면 부탁 금액');
  });
});

describe('역할·순서 위반', () => {
  test('요청자가 시작, 수행자가 확인 → 거부', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    const { tradeId } = await core.acceptApplication(db, OWNER, { requestId: RID, helperUid: HELPER });
    await rejectsWith(core.advanceTrade(db, OWNER, { tradeId, action: 'start' }), 'permission-denied');
    await core.advanceTrade(db, HELPER, { tradeId, action: 'start' });
    await core.advanceTrade(db, HELPER, { tradeId, action: 'finish' });
    await rejectsWith(core.advanceTrade(db, HELPER, { tradeId, action: 'confirm' }), 'permission-denied');
  });

  test('단계 건너뛰기 · 제3자 호출 → 거부', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    const { tradeId } = await core.acceptApplication(db, OWNER, { requestId: RID, helperUid: HELPER });
    await rejectsWith(core.advanceTrade(db, HELPER, { tradeId, action: 'finish' }), 'failed-precondition');
    await rejectsWith(core.advanceTrade(db, OTHER, { tradeId, action: 'start' }), 'permission-denied');
    await rejectsWith(core.advanceTrade(db, HELPER, { tradeId, action: 'teleport' }), 'invalid-argument');
  });

  test('남의 부탁 수락 · 내 부탁 지원 → 거부', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    await rejectsWith(core.acceptApplication(db, OTHER, { requestId: RID, helperUid: HELPER }), 'permission-denied');
    await rejectsWith(core.applyToRequest(db, OWNER, { requestId: RID }), 'failed-precondition');
  });

  test('입력 검증', async () => {
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: RID, offerPrice: -1 }), 'invalid-argument');
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: RID, offerPrice: 1.5 }), 'invalid-argument');
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: 'a/b' }), 'invalid-argument');
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: RID, msg: 'x'.repeat(301) }), 'invalid-argument');
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: 'nope' }), 'not-found');
  });
});

describe('중복 · 동시 호출', () => {
  test('같은 단계를 두 번 → 한 번만 반영', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    const { tradeId } = await core.acceptApplication(db, OWNER, { requestId: RID, helperUid: HELPER });
    await core.advanceTrade(db, HELPER, { tradeId, action: 'start' });
    await rejectsWith(core.advanceTrade(db, HELPER, { tradeId, action: 'start' }), 'failed-precondition');
    assert.equal((await trade(tradeId)).history.length, 2);
  });

  test('같은 지원 10번 동시에 → 1건만, 지원자 수 1', async () => {
    const results = await Promise.allSettled(
      Array.from({ length: 10 }, () => core.applyToRequest(db, HELPER, { requestId: RID })),
    );
    assert.equal(results.filter((r) => r.status === 'fulfilled').length, 1);
    assert.equal((await req()).applicantCount, 1);
  });

  test('이미 지원 → already-exists, 수락 두 번 → 두 번째 거부', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: RID }), 'already-exists');
    await core.acceptApplication(db, OWNER, { requestId: RID, helperUid: HELPER });
    await rejectsWith(core.acceptApplication(db, OWNER, { requestId: RID, helperUid: HELPER }), 'failed-precondition');
  });
});

describe('수락 · 거절 · 취소 · 철회', () => {
  test('수락하면 다른 지원은 거절되고 모집이 닫힌다', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    await core.applyToRequest(db, OTHER, { requestId: RID });
    assert.equal((await req()).applicantCount, 2);
    await core.acceptApplication(db, OWNER, { requestId: RID, helperUid: HELPER });
    assert.equal((await app(OTHER))!.status, 'rejected');
    assert.equal((await req()).applicantCount, 0);
    await rejectsWith(core.applyToRequest(db, 'helper-3', { requestId: RID }), 'failed-precondition');
  });

  test('거절된 지원은 다시 지원할 수 없고, 철회한 지원은 다시 할 수 있다', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    await core.rejectApplication(db, OWNER, { requestId: RID, helperUid: HELPER });
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: RID }), 'failed-precondition');

    await core.applyToRequest(db, OTHER, { requestId: RID });
    await core.withdrawApplication(db, OTHER, { requestId: RID });
    assert.equal((await req()).applicantCount, 0);
    await core.applyToRequest(db, OTHER, { requestId: RID });
    assert.equal((await req()).applicantCount, 1);
  });

  test('시작 전 거래 취소 → 부탁이 다시 모집 중, 지원서는 cancelled', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    const { tradeId } = await core.acceptApplication(db, OWNER, { requestId: RID, helperUid: HELPER });
    await core.advanceTrade(db, HELPER, { tradeId, action: 'cancel' });
    const r = await req();
    assert.equal(r.status, 'open');
    assert.equal(r.helperUid, undefined);
    assert.equal((await app(HELPER))!.status, 'cancelled');
    assert.equal((await trade(tradeId)).cancelledBy, 'helper');
  });

  test('시작 후에는 취소 불가', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    const { tradeId } = await core.acceptApplication(db, OWNER, { requestId: RID, helperUid: HELPER });
    await core.advanceTrade(db, HELPER, { tradeId, action: 'start' });
    await rejectsWith(core.advanceTrade(db, OWNER, { tradeId, action: 'cancel' }), 'failed-precondition');
  });

  test('모집 취소는 모집 중일 때만, 대기 지원은 거절 처리', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    await rejectsWith(core.cancelRequest(db, HELPER, { requestId: RID }), 'permission-denied');
    await core.cancelRequest(db, OWNER, { requestId: RID });
    assert.equal((await req()).status, 'cancelled');
    assert.equal((await app(HELPER))!.status, 'rejected');
    await rejectsWith(core.cancelRequest(db, OWNER, { requestId: RID }), 'failed-precondition');
  });
});

describe('차단 · 정지 · 마감', () => {
  test('차단 관계면 지원·수락 불가', async () => {
    await db.collection('users').doc(OWNER).collection('blocks').doc(HELPER).set({ at: Timestamp.now() });
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: RID }), 'permission-denied');
  });

  test('이용 정지 계정은 지원 불가, 정지된 지원자는 수락 불가', async () => {
    await db.collection('users').doc(HELPER).set({ suspended: true });
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: RID }), 'permission-denied');

    await core.applyToRequest(db, OTHER, { requestId: RID });
    await db.collection('users').doc(OTHER).set({ suspended: true });
    await rejectsWith(core.acceptApplication(db, OWNER, { requestId: RID, helperUid: OTHER }), 'permission-denied');
  });

  test('마감 지난 부탁: 지원 불가, 정리 작업이 expired로 바꾸고 대기 지원 거절', async () => {
    await core.applyToRequest(db, HELPER, { requestId: RID });
    await db.collection('requests').doc(RID).update({ deadline: Timestamp.fromMillis(Date.now() - 1000) });
    await rejectsWith(core.applyToRequest(db, OTHER, { requestId: RID }), 'failed-precondition');

    await seedRequest(db, '1760000000001', OWNER); // 마감 전 — 그대로 남아야 함
    const n = await core.expireOpenRequests(db);
    assert.equal(n, 1);
    assert.equal((await req()).status, 'expired');
    assert.equal((await app(HELPER))!.status, 'rejected');
    assert.equal((await db.collection('requests').doc('1760000000001').get()).get('status'), 'open');
  });
});

describe('가는 김에 · 제가 가요(going) — 글쓴이가 도와주는 쪽', () => {
  const GID = '1760000000005';
  beforeEach(async () => {
    await seedRequest(db, GID, OWNER, { mode: 'going', title: '내일 오사카 가요', price: 3000 });
  });

  test('신청자가 요청자, 글쓴이가 수행자. 여러 명 수락해도 모집은 열려 있고 거래는 따로', async () => {
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: GID }), 'invalid-argument'); // 무엇을 부탁할지 없음
    await core.applyToRequest(db, HELPER, { requestId: GID, msg: '곤약젤리 2봉', offerPrice: 5000 });
    await core.applyToRequest(db, OTHER, { requestId: GID, msg: '동전파스' });
    const a = await db.collection('requests').doc(GID).collection('applications').doc(HELPER).get();
    assert.equal(a.get('requestMode'), 'going');

    const { tradeId: t1 } = await core.acceptApplication(db, OWNER, { requestId: GID, helperUid: HELPER });
    let r = (await db.collection('requests').doc(GID).get()).data()!;
    assert.equal(r.status, 'open', '모집은 그대로');
    assert.equal(r.applicantCount, 1);
    const tr = await trade(t1);
    assert.equal(tr.requesterUid, HELPER, '신청자가 요청자');
    assert.equal(tr.helperUid, OWNER, '글쓴이가 수행자');
    assert.equal(tr.ask, '곤약젤리 2봉');
    assert.equal(tr.price, 5000);
    assert.equal((await db.collection('requests').doc(GID).collection('applications').doc(OTHER).get()).get('status'), 'pending', '다른 신청은 그대로');

    const { tradeId: t2 } = await core.acceptApplication(db, OWNER, { requestId: GID, helperUid: OTHER });
    assert.equal((await trade(t2)).price, 3000, '제안이 없으면 글의 사례비');

    // 수행자(글쓴이)가 시작·완료 요청, 요청자(신청자)가 확인
    await rejectsWith(core.advanceTrade(db, HELPER, { tradeId: t1, action: 'start' }), 'permission-denied');
    await core.advanceTrade(db, OWNER, { tradeId: t1, action: 'start' });
    await core.advanceTrade(db, OWNER, { tradeId: t1, action: 'finish' });
    await core.advanceTrade(db, HELPER, { tradeId: t1, action: 'confirm' });
    assert.equal((await trade(t1)).status, 'completed');
    r = (await db.collection('requests').doc(GID).get()).data()!;
    assert.equal(r.status, 'open', '거래 하나가 끝나도 글은 그대로');

    // 시작 전 취소 → 그 신청만 cancelled, 글은 그대로
    await core.advanceTrade(db, OTHER, { tradeId: t2, action: 'cancel' });
    assert.equal((await db.collection('requests').doc(GID).collection('applications').doc(OTHER).get()).get('status'), 'cancelled');
    assert.equal((await db.collection('requests').doc(GID).get()).get('status'), 'open');
  });
});

describe('가는 김에 v78 — 정원·접수 마감·금지 품목', () => {
  const GID = '1760000000007';
  beforeEach(async () => {
    await seedRequest(db, GID, OWNER, { mode: 'going', title: '죽전역 이마트', price: 0, capacity: 1, kinds: ['사다주기'] });
  });

  test('받기로 한 건수가 차면 더 신청·수락할 수 없고, 시작 전 취소하면 자리가 돌아온다', async () => {
    await core.applyToRequest(db, HELPER, { requestId: GID, msg: '우유 1L', offerPrice: 1500, est: 3000, spot: '문 앞' });
    await core.applyToRequest(db, OTHER, { requestId: GID, msg: '식빵 1봉', offerPrice: 1500 });
    const a = (await db.collection('requests').doc(GID).collection('applications').doc(HELPER).get()).data()!;
    assert.equal(a.est, 3000);
    assert.equal(a.spot, '문 앞');

    const { tradeId } = await core.acceptApplication(db, OWNER, { requestId: GID, helperUid: HELPER });
    assert.equal((await db.collection('requests').doc(GID).get()).get('acceptedCount'), 1);
    assert.equal((await trade(tradeId)).est, 3000);
    await rejectsWith(core.acceptApplication(db, OWNER, { requestId: GID, helperUid: OTHER }), 'failed-precondition');
    await rejectsWith(core.applyToRequest(db, 'helper-3', { requestId: GID, msg: '휴지' }), 'failed-precondition');

    await core.advanceTrade(db, HELPER, { tradeId, action: 'cancel' });
    assert.equal((await db.collection('requests').doc(GID).get()).get('acceptedCount'), 0);
    await core.acceptApplication(db, OWNER, { requestId: GID, helperUid: OTHER });
  });

  test('접수 마감·금지 품목·물건값 한도 → 거부', async () => {
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: GID, msg: '소주 2병' }), 'invalid-argument');
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: GID, msg: '우유', est: 50001 }), 'invalid-argument');
    await db.collection('requests').doc(GID).update({ closed: true });
    await rejectsWith(core.applyToRequest(db, HELPER, { requestId: GID, msg: '우유' }), 'failed-precondition');
  });
});
