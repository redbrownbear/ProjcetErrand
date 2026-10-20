/**
 * '가는 김에' 댓글 (Firestore 에뮬레이터): 다른 계정이 댓글을 남기면 연락처를 가려 저장하고, 글쓴이에게 알림함·푸시
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import { Timestamp } from 'firebase-admin/firestore';

import { PushMessage } from '../../src/notify/deliver';
import * as trip from '../../src/trip/core';
import { adminDb, clearDb, rejectsWith } from './helpers';

const db = adminDb();
const PID = '1760000000000';

beforeEach(async () => {
  await clearDb();
  await db.collection('tripPosts').doc(PID).set({
    ownerUid: 'owner',
    author: '민지',
    type: 'going',
    title: '내일 오사카 가요',
    quote: '필요한 거 있으면 말씀 주세요',
    commentCount: 0,
    createdAt: Timestamp.now(),
  });
  await db.collection('users').doc('reader').set({ nickname: '준호' });
});

describe('가는 김에 댓글', () => {
  test('다른 계정이 댓글 → 가려서 저장, 댓글 수 +1, 글쓴이에게 알림함과 푸시', async () => {
    await db.collection('users').doc('owner').collection('fcmTokens').doc('tok').set({});
    const sent: PushMessage[] = [];
    const push = async (m: PushMessage) => {
      sent.push(m);
      return [];
    };
    const r = await trip.addTripComment(db, 'reader', { postId: PID, text: '곤약젤리 부탁해요 010-1234-5678' }, push);
    assert.equal(r.masked, true);
    const cs = await db.collection('tripPosts').doc(PID).collection('comments').get();
    assert.equal(cs.size, 1);
    assert.equal(cs.docs[0].get('author'), '준호');
    assert.match(cs.docs[0].get('text'), /\[전화번호 가림\]/);
    assert.equal((await db.collection('tripPosts').doc(PID).get()).get('commentCount'), 1);
    const notes = await db.collection('users').doc('owner').collection('notifications').get();
    assert.equal(notes.size, 1);
    assert.equal(notes.docs[0].get('kind'), 'trip.comment');
    assert.equal(notes.docs[0].get('tripId'), PID);
    assert.equal(sent.length, 1);
  });

  test('내 글에 내가 댓글 → 알림 없음', async () => {
    const sent: PushMessage[] = [];
    await trip.addTripComment(db, 'owner', { postId: PID, text: '아직 자리 있어요' }, async (m) => {
      sent.push(m);
      return [];
    });
    assert.equal(sent.length, 0);
    assert.equal((await db.collection('users').doc('owner').collection('notifications').get()).size, 0);
  });

  test('빈 댓글·너무 긴 댓글·없는 글·차단·정지 → 거부', async () => {
    await rejectsWith(trip.addTripComment(db, 'reader', { postId: PID, text: '  ' }), 'invalid-argument');
    await rejectsWith(trip.addTripComment(db, 'reader', { postId: PID, text: 'x'.repeat(301) }), 'invalid-argument');
    await rejectsWith(trip.addTripComment(db, 'reader', { postId: 'nope', text: '안녕' }), 'not-found');
    await db.collection('users').doc('owner').collection('blocks').doc('reader').set({ at: Timestamp.now() });
    await rejectsWith(trip.addTripComment(db, 'reader', { postId: PID, text: '안녕' }), 'permission-denied');
    await db.collection('users').doc('x').set({ suspended: true });
    await rejectsWith(trip.addTripComment(db, 'x', { postId: PID, text: '안녕' }), 'permission-denied');
  });
});
