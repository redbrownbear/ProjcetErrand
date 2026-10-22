/**
 * 알림 전달(W4)·운영자 작업(W5) 테스트 (Firestore 에뮬레이터). FCM은 가짜 전송기로 대신한다.
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import { Timestamp } from 'firebase-admin/firestore';

import * as admin from '../../src/admin/core';
import { triageReport } from '../../src/admin/triage';
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

  test('신고 처리 알림: 경고는 대상에게, 처리됨은 신고자에게 한 번만', async () => {
    await db.collection('reports').doc('rw').set({ reporterUid: 'a', targetUid: 'b', requestId: '7', reason: '욕설', createdAt: Timestamp.now() });
    const sent: PushMessage[] = [];
    const send = async (m: PushMessage) => {
      sent.push(m);
      return [];
    };
    await admin.resolveReport(db, 'ops', { reportId: 'rw', resolution: 'warned' }, send);
    await admin.resolveReport(db, 'ops', { reportId: 'rw', resolution: 'warned' }, send);
    const nb = await db.collection('users').doc('b').collection('notifications').get();
    assert.deepEqual(nb.docs.map((d) => d.get('kind')), ['report.warned']);
    assert.equal(nb.docs[0].get('requestId'), '7');
    const na = await db.collection('users').doc('a').collection('notifications').get();
    assert.deepEqual(na.docs.map((d) => d.get('kind')), ['report.resolved']);
    assert.equal((await db.collection('users').doc('b').get()).get('suspended'), undefined);
  });

  test('운영자 글 내리기 · 되돌리기, 금지 품목으로 내려간 글은 못 되돌린다', async () => {
    await seedRequest(db, '9', 'owner');
    const send = async () => [];
    const r1 = await admin.setRequestHidden(db, 'ops', { requestId: '9', hidden: true, reason: '사기 의심' }, send);
    assert.equal(r1.changed, true);
    let doc = (await db.collection('requests').doc('9').get()).data()!;
    assert.equal(doc.status, 'hidden');
    assert.equal(doc.hiddenBy, 'admin');
    assert.equal(doc.hiddenReason, '사기 의심');
    assert.equal((await admin.setRequestHidden(db, 'ops', { requestId: '9', hidden: true })).changed, false);
    const n = await db.collection('users').doc('owner').collection('notifications').get();
    assert.deepEqual(n.docs.map((d) => d.get('kind')), ['request.hidden']);

    await admin.setRequestHidden(db, 'ops', { requestId: '9', hidden: false });
    doc = (await db.collection('requests').doc('9').get()).data()!;
    assert.equal(doc.status, 'open');
    assert.equal(doc.hiddenBy, null);

    await db.collection('requests').doc('9').update({ status: 'hidden', hiddenReason: '금지 품목' });
    await rejectsWith(admin.setRequestHidden(db, 'ops', { requestId: '9', hidden: false }), 'failed-precondition');
    await rejectsWith(admin.setRequestHidden(db, 'ops', { requestId: 'none', hidden: true }), 'not-found');
    await rejectsWith(admin.setRequestHidden(db, 'ops', { requestId: '9' }), 'invalid-argument');
  });
});

describe('신고 자동 분류 · 1차 안내(A34)', () => {
  const send = async () => [];
  const report = (id: string, reporter: string, extra: Record<string, unknown> = {}) =>
    db.collection('reports').doc(id).set({ reporterUid: reporter, targetUid: 'bad', reason: '노쇼·약속 불이행', createdAt: Timestamp.now(), ...extra });

  test('분류를 붙이고 신고자에게 한 번만 안내, 같은 사람에게 몰리면 high', async () => {
    await report('r1', 'a');
    const t = await triageReport(db, 'r1', send);
    assert.equal(t?.category, 'noshow');
    assert.equal(t?.priority, 'normal');
    assert.equal(await triageReport(db, 'r1', send), null); // 두 번 돌아도 한 번
    const n = await db.collection('users').doc('a').collection('notifications').get();
    assert.deepEqual(n.docs.map((d) => d.get('kind')), ['report.received']);

    await report('r2', 'b');
    await report('r3', 'a'); // 같은 사람이 또 신고해도 한 명
    await report('old', 'z', { createdAt: Timestamp.fromMillis(Date.now() - 10 * 86_400_000) });
    await report('r4', 'c');
    const t4 = await triageReport(db, 'r4', send);
    assert.equal(t4?.repeatCount, 3);
    assert.equal(t4?.priority, 'high');
    const doc = (await db.collection('reports').doc('r4').get()).data()!;
    assert.equal(doc.category, 'noshow');
    assert.ok(doc.triagedAt);
  });

  test('내용의 금지 품목 · 위험한 말', async () => {
    await report('p1', 'a', { reason: '기타', detail: '담배 사다 달래요' });
    assert.equal((await triageReport(db, 'p1', send))?.category, 'prohibited');
    await report('p2', 'b', { reason: '욕설·위협·불쾌한 행동', detail: '때리겠다고 했어요' });
    assert.equal((await triageReport(db, 'p2', send))?.priority, 'urgent');
  });
});
