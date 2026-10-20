/**
 * 보안 규칙 v2 테스트 (Firestore 에뮬레이터).
 * 설계 문서 W2 검증 기준: 남의 부탁 수정, 상태 직접 변경, 지원·거래 직접 쓰기,
 * 비당사자의 상세·거래 읽기, 포인트 직접 수정을 모두 거부한다.
 */
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
} from 'firebase/firestore';

import { PROJECT } from './helpers';

let env: RulesTestEnvironment;
const OWNER = 'owner-1';
const HELPER = 'helper-1';
const STRANGER = 'stranger';
const RID = '1760000000000';

const db = (uid?: string, claims: Record<string, unknown> = {}) =>
  uid ? env.authenticatedContext(uid, claims).firestore() : env.unauthenticatedContext().firestore();

function newRequest(extra: Record<string, unknown> = {}) {
  return {
    ownerUid: OWNER,
    who: '요청자',
    mode: 'ask',
    cat: 'pickup',
    title: '편의점 택배 찾아 주세요',
    desc: '',
    price: 3000,
    status: 'open',
    deadline: Timestamp.fromMillis(Date.now() + 3_600_000),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra,
  };
}

before(async () => {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080').split(':');
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { host, port: Number(port), rules: readFileSync(resolve(__dirname, '../../../firebase/firestore.rules'), 'utf8') },
  });
});
after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    await setDoc(doc(f, 'requests', RID), { ...newRequest(), createdAt: Timestamp.now(), updatedAt: Timestamp.now(), helperUid: HELPER });
    await setDoc(doc(f, 'requests', RID, 'private', 'detail'), { place: '역삼동 GS25', lat: 37.5, lng: 127.03 });
    await setDoc(doc(f, 'requests', RID, 'applications', HELPER), { helperUid: HELPER, requesterUid: OWNER, status: 'pending' });
    await setDoc(doc(f, 'trades', 't1'), { requestId: RID, requesterUid: OWNER, helperUid: HELPER, status: 'matched' });
    await setDoc(doc(f, 'trades', 't1', 'messages', 'm1'), { senderUid: HELPER, text: '도착했어요' });
    await setDoc(doc(f, 'users', OWNER), { nickname: '요청자', points: 100 });
  });
});

describe('공개 부탁글', () => {
  test('비로그인도 목록은 읽는다', async () => {
    await assertSucceeds(getDoc(doc(db(), 'requests', RID)));
  });

  test('올바른 새 글은 만들 수 있다', async () => {
    await assertSucceeds(setDoc(doc(db(OWNER), 'requests', '2'), newRequest()));
  });

  test('정확한 위치를 공개 문서에 넣으면 거부', async () => {
    await assertFails(setDoc(doc(db(OWNER), 'requests', '2'), newRequest({ lat: 37.5, lng: 127.0 })));
    await assertFails(setDoc(doc(db(OWNER), 'requests', '3'), newRequest({ place: '역삼동 GS25' })));
  });

  test('남의 이름 · open이 아닌 상태 · 지원자 수 임의 지정 · 잘못된 금액 → 거부', async () => {
    await assertFails(setDoc(doc(db(STRANGER), 'requests', '2'), newRequest()));
    await assertFails(setDoc(doc(db(OWNER), 'requests', '2'), newRequest({ status: 'matched' })));
    await assertFails(setDoc(doc(db(OWNER), 'requests', '2'), newRequest({ applicantCount: 5 })));
    await assertFails(setDoc(doc(db(OWNER), 'requests', '2'), newRequest({ price: -100 })));
    await assertFails(setDoc(doc(db(OWNER), 'requests', '2'), newRequest({ createdAt: Timestamp.fromMillis(0) })));
  });

  test('글쓴이는 모집 중 내용만 고칠 수 있고, 상태·지원자 수는 못 바꾼다', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'requests', RID), { status: 'open' });
    });
    await assertSucceeds(updateDoc(doc(db(OWNER), 'requests', RID), { title: '택배 2개', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db(OWNER), 'requests', RID), { status: 'done', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db(OWNER), 'requests', RID), { applicantCount: 0, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db(STRANGER), 'requests', RID), { title: '남의 글', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(db(OWNER), 'requests', RID)));
  });

  test('매칭된 뒤에는 글쓴이도 내용 수정 불가', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'requests', RID), { status: 'matched' });
    });
    await assertFails(updateDoc(doc(db(OWNER), 'requests', RID), { title: '바꿈', updatedAt: serverTimestamp() }));
  });
});

describe('정확한 위치 (private/detail)', () => {
  test('글쓴이와 수락된 수행자만 읽는다', async () => {
    await assertSucceeds(getDoc(doc(db(OWNER), 'requests', RID, 'private', 'detail')));
    await assertSucceeds(getDoc(doc(db(HELPER), 'requests', RID, 'private', 'detail')));
    await assertFails(getDoc(doc(db(STRANGER), 'requests', RID, 'private', 'detail')));
    await assertFails(getDoc(doc(db(), 'requests', RID, 'private', 'detail')));
  });

  test('글쓴이만, 정해진 필드만 쓴다', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'requests', RID), { status: 'open' });
    });
    await assertSucceeds(setDoc(doc(db(OWNER), 'requests', RID, 'private', 'detail'), { place: '역삼역 2번 출구' }));
    await assertFails(setDoc(doc(db(OWNER), 'requests', RID, 'private', 'detail'), { phone: '010' }));
    await assertFails(setDoc(doc(db(HELPER), 'requests', RID, 'private', 'detail'), { place: 'x' }));
  });
});

describe('지원서 · 거래 — 서버만 쓴다', () => {
  test('지원서는 지원자와 글쓴이만 읽고, 아무도 직접 쓰지 못한다', async () => {
    await assertSucceeds(getDoc(doc(db(HELPER), 'requests', RID, 'applications', HELPER)));
    await assertSucceeds(getDoc(doc(db(OWNER), 'requests', RID, 'applications', HELPER)));
    await assertFails(getDoc(doc(db(STRANGER), 'requests', RID, 'applications', HELPER)));
    await assertFails(setDoc(doc(db(STRANGER), 'requests', RID, 'applications', STRANGER), { helperUid: STRANGER, status: 'pending' }));
    await assertFails(updateDoc(doc(db(OWNER), 'requests', RID, 'applications', HELPER), { status: 'accepted' }));
  });

  test('내 지원(지원자) · 받은 지원(요청자) 목록은 조회되고, 남의 것은 조회 불가', async () => {
    await assertSucceeds(getDocs(query(collectionGroup(db(HELPER), 'applications'), where('helperUid', '==', HELPER))));
    await assertSucceeds(getDocs(query(collectionGroup(db(OWNER), 'applications'), where('requesterUid', '==', OWNER))));
    await assertFails(getDocs(query(collectionGroup(db(STRANGER), 'applications'), where('requesterUid', '==', OWNER))));
  });

  test('채팅은 당사자만 읽고, 앱은 직접 쓰지 못한다(서버가 연락처를 가린 뒤 쓴다)', async () => {
    await assertSucceeds(getDoc(doc(db(OWNER), 'trades', 't1', 'messages', 'm1')));
    await assertSucceeds(getDoc(doc(db(HELPER), 'trades', 't1', 'messages', 'm1')));
    await assertFails(getDoc(doc(db(STRANGER), 'trades', 't1', 'messages', 'm1')));
    await assertFails(setDoc(doc(db(HELPER), 'trades', 't1', 'messages', 'm2'), { senderUid: HELPER, text: '010-1234-5678' }));
  });

  test('거래는 당사자만 읽고, 아무도 직접 쓰지 못한다', async () => {
    await assertSucceeds(getDoc(doc(db(OWNER), 'trades', 't1')));
    await assertSucceeds(getDoc(doc(db(HELPER), 'trades', 't1')));
    await assertFails(getDoc(doc(db(STRANGER), 'trades', 't1')));
    await assertFails(updateDoc(doc(db(HELPER), 'trades', 't1'), { status: 'completed' }));
    await assertFails(setDoc(doc(db(OWNER), 'trades', 't2'), { requesterUid: OWNER, helperUid: HELPER, status: 'completed' }));
  });
});

describe('사용자 문서', () => {
  test('프로필은 고치되 포인트·인증·역할·정지는 못 고친다', async () => {
    await assertSucceeds(updateDoc(doc(db(OWNER), 'users', OWNER), { nickname: '새 이름' }));
    await assertFails(updateDoc(doc(db(OWNER), 'users', OWNER), { points: 99999 }));
    await assertFails(updateDoc(doc(db(OWNER), 'users', OWNER), { verified: true }));
    await assertFails(updateDoc(doc(db(OWNER), 'users', OWNER), { role: 'admin' }));
    await assertFails(setDoc(doc(db(HELPER), 'users', HELPER), { nickname: 'x', suspended: false }));
    await assertFails(getDoc(doc(db(STRANGER), 'users', OWNER)));
  });

  test('포인트 원장 · 알림 생성 · 프로토타입 기록은 앱이 쓰지 못한다', async () => {
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'pointLedger', 'x'), { amount: 100 }));
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'notifications', 'n'), { title: '가짜' }));
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'trades', RID), { status: 'completed' }));
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'payEntries', '1'), { amount: 100 }));
  });

  test('차단·관심·토큰은 본인이 쓴다, 자기 자신 차단은 불가', async () => {
    await assertSucceeds(setDoc(doc(db(OWNER), 'users', OWNER, 'blocks', HELPER), { at: serverTimestamp() }));
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'blocks', OWNER), { at: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(db(OWNER), 'users', OWNER, 'bookmarks', RID), { createdAt: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(db(OWNER), 'users', OWNER, 'fcmTokens', 'tok'), { platform: 'android' }));
    await assertFails(setDoc(doc(db(STRANGER), 'users', OWNER, 'blocks', HELPER), { at: serverTimestamp() }));
  });
});

describe('신고', () => {
  const report = (uid: string, extra: Record<string, unknown> = {}) => ({
    reporterUid: uid,
    targetUid: HELPER,
    requestId: RID,
    reason: '노쇼',
    createdAt: serverTimestamp(),
    ...extra,
  });

  test('본인 이름으로만 신고, 운영자만 읽는다', async () => {
    await assertSucceeds(setDoc(doc(db(OWNER), 'reports', 'r1'), report(OWNER)));
    await assertFails(setDoc(doc(db(OWNER), 'reports', 'r2'), report(STRANGER)));
    await assertFails(setDoc(doc(db(OWNER), 'reports', 'r3'), report(OWNER, { status: 'resolved' })));
    await assertFails(getDoc(doc(db(OWNER), 'reports', 'r1')));
    await assertSucceeds(getDoc(doc(db('ops', { role: 'admin' }), 'reports', 'r1')));
  });
});

describe('가는 김에', () => {
  const post = (uid: string, extra: Record<string, unknown> = {}) => ({
    ownerUid: uid,
    author: '민지',
    area: '반포동',
    type: 'going',
    where: '오사카',
    title: '오사카 가요',
    when: '내일',
    quote: '필요한 거 있으면 댓글 주세요',
    commentCount: 0,
    createdAt: serverTimestamp(),
    ...extra,
  });

  test('본인 이름으로만 올리고, 누구나 읽고, 댓글 수·댓글은 앱이 못 쓴다', async () => {
    await assertSucceeds(setDoc(doc(db(OWNER), 'tripPosts', 'p1'), post(OWNER)));
    await assertFails(setDoc(doc(db(OWNER), 'tripPosts', 'p2'), post(STRANGER)));
    await assertFails(setDoc(doc(db(OWNER), 'tripPosts', 'p3'), post(OWNER, { commentCount: 5 })));
    await assertFails(setDoc(doc(db(OWNER), 'tripPosts', 'p4'), post(OWNER, { lat: 37.5 })));
    await assertFails(setDoc(doc(db(), 'tripPosts', 'p5'), post(OWNER)));
    await assertSucceeds(getDoc(doc(db(), 'tripPosts', 'p1')));
    await assertFails(updateDoc(doc(db(OWNER), 'tripPosts', 'p1'), { commentCount: 3 }));
    await assertFails(setDoc(doc(db(STRANGER), 'tripPosts', 'p1', 'comments', 'c1'), { uid: STRANGER, text: '안녕' }));
    await assertFails(deleteDoc(doc(db(STRANGER), 'tripPosts', 'p1')));
    await assertSucceeds(deleteDoc(doc(db(OWNER), 'tripPosts', 'p1')));
  });
});
