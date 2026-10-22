/**
 * 금지 품목 · 물건값 상한 (Firestore 에뮬레이터): 글 숨김과 알림, 설정 문서로 바꾸기, 댓글 · 가는 김에 신청 거부
 */
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import * as comment from '../../src/comment/core';
import * as core from '../../src/errand/core';
import { PushMessage } from '../../src/notify/deliver';
import { resetPolicyCache } from '../../src/safety/policy';
import { screenRequest } from '../../src/safety/screen';
import { adminDb, clearDb, rejectsWith, seedRequest } from './helpers';

const db = adminDb();
const RID = '1760000000001';
const push = async (_: PushMessage) => [] as string[];
const req = async () => (await db.collection('requests').doc(RID).get()).data()!;

beforeEach(async () => {
  await clearDb();
  resetPolicyCache();
  await db.collection('users').doc('reader').set({ nickname: '준호' });
});

describe('부탁 글 검사', () => {
  test('금지어가 있으면 글을 숨기고 글쓴이에게 알린다(한 번만)', async () => {
    await seedRequest(db, RID, 'owner', { title: '편의점 담배 한 갑' });
    const after = await req();
    const reason = await screenRequest(db, RID, undefined, after, push);
    assert.match(reason ?? '', /담배/);
    const d = await req();
    assert.equal(d.status, 'hidden');
    assert.match(d.hiddenReason, /담배/);
    const n = await db.collection('users').doc('owner').collection('notifications').get();
    assert.equal(n.size, 1);
    assert.equal(n.docs[0].get('kind'), 'request.hidden');
    // 숨긴 뒤 다시 불려도(트리거 재전달) 아무것도 하지 않는다
    assert.equal(await screenRequest(db, RID, after, d, push), null);
  });

  test('문제없는 글 · 바뀐 칸이 없는 수정은 그대로 둔다', async () => {
    await seedRequest(db, RID, 'owner', { title: '편의점 택배 찾기', budget: 10_000 });
    const d = await req();
    assert.equal(await screenRequest(db, RID, undefined, d, push), null);
    assert.equal(await screenRequest(db, RID, d, { ...d, applicantCount: 1 }, push), null);
    assert.equal((await req()).status, 'open');
  });

  test('config/safety로 금지어 · 상한을 바꾼다', async () => {
    await db.collection('config').doc('safety').set({ blockedWords: ['곤약젤리'], maxItemPrice: 20_000 });
    await seedRequest(db, RID, 'owner', { title: '소주 말고 곤약젤리', budget: 10_000 });
    assert.match((await screenRequest(db, RID, undefined, await req(), push)) ?? '', /곤약젤리/);
    resetPolicyCache();
    await seedRequest(db, '1760000000002', 'owner', { title: '휴지', budget: 30_000 });
    const d2 = (await db.collection('requests').doc('1760000000002').get()).data()!;
    assert.match((await screenRequest(db, '1760000000002', undefined, d2, push)) ?? '', /20,000원/);
  });
});

describe('댓글 · 가는 김에 신청', () => {
  test('금지어 댓글은 거부한다', async () => {
    await seedRequest(db, RID, 'owner', { mode: 'going', title: '이마트 가요' });
    await rejectsWith(comment.addComment(db, 'reader', { requestId: RID, text: '맥주 6캔 부탁돼요?' }), 'invalid-argument');
    await comment.addComment(db, 'reader', { requestId: RID, text: '휴지 부탁돼요?' });
  });

  test('가는 김에 신청: 금지어 · 물건값 상한', async () => {
    await seedRequest(db, RID, 'owner', { mode: 'going', title: '이마트 가요', capacity: 3, acceptedCount: 0 });
    await rejectsWith(core.applyToRequest(db, 'reader', { requestId: RID, msg: '타이레놀 한 통' }), 'invalid-argument');
    await rejectsWith(core.applyToRequest(db, 'reader', { requestId: RID, msg: '라면 박스', est: 60_000 }), 'invalid-argument');
    await core.applyToRequest(db, 'reader', { requestId: RID, msg: '라면 박스', est: 20_000 });
  });
});
