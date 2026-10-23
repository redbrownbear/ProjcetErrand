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
  collection,
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
    await setDoc(doc(f, 'trades', 't1', 'photos', 'p1'), { uid: HELPER, kind: 'receipt', amount: 4500, path: `trades/t1/${HELPER}/a.jpg` });
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
    await assertFails(updateDoc(doc(db(OWNER), 'users', OWNER), { attend: { last: '2026-10-23', streak: 6 } }));
    await assertFails(updateDoc(doc(db(OWNER), 'users', OWNER), { pointsOpenedAt: null }));
    await assertFails(setDoc(doc(db(HELPER), 'users', HELPER), { nickname: 'x', suspended: false }));
    await assertFails(getDoc(doc(db(STRANGER), 'users', OWNER)));
  });

  test('포인트 원장 · 알림 생성 · 프로토타입 기록은 앱이 쓰지 못한다', async () => {
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'pointLedger', 'x'), { amount: 100 }));
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'coupons', '1'), { name: '공짜 쿠폰', used: false }));
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'notifications', 'n'), { title: '가짜' }));
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'trades', RID), { status: 'completed' }));
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'payEntries', '1'), { amount: 100 }));
  });

  test('가입 때 프로필은 포인트·인증 없이 만들고, 동의는 함께 저장한다', async () => {
    const NEW = 'newbie';
    await assertSucceeds(
      setDoc(doc(db(NEW), 'users', NEW), {
        email: 'n@x.com',
        nickname: '새내기',
        consents: { terms: { on: true, v: '2026-10-22', at: serverTimestamp() } },
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(setDoc(doc(db('other'), 'users', 'other'), { nickname: 'x', points: 0, verified: false }));
  });

  test('동의 기록은 본인이 서버 시각으로 추가만 한다', async () => {
    const log = (uid: string) => doc(collection(db(uid), 'users', OWNER, 'consentLog'));
    await assertSucceeds(setDoc(log(OWNER), { key: 'marketing', on: true, v: '2026-10-22', at: serverTimestamp() }));
    await assertFails(setDoc(log(OWNER), { key: 'marketing', on: true, v: '2026-10-22', at: new Date(0) }));
    await assertFails(setDoc(log(OWNER), { key: 'points', on: true, v: '2026-10-22', at: serverTimestamp() }));
    await assertFails(setDoc(log(OWNER), { key: 'marketing', on: 'yes', v: '2026-10-22', at: serverTimestamp() }));
    await assertFails(setDoc(log(STRANGER), { key: 'marketing', on: true, v: '2026-10-22', at: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(db(OWNER), 'users', OWNER, 'consentLog', 'fixed'), { key: 'night', on: false, v: '1', at: serverTimestamp() }));
    await assertFails(updateDoc(doc(db(OWNER), 'users', OWNER, 'consentLog', 'fixed'), { on: true }));
    await assertFails(deleteDoc(doc(db(OWNER), 'users', OWNER, 'consentLog', 'fixed')));
  });

  test('차단·관심·토큰은 본인이 쓴다, 자기 자신 차단은 불가', async () => {
    await assertSucceeds(setDoc(doc(db(OWNER), 'users', OWNER, 'blocks', HELPER), { at: serverTimestamp() }));
    await assertFails(setDoc(doc(db(OWNER), 'users', OWNER, 'blocks', OWNER), { at: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(db(OWNER), 'users', OWNER, 'bookmarks', RID), { createdAt: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(db(OWNER), 'users', OWNER, 'fcmTokens', 'tok'), { platform: 'android' }));
    await assertFails(setDoc(doc(db(STRANGER), 'users', OWNER, 'blocks', HELPER), { at: serverTimestamp() }));
  });
});

describe('거래 사진', () => {
  test('당사자만 읽고, 아무도 직접 쓰지 못한다', async () => {
    await assertSucceeds(getDoc(doc(db(OWNER), 'trades', 't1', 'photos', 'p1')));
    await assertSucceeds(getDoc(doc(db(HELPER), 'trades', 't1', 'photos', 'p1')));
    await assertFails(getDoc(doc(db(STRANGER), 'trades', 't1', 'photos', 'p1')));
    await assertFails(setDoc(doc(db(HELPER), 'trades', 't1', 'photos', 'p2'), { uid: HELPER, kind: 'proof', path: 'x' }));
  });
});

describe('정기 동선', () => {
  const route = (extra: Record<string, unknown> = {}) => ({
    name: '출근',
    from: { label: '방배역', area: '방배동', cell6: 'wydm9q' },
    to: { label: '강남역', area: '역삼동', cell6: 'wydm9x' },
    days: [1, 2, 3, 4, 5],
    window: { start: '08:00', end: '09:00' },
    mode: 'transit',
    radiusM: 500,
    active: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra,
  });
  const ref = (uid: string, id = 'r1') => doc(db(uid), 'users', OWNER, 'routes', id);

  test('본인만 격자 · 요일 · 시간대로 저장한다', async () => {
    await assertSucceeds(setDoc(ref(OWNER), route()));
    await assertSucceeds(getDoc(ref(OWNER)));
    await assertFails(getDoc(ref(STRANGER)));
    await assertFails(setDoc(ref(STRANGER, 'r2'), route()));
  });

  test('정확한 좌표 · 서버 격자 · 이상한 값은 거부', async () => {
    await assertFails(setDoc(ref(OWNER, 'a'), route({ from: { label: '집', cell6: 'wydm9q', lat: 37.48, lng: 126.99 } })));
    await assertFails(setDoc(ref(OWNER, 'b'), route({ cells: ['wydm9q'] })));
    await assertFails(setDoc(ref(OWNER, 'c'), route({ window: { start: '25:00', end: '09:00' } })));
    await assertFails(setDoc(ref(OWNER, 'd'), route({ radiusM: 50 })));
    await assertFails(setDoc(ref(OWNER, 'e'), route({ mode: 'plane' })));
    await assertFails(setDoc(ref(OWNER, 'f'), route({ to: { label: '강남역', cell6: 'WYDM9X' } })));
    await assertSucceeds(setDoc(ref(OWNER, 'g'), route()));
    await assertFails(updateDoc(ref(OWNER, 'g'), { cells: ['x'] }));
    await assertSucceeds(updateDoc(ref(OWNER, 'g'), { active: false, updatedAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(ref(OWNER, 'g')));
  });
});

describe('여행 · 출국 일정', () => {
  const travel = (extra: Record<string, unknown> = {}) => ({
    cc: 'jp',
    city: '오사카',
    depart: '2026-11-03',
    back: '2026-11-07',
    takeAsks: true,
    note: '',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra,
  });
  const ref = (uid: string, id = 't1') => doc(db(uid), 'users', OWNER, 'travels', id);

  test('본인만 읽고 쓴다', async () => {
    await assertSucceeds(setDoc(ref(OWNER), travel()));
    await assertSucceeds(getDoc(ref(OWNER)));
    await assertFails(getDoc(ref(STRANGER)));
    await assertFails(setDoc(ref(STRANGER, 't2'), travel()));
    await assertSucceeds(updateDoc(ref(OWNER), { back: '2026-11-08', updatedAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(ref(OWNER)));
  });

  test('귀국이 출국보다 이르거나 · 날짜 모양 · 나라 코드 · 모르는 칸은 거부', async () => {
    await assertFails(setDoc(ref(OWNER, 'a'), travel({ back: '2026-11-01' })));
    await assertFails(setDoc(ref(OWNER, 'b'), travel({ depart: '2026-13-01', back: '2026-13-05' })));
    await assertFails(setDoc(ref(OWNER, 'c'), travel({ cc: 'JPN' })));
    await assertFails(setDoc(ref(OWNER, 'd'), travel({ flight: 'KE123' })));
    await assertFails(setDoc(ref(OWNER, 'e'), travel({ takeAsks: 'yes' })));
    await assertSucceeds(setDoc(ref(OWNER, 'f'), travel({ depart: '2026-11-03', back: '2026-11-03' })));
  });
});

describe('공지', () => {
  test('누구나 읽고, 앱은 운영자라도 못 쓴다', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'notices', 'n1'), { title: '점검 안내', body: '...', kind: 'notice', publishedAt: Timestamp.now() });
    });
    await assertSucceeds(getDoc(doc(db(), 'notices', 'n1')));
    await assertFails(setDoc(doc(db(OWNER, { role: 'admin' }), 'notices', 'n2'), { title: 'x' }));
  });
});

describe('공개 완료 기록', () => {
  test('누구나 읽고, 앱은 못 쓴다', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'activity', 't1'), { kind: 'done', cat: 'pickup', area: '방배동', at: Timestamp.now() });
    });
    await assertSucceeds(getDoc(doc(db(), 'activity', 't1')));
    await assertFails(setDoc(doc(db(OWNER), 'activity', 't2'), { kind: 'done' }));
  });
});

describe('운영 설정', () => {
  test('로그인한 사람은 읽고, 아무도 앱에서 고치지 못한다', async () => {
    await assertSucceeds(getDoc(doc(db(OWNER), 'config', 'safety')));
    await assertFails(getDoc(doc(db(), 'config', 'safety')));
    await assertFails(setDoc(doc(db(OWNER), 'config', 'safety'), { blockedWords: [] }));
    await assertFails(setDoc(doc(db(OWNER, { role: 'admin' }), 'config', 'safety'), { blockedWords: [] }));
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

describe('가는 김에 · 댓글', () => {
  test('제가 가요(going)·가는 분 찾아요(extra: trip) 글을 올리고, 댓글·댓글 수는 앱이 못 쓴다', async () => {
    await assertSucceeds(setDoc(doc(db(OWNER), 'requests', '1760000000009'), newRequest({ mode: 'going', title: '내일 오사카 가요' })));
    await assertSucceeds(setDoc(doc(db(OWNER), 'requests', '1760000000010'), newRequest({ extra: 'trip' })));
    await assertFails(setDoc(doc(db(OWNER), 'requests', '1760000000011'), newRequest({ mode: 'teleport' })));
    await assertFails(setDoc(doc(db(OWNER), 'requests', '1760000000012'), newRequest({ extra: 'hack' })));
    await assertFails(setDoc(doc(db(OWNER), 'requests', '1760000000013'), newRequest({ commentCount: 3 })));
    // 가는 김에 일정: 가는 시각·정원·종류·핀은 going 글에만, 정원 1~5
    await assertSucceeds(
      setDoc(doc(db(OWNER), 'requests', '1760000000014'), newRequest({ mode: 'going', goAt: Timestamp.now(), capacity: 3, kinds: ['사다주기'], pinLat: 37.48, pinLng: 127.03 })),
    );
    await assertFails(setDoc(doc(db(OWNER), 'requests', '1760000000015'), newRequest({ pinLat: 37.48, pinLng: 127.03 })));
    await assertFails(setDoc(doc(db(OWNER), 'requests', '1760000000016'), newRequest({ mode: 'going', capacity: 9 })));
    await assertFails(setDoc(doc(db(OWNER), 'requests', '1760000000017'), newRequest({ mode: 'going', acceptedCount: 3 })));
    // 글쓴이는 접수 마감을 켜고 끌 수 있다
    await assertSucceeds(updateDoc(doc(db(OWNER), 'requests', '1760000000014'), { closed: true, updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db(STRANGER), 'requests', RID, 'comments', 'c1'), { uid: STRANGER, text: '안녕' }));
    await assertSucceeds(getDoc(doc(db(), 'requests', RID, 'comments', 'c1')));
  });
});

describe('제안하기', () => {
  test('누구나 읽고 앱은 못 쓴다, 신청은 본인과 제안자만 읽는다', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const f = ctx.firestore();
      await setDoc(doc(f, 'proposals', '9'), { ownerUid: OWNER, item: '갓김치', status: 'open' });
      await setDoc(doc(f, 'proposals', '9', 'joins', HELPER), { uid: HELPER, proposalId: '9', status: 'joined' });
    });
    await assertSucceeds(getDoc(doc(db(), 'proposals', '9')));
    await assertFails(setDoc(doc(db(OWNER), 'proposals', '10'), { ownerUid: OWNER, item: 'x' }));
    await assertFails(updateDoc(doc(db(OWNER), 'proposals', '9'), { joinedCount: 3 }));
    await assertFails(setDoc(doc(db(STRANGER), 'proposals', '9', 'joins', STRANGER), { uid: STRANGER, status: 'joined' }));
    await assertSucceeds(getDoc(doc(db(HELPER), 'proposals', '9', 'joins', HELPER)));
    await assertSucceeds(getDocs(collection(db(OWNER), 'proposals', '9', 'joins')));
    await assertFails(getDoc(doc(db(STRANGER), 'proposals', '9', 'joins', HELPER)));
    await assertSucceeds(getDocs(query(collectionGroup(db(HELPER), 'joins'), where('uid', '==', HELPER))));
    await assertFails(getDocs(query(collectionGroup(db(STRANGER), 'joins'), where('uid', '==', HELPER))));
  });

  test('따로 부탁은 부탁한 본인과 제안자만 읽고, 앱은 못 쓴다', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const f = ctx.firestore();
      await setDoc(doc(f, 'proposals', '9'), { ownerUid: OWNER, item: '갓김치', status: 'open' });
      await setDoc(doc(f, 'proposals', '9', 'asks', HELPER), { uid: HELPER, item: '갓', status: 'pending' });
    });
    await assertSucceeds(getDoc(doc(db(HELPER), 'proposals', '9', 'asks', HELPER)));
    await assertSucceeds(getDocs(collection(db(OWNER), 'proposals', '9', 'asks')));
    await assertFails(getDoc(doc(db(STRANGER), 'proposals', '9', 'asks', HELPER)));
    await assertFails(setDoc(doc(db(STRANGER), 'proposals', '9', 'asks', STRANGER), { uid: STRANGER, item: 'x' }));
  });
});
