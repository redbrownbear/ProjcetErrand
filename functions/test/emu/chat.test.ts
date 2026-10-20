/**
 * 최소 채팅 (Firestore 에뮬레이터): 당사자만, 연락처 가리기, 취소된 거래 차단, 상대에게 푸시·안 읽음 수
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import * as chat from '../../src/chat/core';
import * as core from '../../src/errand/core';
import { PushMessage } from '../../src/notify/deliver';
import { adminDb, clearDb, rejectsWith, seedRequest } from './helpers';

const db = adminDb();
let tradeId = '';

beforeEach(async () => {
  await clearDb();
  await seedRequest(db, '1', 'owner');
  await core.applyToRequest(db, 'helper', { requestId: '1' });
  ({ tradeId } = await core.acceptApplication(db, 'owner', { requestId: '1', helperUid: 'helper' }));
});

describe('채팅', () => {
  test('당사자는 보내고, 연락처는 가려서 저장, 상대에게 푸시와 안 읽음 수', async () => {
    await db.collection('users').doc('owner').collection('fcmTokens').doc('tok').set({});
    const sent: PushMessage[] = [];
    const push = async (msg: PushMessage) => {
      sent.push(msg);
      return [];
    };
    const r = await chat.sendMessage(db, 'helper', { tradeId, text: '도착하면 010-1234-5678로 전화 주세요' }, push);
    assert.equal(r.masked, true);
    const msgs = await db.collection('trades').doc(tradeId).collection('messages').get();
    assert.equal(msgs.size, 1);
    assert.match(msgs.docs[0].get('text'), /\[전화번호 가림\]/);
    assert.equal(msgs.docs[0].get('senderUid'), 'helper');
    assert.equal(sent.length, 1);
    assert.deepEqual(sent[0].tokens, ['tok']);

    const t = (await db.collection('trades').doc(tradeId).get()).data()!;
    assert.equal(t.unread.owner, 1);
    assert.equal(t.status, 'matched', '채팅은 거래 단계를 바꾸지 않는다');
    // 채팅은 알림함에 쌓지 않는다
    assert.equal((await db.collection('users').doc('owner').collection('notifications').get()).size, 0);

    await chat.markChatRead(db, 'owner', { tradeId });
    assert.equal((await db.collection('trades').doc(tradeId).get()).get('unread.owner'), 0);
  });

  test('제3자·빈 메시지·너무 긴 메시지·취소된 거래 → 거부', async () => {
    await rejectsWith(chat.sendMessage(db, 'stranger', { tradeId, text: '안녕' }), 'permission-denied');
    await rejectsWith(chat.sendMessage(db, 'owner', { tradeId, text: '   ' }), 'invalid-argument');
    await rejectsWith(chat.sendMessage(db, 'owner', { tradeId, text: 'x'.repeat(1001) }), 'invalid-argument');
    await rejectsWith(chat.markChatRead(db, 'stranger', { tradeId }), 'permission-denied');
    await core.advanceTrade(db, 'helper', { tradeId, action: 'cancel' });
    await rejectsWith(chat.sendMessage(db, 'owner', { tradeId, text: '왜 취소하셨어요?' }), 'failed-precondition');
  });
});
