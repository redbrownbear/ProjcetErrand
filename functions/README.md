# 겸사겸사 서버 함수 (functions/)

Firebase Cloud Functions(TypeScript, 서울 리전 `asia-northeast3`). 앱은 읽기만 하고 **돈 · 상태 · 신뢰에 관한 쓰기는 모두 여기서** 한다.
보안 규칙은 `../firebase/firestore.rules` · `../firebase/storage.rules`, 설계 근거는 `../docs/1차_백엔드_설계.md`.

## 처음 한 번

```bash
cd functions
npm ci
npm run build && npm run test:unit   # 1분 안에 끝나는 확인
```

Java 17 이상이 있어야 에뮬레이터(`npm test` · `npm run dev`)가 돈다. Firebase CLI는 `npx firebase`로도 된다.

## 자주 쓰는 명령

| 명령 | 하는 일 |
| --- | --- |
| `npm run typecheck` | 타입만 확인 |
| `npm run test:unit` | 단위 테스트(에뮬레이터 없이) |
| `npm test` | 단위 + 에뮬레이터 테스트(거래 흐름 · 보안 규칙). CI(`functions`)와 같다 |
| `npm run dev` | 로컬 에뮬레이터(Auth · Firestore · Functions · Storage) — 코드를 고치면 `npm run build:watch`를 옆에 띄워 둔다 |
| `npm run seed` | 에뮬레이터에 테스트 계정 · 예시 부탁 · 설정 넣기(여러 번 돌려도 같음) |
| `npm run deploy:dev` | 개발 프로젝트에 함수 · 규칙 · 색인 배포 |

## 앱까지 로컬에서 돌리기

1. 터미널 1: `npm run dev`
2. 터미널 2: `npm run seed` → 계정(비밀번호 `test1234`): 요청자 `a@test.dev` · 수행자 `b@test.dev` · 운영자 `admin@test.dev`
3. 앱: `flutter run --dart-define=EMULATOR_HOST=10.0.2.2` (안드로이드 에뮬레이터 기준. 실제 폰은 PC 내부 IP를 넣고,
   `firebase.json`의 각 에뮬레이터에 `"host": "0.0.0.0"`을 잠깐 더한다 — 커밋하지 않는다)
4. 로그인 화면 아래 '테스트 계정(이메일)'으로 들어간다. 에뮬레이터에서는 푸시를 실제로 보내지 않고 로그만 찍는다(알림함 기록은 그대로)

개발 · 운영 프로젝트의 데이터는 건드리지 않는다. 에뮬레이터를 끄면 데이터도 사라진다.

## 폴더

```
src/
  index.ts          배포되는 함수 목록(여기 export된 이름 = 함수 이름)
  config.ts         리전 · 인스턴스 상한 · App Check 스위치
  shared/           모듈들이 같이 쓰는 것
    callable.ts       앱이 부르는 함수 껍데기(로그인 · App Check · 운영자 확인)
    input.ts          요청 값 검사(fields · docId · ownPhotoPath)
    guards.ts         정지 계정 · 차단 관계 · 닉네임
    paths.ts          Firestore 컬렉션 이름(C.users …) — 문자열을 직접 쓰지 않는다
    kst.ts            한국 시간
  domain/           앱과 같이 지켜야 하는 규칙(거래 단계 상태 머신)
  errand/           부탁 · 지원 · 수락 · 거래 단계 · 마감 정리
  chat/ comment/ photo/   채팅 · 공개 댓글 · 완료 사진/영수증 (연락처 가리기 chat/mask.ts)
  proposal/         제안하기 · 신청 · 대기 · 따로 부탁
  points/           출석 적립 · 교환 · 쿠폰 · 소멸 (금액 표 catalog.json — 앱 표와 같은지 앱 테스트가 본다)
  route/            동선 격자 · 동선 맞춤 추천
  safety/           금지 품목 · 물건값 상한(config/safety)
  notify/           알림함 기록 + 푸시(deliver.ts), 지원서 · 거래 변경 알림, 실제 FCM(fcm.ts)
  admin/            운영자 함수 · 신고 자동 분류
  auth/             카카오 · 네이버 로그인
test/unit/          에뮬레이터 없이 도는 테스트
test/emu/           에뮬레이터 테스트(helpers.ts: adminDb · clearDb · seedRequest · rejectsWith)
scripts/            운영 스크립트(set-admin.js · post-notice.js) · 로컬 예시 데이터(seed.ts)
```

모듈 하나 = `core.ts`(로직) + `callables.ts`(앱이 부르는 함수) + 필요하면 `triggers.ts`(문서 변경 · 예약 실행).
**`core.ts`는 Firestore 인스턴스만 받는다** — Cloud Functions 런타임 없이 에뮬레이터에서 그대로 테스트할 수 있게.

## 새 함수 더하기

1. `src/<모듈>/core.ts`에 로직: `(db, uid, data, push?) => 결과`
   - 입력은 `fields(data)`로 받고 `docId` 등으로 검사. 실패는 `HttpsError('invalid-argument', '사용자에게 보일 한국어 문구')`
   - 상태를 바꾸면 트랜잭션 안에서 **다시 읽고 → 허용되는지 확인 → 쓴다**(같은 요청이 두 번 와도 두 번째는 거부되게)
   - 정지 · 차단은 `shared/guards.ts`, 컬렉션 이름은 `C.<이름>`(없으면 `shared/paths.ts`에 더한다)
   - 알림은 `deliver(db, push, 이벤트, 이벤트id)` — 같은 이벤트 id는 한 번만 간다
2. `src/<모듈>/callables.ts`에 `export const 이름 = userCallable((db, uid, data) => core.이름(db, uid, data, fcm));`
3. `src/index.ts`에 export, `test/unit/exports.test.ts` 목록에 이름 추가
4. 테스트: `test/emu/<모듈>.test.ts`에 성공 한 번 + 거부 몇 가지(`rejectsWith(p, 'permission-denied')`)
5. 앱이 문서를 새로 읽으면 `../firebase/firestore.rules`와 `test/emu/rules.test.ts`도
6. 앱 쪽 호출은 `lib/core/backend/server_api.dart`의 `ServerApi.call('이름', {...})`
7. `../docs/WORKLOG.md` 기록 + '할 일'에 배포 명령

## 지켜야 할 것

- **이미 깔린 앱을 깨지 않는다.** 서버는 배포 즉시 모든 사용자에게 바뀌지만 앱은 마켓 업데이트가 필요하다.
  함수 이름 · 입력 필드 · 응답 필드 · 컬렉션 이름은 바꾸거나 지우지 말고 **더한다**. 함수 이름은 `exports.test.ts`가 지킨다.
- 숫자 · 목록처럼 운영하며 바꿀 값은 코드 대신 `config/*` 문서에서 읽는다(콘솔에서 고치면 배포 없이 반영). 기본값은 코드에 둔다.
- 비밀 값은 `.env.<프로젝트>`가 아니라 Secret Manager(`defineSecret`)로. 공개 값 예시는 `.env.example`.
- 오류 문구는 사용자에게 그대로 보인다 — 한국어로, 무엇을 하면 되는지까지.

## 배포

```bash
firebase deploy --project dev --only functions          # 함수만
firebase deploy --project dev --only functions,firestore # 규칙 · 색인까지
```

`predeploy`가 빌드를 먼저 돌린다. 운영 프로젝트(`prod`)는 출시 전에 따로 만든다 — dev에서 확인한 같은 커밋을 `--project prod`로.
