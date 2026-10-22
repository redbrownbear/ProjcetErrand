/**
 * 거래 사진(A37, Firestore 에뮬레이터): 당사자 · 경로 · 금액 확인, 사진 수 · 알림, 끝난 거래 거부
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import { Timestamp } from 'firebase-admin/firestore';

import { PushMessage } from '../../src/notify/deliver';
import * as photo from '../../src/photo/core';
import { adminDb, clearDb, rejectsWith } from './helpers';

const db = adminDb();
const TID = 'trade-1';
const push = async (_: PushMessage) => [] as string[];
const trade = async () => (await db.collection('trades').doc(TID).get()).data()!;

beforeEach(async () => {
  await clearDb();
  await db.collection('trades').doc(TID).set({
    requestId: '1760000000000',
    requesterUid: 'req',
    helperUid: 'help',
    title: '편의점 택배 찾기',
    status: 'working',
    updatedAt: Timestamp.now(),
  });
});

describe('거래 사진', () => {
  test('수행자가 영수증을 올리면 목록 · 사진 수가 늘고 요청자에게 알림', async () => {
    const r = await photo.addTradePhoto(db, 'help', { tradeId: TID, kind: 'receipt', path: `trades/${TID}/help/1.jpg`, amount: 4500 }, push);
    const p = (await db.collection('trades').doc(TID).collection('photos').doc(r.id).get()).data()!;
    assert.equal(p.kind, 'receipt');
    assert.equal(p.amount, 4500);
    assert.equal(p.role, 'helper');
    assert.equal((await trade()).photoCount, 1);
    const n = await db.collection('users').doc('req').collection('notifications').get();
    assert.equal(n.size, 1);
    assert.equal(n.docs[0].get('kind'), 'trade.photo');
    assert.match(n.docs[0].get('body'), /4,500원/);
  });

  test('요청자도 받은 물건 사진을 올린다(금액 없음)', async () => {
    await photo.addTradePhoto(db, 'req', { tradeId: TID, kind: 'proof', path: `trades/${TID}/req/a.jpg` });
    assert.equal((await trade()).photoCount, 1);
  });

  test('남 · 남의 폴더 · 금액 없는 영수증 · 끝난 거래는 거부', async () => {
    await rejectsWith(photo.addTradePhoto(db, 'other', { tradeId: TID, kind: 'proof', path: `trades/${TID}/other/a.jpg` }), 'permission-denied');
    await rejectsWith(photo.addTradePhoto(db, 'help', { tradeId: TID, kind: 'proof', path: `trades/${TID}/req/a.jpg` }), 'invalid-argument');
    await rejectsWith(photo.addTradePhoto(db, 'help', { tradeId: TID, kind: 'proof', path: `trades/${TID}/help/../req/a.jpg` }), 'invalid-argument');
    await rejectsWith(photo.addTradePhoto(db, 'help', { tradeId: TID, kind: 'receipt', path: `trades/${TID}/help/a.jpg` }), 'invalid-argument');
    await rejectsWith(photo.addTradePhoto(db, 'help', { tradeId: TID, kind: 'selfie', path: `trades/${TID}/help/a.jpg` }), 'invalid-argument');
    await db.collection('trades').doc(TID).update({ status: 'completed' });
    await rejectsWith(photo.addTradePhoto(db, 'help', { tradeId: TID, kind: 'proof', path: `trades/${TID}/help/a.jpg` }), 'failed-precondition');
  });

  test(`거래마다 ${photo.PHOTO_LIMIT}장까지`, async () => {
    await db.collection('trades').doc(TID).update({ photoCount: photo.PHOTO_LIMIT });
    await rejectsWith(photo.addTradePhoto(db, 'help', { tradeId: TID, kind: 'proof', path: `trades/${TID}/help/a.jpg` }), 'resource-exhausted');
  });
});
