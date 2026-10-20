/**
 * 부탁 댓글 (Firestore 에뮬레이터): 연락처 가리기, 댓글 수, 글쓴이·댓글 단 사람에게 알림, 차단·정지
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import { Timestamp } from 'firebase-admin/firestore';

import * as comment from '../../src/comment/core';
import { PushMessage } from '../../src/notify/deliver';
import { adminDb, clearDb, rejectsWith, seedRequest } from './helpers';

const db = adminDb();
const RID = '1760000000000';
const notes = async (uid: string) => (await db.collection('users').doc(uid).collection('notifications').get()).docs;

beforeEach(async () => {
  await clearDb();
  await seedRequest(db, RID, 'owner', { mode: 'going', title: '내일 오사카 가요' });
  await db.collection('users').doc('reader').set({ nickname: '준호' });
});

describe('부탁 댓글', () => {
  test('남이 댓글 → 가려서 저장, 댓글 수 +1, 글쓴이에게 알림', async () => {
    await db.collection('users').doc('owner').collection('fcmTokens').doc('tok').set({});
    const sent: PushMessage[] = [];
    const push = async (m: PushMessage) => {
      sent.push(m);
      return [];
    };
    const r = await comment.addComment(db, 'reader', { requestId: RID, text: '곤약젤리 부탁돼요? 010-1234-5678' }, push);
    assert.equal(r.masked, true);
    const cs = await db.collection('requests').doc(RID).collection('comments').get();
    assert.equal(cs.size, 1);
    assert.equal(cs.docs[0].get('author'), '준호');
    assert.match(cs.docs[0].get('text'), /\[전화번호 가림\]/);
    assert.equal((await db.collection('requests').doc(RID).get()).get('commentCount'), 1);
    const n = await notes('owner');
    assert.equal(n.length, 1);
    assert.equal(n[0].get('kind'), 'request.comment');
    assert.equal(n[0].get('requestId'), RID);
    assert.equal(sent.length, 1);
  });

  test('글쓴이가 답하면 댓글 단 사람들에게 알림(글쓴이 본인 제외)', async () => {
    const push = async () => [];
    await comment.addComment(db, 'reader', { requestId: RID, text: '몇 시에 출발하세요?' }, push);
    await comment.addComment(db, 'other', { requestId: RID, text: '저도 궁금해요' }, push);
    await comment.addComment(db, 'owner', { requestId: RID, text: '오전 10시요' }, push);
    assert.equal((await notes('reader')).length, 1);
    assert.equal((await notes('other')).length, 1);
    assert.equal((await notes('owner')).length, 2, '남이 단 댓글 두 개만');
  });

  test('빈 댓글·긴 댓글·없는 글·차단·정지 → 거부', async () => {
    await rejectsWith(comment.addComment(db, 'reader', { requestId: RID, text: '  ' }), 'invalid-argument');
    await rejectsWith(comment.addComment(db, 'reader', { requestId: RID, text: 'x'.repeat(301) }), 'invalid-argument');
    await rejectsWith(comment.addComment(db, 'reader', { requestId: 'nope', text: '안녕' }), 'not-found');
    await db.collection('users').doc('owner').collection('blocks').doc('reader').set({ at: Timestamp.now() });
    await rejectsWith(comment.addComment(db, 'reader', { requestId: RID, text: '안녕' }), 'permission-denied');
    await db.collection('users').doc('x').set({ suspended: true });
    await rejectsWith(comment.addComment(db, 'x', { requestId: RID, text: '안녕' }), 'permission-denied');
  });
});
