/**
 * 알림 전달(W4)·운영자 작업(W5) 테스트 (Firestore 에뮬레이터). FCM은 가짜 전송기로 대신한다.
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import { Timestamp } from 'firebase-admin/firestore';

import * as admin from '../../src/admin/core';
import * as core from '../../src/errand/core';
import { deliver, PushMessage } from '../../src/notify/deliver';
import { adminDb, clearDb, rejectsWith, seedRequest } from './helpers';

const db = adminDb();

beforeEach(clearDb);

describe('알림 전달', () => {
  const ev = { to: 'r', kind: 'application.new' as const, title: '새 지원이 왔어요', body: 'b', requestId: '1' };

  test('알림함에 기록하고 토큰으로 보낸다, 같은 이벤트는 한 번만', async () => {
    await db.collection('users').doc('r').collection('fcmTokens').doc('tok-a').set({ platform: 'android' });
    const sent: PushMessage[] = [];
    const send = async (m: PushMessage) => {
      sent.push(m);
      return [];
    };
    assert.equal(await deliver(db, send, ev, 'e1'), true);
    assert.equal(await deliver(db, send, ev, 'e1'), false);
    assert.equal(sent.length, 1);
    assert.deepEqual(sent[0].tokens, ['tok-a']);
    const n = await db.collection('users').doc('r').collection('notifications').get();
    assert.equal(n.size, 1);
    assert.equal(n.docs[0].get('readAt'), null);
  });

  test('만료된 토큰은 지운다, 토큰이 없어도 알림함엔 남는다', async () => {
    const tokens = db.collection('users').doc('r').collection('fcmTokens');
    await tokens.doc('good').set({});
    await tokens.doc('dead').set({});
    await deliver(db, async () => ['dead'], ev, 'e2');
    assert.deepEqual((await tokens.get()).docs.map((d) => d.id), ['good']);

    await deliver(db, async () => assert.fail('토큰이 없으면 보내지 않는다'), { ...ev, to: 'nobody' }, 'e3');
    assert.equal((await db.collection('users').doc('nobody').collection('notifications').get()).size, 1);
  });
});

describe('운영자', () => {
  test('운영자만, 정지하면 지원이 막힌다', async () => {
    assert.throws(() => admin.assertAdmin({}), { code: 'permission-denied' });
    admin.assertAdmin({ role: 'admin' });

    await seedRequest(db, '1', 'owner');
    await admin.setSuspended(db, 'ops', { uid: 'h', suspended: true, reason: '노쇼 반복' });
    await rejectsWith(core.applyToRequest(db, 'h', { requestId: '1' }), 'permission-denied');
    await admin.setSuspended(db, 'ops', { uid: 'h', suspended: false });
    await core.applyToRequest(db, 'h', { requestId: '1' });
    assert.equal((await db.collection('adminLog').get()).size, 2);
  });

  test('신고 처리: suspended면 대상 정지', async () => {
    await db.collection('reports').doc('rp').set({ reporterUid: 'a', targetUid: 'b', reason: '노쇼', createdAt: Timestamp.now() });
    await admin.resolveReport(db, 'ops', { reportId: 'rp', resolution: 'suspended', memo: '확인' });
    const rp = (await db.collection('reports').doc('rp').get()).data()!;
    assert.equal(rp.status, 'resolved');
    assert.equal((await db.collection('users').doc('b').get()).get('suspended'), true);
    await rejectsWith(admin.resolveReport(db, 'ops', { reportId: 'rp', resolution: 'ban' }), 'invalid-argument');
    await rejectsWith(admin.resolveReport(db, 'ops', { reportId: 'none', resolution: 'dismissed' }), 'not-found');
  });
});
