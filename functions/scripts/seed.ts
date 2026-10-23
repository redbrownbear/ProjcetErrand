/**
 * 로컬 에뮬레이터에 예시 데이터 · 테스트 계정 넣기 (실제 프로젝트에는 절대 쓰지 않는다 — 에뮬레이터가 아니면 멈춘다)
 *
 *   터미널 1: npm run dev      (에뮬레이터 + 서버 함수)
 *   터미널 2: npm run seed     (여러 번 돌려도 같은 결과)
 *
 * 계정(비밀번호 모두 test1234): 요청자 a@test.dev · 수행자 b@test.dev · 운영자 admin@test.dev
 * 앱은 `flutter run --dart-define=EMULATOR_HOST=10.0.2.2`로 붙인다(functions/README.md).
 */
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

import { DEFAULT_MATCH } from '../src/route/match';
import { DEFAULT_POLICY } from '../src/safety/policy';
import { C } from '../src/shared/paths';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
const PROJECT = process.env.GCLOUD_PROJECT ?? 'projecterrand';

const ACCOUNTS = [
  { uid: 'test-a', email: 'a@test.dev', nickname: '요청자A' },
  { uid: 'test-b', email: 'b@test.dev', nickname: '수행자B' },
  { uid: 'test-admin', email: 'admin@test.dev', nickname: '운영자', admin: true },
];

async function main() {
  initializeApp({ projectId: PROJECT });
  const auth = getAuth();
  const db = getFirestore();

  for (const a of ACCOUNTS) {
    await auth.deleteUser(a.uid).catch(() => undefined);
    await auth.createUser({ uid: a.uid, email: a.email, password: 'test1234', displayName: a.nickname });
    if (a.admin) await auth.setCustomUserClaims(a.uid, { role: 'admin' });
    await db.collection(C.users).doc(a.uid).set({ nickname: a.nickname, createdAt: Timestamp.now() });
  }

  // 서버 설정 — 콘솔에서 고치는 것과 같은 문서
  await db.collection(C.config).doc('safety').set(DEFAULT_POLICY);
  await db.collection(C.config).doc('matching').set(DEFAULT_MATCH);
  await db.collection(C.config).doc('points').set({ expireDays: 0, shopOpen: false });

  // 요청자A가 올린 동네 부탁 3건(내일 이 시각 마감)
  const now = Date.now();
  const samples = [
    { cat: 'pickup', title: '편의점 택배 찾아 주세요', desc: '방배동 GS25, 저녁 7시 전에요', price: 3000 },
    { cat: 'shop', title: '마트에서 우유 두 팩만', desc: '서울우유 1L 두 개', price: 4000, budget: 6000 },
    { cat: 'etc', title: '분리수거 같이 내려 주실 분', desc: '박스 세 개예요', price: 2000 },
  ];
  for (const [i, s] of samples.entries()) {
    const id = String(now - i * 1000);
    await db.collection(C.requests).doc(id).set({
      ownerUid: 'test-a',
      who: '요청자A',
      mode: 'ask',
      region: '서울 서초구 방배동',
      area: '서울 서초구 방배동',
      budget: 0,
      ...s,
      status: 'open',
      applicantCount: 0,
      deadline: Timestamp.fromMillis(now + 86_400_000),
      createdAt: Timestamp.fromMillis(now - i * 1000),
      updatedAt: Timestamp.fromMillis(now - i * 1000),
    });
  }

  await db.collection(C.notices).doc('welcome').set({
    title: '로컬 에뮬레이터예요',
    body: 'npm run seed가 넣은 예시 공지예요.',
    kind: 'notice',
    pinned: true,
    hidden: false,
    publishedAt: Timestamp.now(),
  });

  console.log(`에뮬레이터(${PROJECT})에 넣음: 계정 ${ACCOUNTS.length}개 · 부탁 ${samples.length}건 · 설정 3개 · 공지 1개`);
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : e);
  process.exit(1);
});
