# 작업 기록 (WORKLOG)

여러 PC·여러 사람이 이어서 작업하기 위한 **공용 기억**이다. Claude는 실행할 때 이 파일을 읽고 시작한다
(루트 `CLAUDE.md`가 불러온다). 로컬 메모리 대신 여기에 적고, git으로 함께 옮겨 다닌다.

## 쓰는 법

- **커밋할 때마다** 맨 아래 `기록`의 맨 위에 한 덩어리를 추가한다. 최신이 위.
- 한 덩어리 = `### 날짜 · 커밋 해시 · 작업자(PC)` + 아래 세 줄 중 해당하는 것만.
  - `추가` 새로 생긴 화면·기능·파일
  - `변경` 동작이나 구조가 바뀐 것
  - `제거` 없앤 것 — **무엇을 왜 뺐는지** 꼭 적는다 (나중에 "그거 어디 갔지?"의 답)
- 아직 커밋 전이면 해시 자리에 `미커밋`이라고 쓰고, 커밋하면 해시로 바꾼다.
- 기능이 생기거나 없어져서 `현재 상태`가 틀려지면 같이 고친다. `다음 할 일`은 끝나면 지운다.
- 지금 안 하기로 한 일은 `보류`의 세 칸(출시 후 · 조건부 · 아이디어) 중 하나에 넣는다. 기준은 그 칸 위의 표.
- 자세한 설계 근거는 `docs/`의 개별 문서에 두고, 여기서는 한 줄 + 링크만.

## 현재 상태

- Flutter 앱 `gyeomsa` — 동네 심부름·해외 사다주기·단기알바·미션/공동구매.
- 디자인 기준: **기획 시안 v77** ([v77_리메이크.md](v77_리메이크.md)) — v33 적용분([v33_디자인_적용.md](v33_디자인_적용.md)) 위에 얹음.
  하단 메뉴 홈 · 마켓 · 커뮤니티 · 채팅 · 마이. 홈 맨 위 국내/해외 전환, 그 안에서 부탁하기/돈벌기(해외는 + 현지 이웃).
  오른쪽 위 '글쓰기'에서 가는 김에 · 제안 · 부탁 · 해외 부탁 · 중고 · 커뮤니티 글을 고른다.
- v77 이웃 활동(제안 · 커뮤니티 이야기 · 중고/나눔 · 응모권)은 `NeighborStore`가 들고 **이 기기에만** 저장한다.
  '가는 김에'만 서버(`tripPosts`)에 올라가 모든 계정이 보고 댓글을 단다.
  화면 이동은 `AppNav` 하나로. 부탁·포인트·겸사페이는 그대로 `AppSession`.
- 백엔드: Firebase(Auth·Firestore). 서버 연결이 안 되면 `LocalStore`(이 기기)에 저장 ([백엔드_연결.md](백엔드_연결.md)).
  1차 출시용 서버 설계·갈래(W1~W10)는 [1차_백엔드_설계.md](1차_백엔드_설계.md). 서버 함수는 `functions/`(TypeScript, 서울 리전),
  지원·수락·거래 단계는 **서버 함수로 처리**한다(`TradeRepository` → `functions/src/errand`). 앱은 결과를 Firestore 구독으로 받는다.
  서버 함수는 dev(`projecterrand`)에 배포됨(2026-10-20). 규칙 v2는 아직 배포 전 — 앱 W3 반영본과 함께 올린다.
- 지도: 네이버 지도(`flutter_naver_map`). 제휴 미션·퀴즈 API 연동 ([제휴_API_연동.md](제휴_API_연동.md)).
- 원칙: 지어낸 숫자를 사실처럼 보여 주지 않는다(예시 데이터엔 '예시' 표시). 겸사페이(원)와 포인트(P)는 섞지 않는다.

## 다음 할 일

### 1차 출시 백엔드 ([1차_백엔드_설계.md](1차_백엔드_설계.md))

- [ ] W3 앱 반영본 배포 — 저장소 폴더에서 `firebase deploy --project dev --only functions,firestore`(함수 갱신 + 규칙 v2 + 색인).
      그 뒤 예전 앱 빌드는 지원·포인트 저장이 막히므로 테스트 기기 앱도 새로 설치
- [ ] W3 실기기 확인 — 계정 두 개로 지원 → 받은 지원 수락 → 시작 → 완료 요청 → 완료 확인, 취소·거절
- [ ] 예산 알림 설정(Google Cloud 콘솔 › 결제 › 예산 및 알림, 50·90·100%)
- [ ] 출시 전 운영 프로젝트 새로 만들기 → `.firebaserc`에 `prod` 추가, 앱 `google-services.json` 교체
- [ ] 수락된 수행자에게 정확한 장소 보여 주기 — 지금은 `private/detail`에 저장만 하고 수행자 화면에서 읽지 않는다
- [ ] W4·W5 배포·실기기 확인 — 알림 권한 허용 → 지원·수락·단계 변경마다 상대 기기에 푸시와 알림함, 신고 접수, 차단 후 목록에서 사라짐.
      운영자 지정은 [1차_백엔드_설계.md › W5 운영 방법](1차_백엔드_설계.md)
- [ ] 채팅 실기기 확인 — 수락 뒤 채팅 탭에 대화방, 메시지 주고받기, 전화번호를 쓰면 가려지는지, 상대 기기 푸시·안 읽은 수
- [ ] W6 동선 구조화 · W7 추천 v0 · 운영자용 신고 처리 화면
- [ ] 포인트·미션·출석·응모권을 1차 출시 빌드에서 숨기기(결정 6). 포인트 서버 이전(W8)은 그다음 업데이트

- [ ] '가는 김에' 배포·실기기 확인 — 계정 두 개로 글 올리기 → 다른 계정에서 보이고 댓글 → 글쓴이 알림
- [ ] v77 이웃 활동(제안·이야기·중고·응모권) 서버 저장 — 지금은 이 기기에만 남는다('가는 김에'는 서버로 옮김)
- [ ] 럭키드로우 추첨·발표 — 응모까지만 됨. 경품 재원·추첨 공정성·경품 관련 법규 검토 후 서버에서
- [ ] 실제 기기에서 v77 홈·마켓·커뮤니티 확인 (브라우저에서만 확인함)

- [ ] v33 디자인 적용분 커밋 (아래 `미커밋` 항목)
- [ ] 로그인 상태의 마이 화면을 실제 기기에서 확인 (브라우저에선 로그아웃 상태만 확인함)
- [ ] 리팩토링 이어서: 주석 정리 2차 (큰 화면 분리는 2026-10-16에 끝냄)
- [ ] 실제 기기에서 계정 전환 확인 — 로그아웃·다른 계정 로그인 때 앞사람 자료가 지워지는지, 로그인 직후 출석이 서버 값에 덮이지 않는지
      (2026-10-16 리뷰에서 고침. 브라우저 로그아웃 상태와 테스트로만 확인함)
- [ ] 포인트 적립·차감을 서버(Cloud Functions)로 옮기기 — 설계는 [백엔드_연결.md › 10. 포인트](백엔드_연결.md#10-포인트).
      광고 보상을 실제로 열기 전에 끝내야 한다

### 출시 준비 (구글 플레이 먼저)

광고 수익(애드핏·AdMob)은 **공개 스토어 페이지가 있어야** 신청·승인된다. 그래서 출시가 먼저다.

- [ ] 플레이 개발자 계정 종류 확인 — 2023-11-13 이후 만든 **개인** 계정이면 비공개 테스트
      (테스터 12명 · 14일 연속)를 거쳐야 정식 출시 권한 신청 가능 (심사 보통 7일 이내). 사업자 계정은 면제
- [ ] 릴리스 서명 키 만들기 — 지금 `android/app/build.gradle.kts` release가 **debug 키로 서명**됨.
      업로드 키(keystore)를 만들고 키 파일·비밀번호는 저장소 밖에 보관
- [ ] 버전 — `pubspec.yaml` `version: 1.0.0+1`. 올릴 때마다 `+숫자`(versionCode) 증가
- [ ] **회원 탈퇴(계정 삭제)** — 계정을 만드는 앱은 앱 안 + 웹 링크 두 곳에서 삭제를 요청할 수 있어야 함.
      지금 앱에 탈퇴 기능 없음. Firebase Auth 계정 + `users/{uid}` 하위 자료 삭제 필요
- [ ] 개인정보처리방침 URL — 플레이 등록 필수. 수집 항목: 이메일·닉네임·위치(정밀)·활동 기록
- [ ] 플레이 콘솔 '데이터 보안' 양식 — 위 수집 항목·Firebase 전송·광고 SDK(붙인 뒤) 기재
- [ ] 위치 권한 — `ACCESS_FINE_LOCATION` 사용(체크인·지도). 국내는 **위치기반서비스사업 신고**
      (방송통신위원회) 대상인지 확인
- [ ] 겸사페이 — 충전·출금은 디버그 빌드에서만 열림(`PayConfig`). 출시 빌드에서 '개발용' 문구가 안 보이는지 확인
- [ ] 예시 데이터 — 출시 빌드에서 예시 부탁·미션을 둘지 결정 (지금은 '예시' 표시로 노출)
- [ ] 스토어 등록 정보 — 앱 이름·짧은 설명·자세한 설명·아이콘 512px·그래픽 이미지 1024×500·스크린샷(휴대폰 2장 이상)
- [ ] 콘텐츠 등급 설문 · 타깃 연령 · 광고 포함 여부 표시
- [ ] 네이버 지도 — 클라우드 콘솔에 **릴리스 패키지명·서명**으로 앱 등록돼 있는지 (debug 서명만 등록돼 있으면 출시 앱에서 지도 안 뜸)
- [ ] Firebase — 릴리스 서명 SHA-1/SHA-256을 Android 앱에 추가
- [ ] iOS(나중) — 번들 ID가 아직 `com.example.pumApp`. 정식 ID 정하기 → Firebase iOS 앱 등록 → 애플 개발자 계정
- [ ] '광고 보고 포인트 받기' 카드를 출시 빌드에서 '준비 중'으로 둘지 숨길지 결정
      (없는 기능을 스토어 설명·마케팅에 내세우면 메타데이터 정책 위반 소지)

## 보류

지금 안 하기로 한 일. 언제 다시 꺼낼지에 따라 세 칸으로 나눈다.

| 칸 | 언제 꺼내나 |
| --- | --- |
| **출시 후** | 구글 플레이에 공개된 뒤. 스토어 링크·실사용자가 있어야 진행되는 일 |
| **조건부** | 적어 둔 `조건`이 채워지면 (사업자 등록, 재원, 서버 작업 완료 등). 날짜와 무관 |
| **아이디어** | 아직 할지 말지 정하지 않은 것. 내용을 보충하다가 하기로 정하면 `다음 할 일`이나 위 두 칸으로 옮긴다 |

항목은 `무엇` — `조건/이유` — `다시 시작할 때 할 일` 순으로 적는다. 꺼내서 시작하면 여기서 지우고 `다음 할 일`로 옮긴다.

### 출시 후

- **광고 수익 연결 (카카오 애드핏)** — 신청서에 스토어 링크·월 이용자 수가 필요하다. 사용자가 어느 정도 쌓인 뒤 신청이 유리.
  - 신청: [with.kakao.com 제휴 제안](https://with.kakao.com/proposition?type=service&page=adfit), 설명란에 '리워드 동영상 이용 희망' 기재
  - 애드핏은 **테스트 광고가 없고, 심사 반려 시 같은 앱 재심사 불가** — 앱을 안정시킨 뒤 신청
  - 승인 → 광고단위 ID 발급 → SDK 넣은 업데이트 출시 → 매체 심사 → 실제 광고 노출
- **광고 보고 포인트 받기 (카카오 리워드 동영상)** — 앱 화면·안내 시트·적립 흐름은 붙어 있고 카드는 '준비 중'.
  - 조건: 위 애드핏 승인 + 리워드 동영상 상품·SDK 확보(공개 SDK v3.23.1엔 없음) + 아래 '포인트 서버 이전' 완료
  - 할 일: ① 광고단위 ID를 `ADFIT_REWARD_ANDROID/IOS`에 ② 네이티브 `gyeomsa/adfit_reward` 채널 `show` 구현
- **광고를 붙이는 업데이트 때 함께 할 일**
  - 플레이 콘솔: '광고 포함' 표시 켜기, 데이터 보안 양식에 광고 SDK 수집 항목(광고 ID 등) 추가 — 안 바꾸면 업데이트 반려 소지
  - `AndroidManifest.xml`에 광고 ID 권한(`com.google.android.gms.permission.AD_ID`) 선언 (Android 13+ 대상)
  - iOS: 추적 허용 문구(ATT, `NSUserTrackingUsageDescription`)
- **본격 마케팅** — 기본 기능(부탁 올리기·지원·로그인)이 안정된 뒤. 출시 초반 평점·리뷰가 오래 남는다.
  없는 기능을 홍보 문구에 쓰지 않는다

### 조건부

- **포인트 적립·차감 서버 이전** — 조건: 광고 보상 등 실제 재원이 붙기 전. 설계는 [백엔드_연결.md › 10. 포인트](백엔드_연결.md#10-포인트)
  (지금은 `다음 할 일`에도 올라가 있음)
- **오퍼월 (애드팝콘·버즈빌)** — 조건: 사업자 등록 + 매체 계약. 적립은 제휴사 → 우리 서버 콜백이라 Cloud Functions 수신부가 함께 필요
  ([제휴_API_연동.md](제휴_API_연동.md) '오퍼월은 목록을 우리가 못 만든다')
- **겸사페이 실제 충전·출금** — 조건: PG 계약 + 본인 계좌 인증 + 전자금융거래법(선불전자지급수단) 검토.
  지금은 디버그 빌드에서만 '개발용'으로 동작 ([백엔드_연결.md › 8](백엔드_연결.md#8-겸사페이-구조만))
- **걷기 적립** — 조건: 재원(제휴사 비용 부담) 확보. 화면에서만 내렸고 `WalkScreen`·`parkedMissions`·`parkedAds`는 남아 있음.
  실제 걸음 수는 Health Connect / HealthKit + `health` 패키지 필요
- **친구 초대 지급** — 조건: 서버가 초대 코드를 발급·확인하는 기능. 지금은 링크 복사까지만

### 아이디어

- **응모권 커뮤니티 적립 한도** — 지금 글·답글마다 +1장이라 답글을 반복해 응모권을 쌓을 수 있다(경품이 항공권). 오늘의 퀴즈도
  틀리면 바로 다시 고를 수 있다. 하루 한도·재도전 제한을 둘지 정하기 (2026-10-16 리뷰에서 발견, 규칙이라 코드만으로 정하지 않음)
- **이번 주 출국 이웃 보드** (v33·v77 해외 탭) — 여행자가 출국 일정을 올리고 그 나라 요청을 먼저 받는 기능. 출국 일정 데이터 구조부터 필요.
  v77 병합 때도 지어낸 인원수를 보여 줘야 해서 옮기지 않았다
- **해외 부탁 예비금 30%** (v77 해외 돈벌기의 '예상가 · 예비금 30%') — 앱에 없는 정책이라 화면에 넣지 않았다

## 환경 메모

- (불곰 PC) pub 캐시가 `C:\src\pub-cache` (`PUB_CACHE` 사용자 환경변수). Android Studio가
  `AppData\Local\Pub\Cache`를 못 읽는 문제로 옮겼다. 경로가 다시 AppData로 보이면 환경변수가 풀린 것.
  바꾼 뒤엔 Android Studio를 완전히 종료 후 재시작.

## 기록

### 2026-10-20 · a108b0d · Claude (가는 김에 서버 저장 · 댓글)
- 추가(서버): `tripPosts` 규칙(본인 이름으로만 올림·누구나 읽음·글쓴이만 지움, 댓글 수·댓글은 앱이 못 씀),
  `functions/src/trip/` — `addTripComment`(300자, 연락처 가리기, 정지·차단 확인, 글쓴이에게 알림함+푸시 `trip.comment`). 알림 문서에 `tripId`
- 추가(앱): `trip/repositories/trip_repository.dart`, 글 상세 `trip/screens/trip_detail_screen.dart`(댓글 목록·쓰기, 내 글 지우기,
  '가요' 글엔 '정식으로 부탁 올리기' 링크), 알림을 누르면 그 글로. 글쓰기에 **제목 칸**(장소를 따라 제안하고 직접 고칠 수 있음)
- 변경: '가는 김에' 글을 서버에 올려 모든 계정이 본다(서버 연결 전엔 이 기기에만). 내 글 여부는 계정 uid로 판단 —
  예전엔 이 기기 글을 모두 '나'로 보여서 같은 폰의 다른 계정이 아무것도 못 했다. 카드 버튼 '부탁하기'·'도와주기' → '댓글로 부탁하기'·'댓글로 도와주기'(상세로)
- 제거: 카드의 '도와주기 의사를 전했어요 · 확인하면 채팅이 열려요' 토스트 — 실제로 아무것도 전달되지 않았다.
  이 기기에만 있던 '가는 김에' 글은 서버 연결 상태에선 보이지 않는다(다른 계정에 안 보이는 글이라 섞지 않음).
  제안 '구매 요청'·현지 이웃 '신청' 토스트의 "확인하면 채팅이 열려요"도 사실과 달라 '아직 전달되지 않아요'로 바꿈

### 2026-10-20 · d17f41d · Claude (브랜치 정리)
- 변경: 작업 브랜치(feat/w1-w2 ~ feat/chat)를 모두 main에 합침(fast-forward). 앞으로 main에 바로 커밋 — `CLAUDE.md`에 규칙 추가
- 제거: PR #2·#3 닫음(내용은 main에 들어감). 원격 feat 브랜치 3개는 GitHub에서 지우면 됨

### 2026-10-20 · ce03543 · Claude (최소 채팅 — 결정 5)
- 추가(서버): `functions/src/chat/` — `sendMessage`(거래 당사자만, 1000자, 전화번호·계좌번호·이메일·외부 링크를 가려 `trades/{id}/messages`에 저장,
  거래 문서에 마지막 메시지·사람별 안 읽은 수, 상대에게 푸시 — 알림함에는 쌓지 않음)·`markChatRead`. 규칙: 메시지는 당사자만 읽고 앱은 못 씀
- 추가(앱): `chat/screens/chat_screen.dart`(채팅방), `chat/models/chat_message.dart`, `chat/repositories/chat_repository.dart`,
  채팅 탭에 대화 목록(안 읽은 수), '진행 중인 부탁' 카드에 '상대방과 채팅하기'
- 변경: 채팅 탭 빈 화면 문구 — "지원하거나 가격을 제안하면 대화가 시작" → "지원이 수락되면 대화"(실제 동작에 맞춤)

### 2026-10-20 · 46b5698 · Claude (W4 알림 · W5 신고·차단·운영)
- 추가(서버): `functions/src/notify/` — 지원서·거래 문서 변경 트리거(`onApplicationWrite`·`onTradeWrite`) → 알림함
  `users/{uid}/notifications` 기록 + FCM 푸시(만료 토큰 정리, 같은 이벤트는 한 번만). `functions/src/admin/` — 운영자 함수
  `adminSetSuspended`·`adminResolveReport`(custom claim `role=admin`, `adminLog` 기록), `functions/scripts/set-admin.js`(운영자 지정)
- 추가(앱): `core/backend/push_service.dart`(알림 권한·토큰 등록·앱 켜져 있을 때 토스트), `profile/models/app_notice.dart`,
  `profile/repositories/safety_repository.dart`(알림함·차단·신고), 부탁 상세 '이 부탁 신고 · 글쓴이 차단' 시트(`report_sheet.dart`),
  헤더 알림 시트에 최근 알림 10개(열면 읽음 처리), `firebase_messaging` 패키지, `POST_NOTIFICATIONS` 권한, `test/server_models_test.dart`
- 변경: 차단한 사용자의 부탁은 목록에서 숨긴다. 로그아웃 **전에** 이 기기의 알림 토큰을 계정에서 지운다(`AuthService.beforeSignOut`) —
  안 지우면 다음 사람이 앞사람의 알림을 받는다
- 변경(문구): 해외 부탁 상세·해외 화면의 "앱이 물건값·사례비를 안전하게 보관/정산·중재" 안내 → "앱 안의 결제·보관은 아직 없어요"
  (실제로 보관·정산 기능이 없어 사실과 달랐다)

### 2026-10-20 · be4478e · Claude (W3 앱 연결 · W2 위치 분리)
- 추가: `core/backend/server_api.dart`(서버 함수 호출, 실패를 화면 문구로), `errand/models/application.dart`(지원서·거래 문서 모델),
  `errand/repositories/trade_repository.dart`(내 지원·받은 지원·거래 구독 + 서버 함수), '진행 중인 부탁'에 **받은 지원**(수락·거절),
  GitHub Actions `app` 워크플로(`flutter analyze`·`flutter test`), `cloud_functions` 패키지
- 변경: `AppSession.apply`·`updateTrade`가 서버 함수를 부르고, `trades`는 서버의 지원서·거래 문서에서 만든다.
  단계 버튼은 역할별(수행자: 시작·완료 요청 / 요청자: 완료 확인·보완 요청). 가격 제안은 지원할 때 함께 보낸다.
  모집이 끝나 공개 목록에서 빠진 내 거래의 부탁은 따로 불러온다(`RequestRepository.get`). 예시 부탁에는 지원할 수 없다
- 변경(W2): 부탁 등록 때 정확한 장소·좌표를 `requests/{id}/private/detail`로, 공개 문서엔 `area`만. 내 글은 이 기기 사본을 먼저 보여 준다
- 변경(서버): 지원서에 `requesterUid`·`helperName`·`requestTitle` 사본 저장, 요청자의 '받은 지원' collectionGroup 조회 규칙·색인
- 제거: '요청자 수락 체험'·'요청자 완료 확인 체험' 버튼 — 이제 실제 요청자가 누른다.
  거래 완료 때 앱이 쓰던 겸사페이 '번 돈' 기록과 응모권 지급 — 결제·정산이 미정이고(결정 10) 포인트·응모권은 1차에서 숨긴다(결정 6).
  `RequestRepository.close` — 모집 취소·마감은 서버 함수(cancelRequest·expireRequests)만 한다.
  첫 로그인 이관에서 지원 내역·제안·겸사페이 기록 업로드 — 서버 함수만 지원·거래를 만들 수 있고 체험 기록이라 옮기지 않는다(결정 4)

### 2026-10-20 · 4a7ae2f · Claude (개발 프로젝트 지정)
- 변경: `projecterrand`를 개발용(dev)으로 쓰기로 함(결정 3 변경). `.firebaserc`는 default/dev = `projecterrand`, prod는 출시 전에 새 프로젝트로 추가.
  `firebase.json` predeploy를 `npm --prefix functions run build`로(Windows에서 `$RESOURCE_DIR`가 안 풀리는 문제), `deploy:prod` 스크립트 제거

### 2026-10-20 · 854d3f3 · Claude (1차 백엔드 W1·W2·W3 서버 부분)
- 추가: [1차_백엔드_설계.md](1차_백엔드_설계.md) — 현재 상태 점검, 1차 출시 범위, 작업 갈래 W1~W10, 결정 필요 11건(3·5·6 결정됨)
- 추가: `firebase.json` · `.firebaserc`(default/dev = `projecterrand-dev`, prod = `projecterrand`), `functions/`(TypeScript, `asia-northeast3`) —
  거래 흐름 함수 `applyToRequest` · `withdrawApplication` · `acceptApplication` · `rejectApplication` · `cancelRequest` · `advanceTrade`,
  예약 실행 `expireRequests`(1시간). 상태 머신은 앱 `Trade._transitions`를 옮기고 역할(요청자·수행자) 검사를 더함
- 추가: 테스트 — 상태 머신 단위 테스트, 에뮬레이터 통합 테스트(거래 흐름·규칙), GitHub Actions `functions` 워크플로
- 변경: `firebase/firestore.rules` v2 — 지원·거래·포인트는 서버만 쓰기, 공개 부탁글 필드 화이트리스트(정확한 위치 금지 → `private/detail`),
  `users`의 points·verified·role·suspended·stats 앱 쓰기 금지, 신고(`reports`) 생성, 프로토타입 기록(`users/*/trades·offers·coupons·ledger·payEntries`)은 읽기 전용.
  `firebase/firestore.indexes.json`에 마감 정리·거래 목록·지원 목록 색인 추가
- 변경: 가격 제안 안내 문구 "요청자에게만 보여요" → "요청자에게 전달하는 기능은 준비 중이에요"(요청자에게 실제로 전달되지 않음)

### 2026-10-16 · 6ae165e · BEAR\speed (전체 코드 리뷰 — 버그 수정·리팩토링)
- 변경(버그): 부탁 상세가 하얗게 뜨던 문제 — 테마의 버튼 최소 크기가 무한 폭(`Size.fromHeight`)이라 Row 안의 '가격 제안' 버튼에서
  레이아웃이 깨졌다(지도 미리보기 카드도 같음). 상세의 관심 저장 아이콘이 안 바뀌어 두 번 누르면 풀리던 문제(옛 목록에 묶인 콜백) —
  `ErrandActions`에 `changes`·`latest`를 둬 열린 상세가 최신 값으로 다시 그린다
- 변경(버그): 로그아웃·다른 계정 로그인 때 앞사람의 관심·지원·겸사페이 기록이 화면에 남고, 새 계정으로 이관까지 되던 문제 —
  `SessionStore`가 사본 주인(`owner`)을 기록하고 바뀌면 비운다. 로그인 직후 적립하면 늦게 온 서버 값이 덮어쓰던 문제 —
  `AppSession.accountReady`를 기다린 뒤 실행. 포인트·쿠폰이 기기에 저장되지 않아 오프라인 재실행 때 0P로 뜨던 문제
- 변경(버그): 포인트샵·내 쿠폰이 연 순간의 값에 묶여 교환해도 포인트가 그대로고, 교환에 실패해도 '교환 완료'가 뜨던 문제 —
  `PointWallet`(포인트·쿠폰·교환·사용 묶음)으로 바꿔 화면이 바뀐 값을 듣는다. 인기 상품 줄 높이 부족(카드 아래 잘림),
  보유 포인트 여섯 자리에서 넘침, 머리줄 '내 쿠폰'이 '내/쿠'로 접히던 것(→ 아이콘 버튼)
- 변경(버그): 32개가 넘는 목록의 정렬이 뒤섞이던 문제(Dart `sort`는 안정 정렬이 아님) → `core/utils/stable_sort.dart`.
  작성자 이름이 '나'인 남의 서버 글이 내 글로 보이던 판단 제거. 쿠폰 유효기간 '2026.12.31' 고정 → 교환일+1년.
  겸사페이 원장을 최근 100줄만 읽어 잔액이 틀릴 수 있던 것, 쿠폰을 쓸 때마다 `createdAt`이 다시 찍혀 순서가 바뀌던 것.
  응모권 하루 기준을 출석과 같은 한국 시간으로, 지난 달 하루 기록은 버림. 저장된 제안·가는 김에 글의 잘못된 값에 앱이 멈추지 않게
- 변경(버그): 숫자 칸에 쉼표를 넣으면 0원이 되던 것(물품 예산·단기알바 급여 등 → 숫자만 입력). '1,000원 결제하고 올리기'인데
  실제 결제는 없던 문구 → '급해요로 올리기 · 결제 연동 전이라 지금은 무료'. 혜택 '근처에서 벌기'에 해외·마감 부탁이 섞이던 것.
  상세 뒤로가기 누르는 칸이 '‹' 글자 폭뿐이던 것. 단기알바 모집에서 시스템 뒤로가기가 쓰던 내용을 날리던 것(한 단계씩 돌아감).
  로그인 화면에서 서버 미연결 사유가 '문제가 발생했어요'로만 나오던 것
- 변경(리팩토링): `benefits_view` 609→290줄(`benefits_parts.dart`로 카드 분리), `detail_page` 415→220줄(`detail_parts.dart`),
  `job_post_screen`의 값·검증을 `job_post_form.dart`로, 로그인·가입 화면의 같은 입력 칸·버튼을 `auth/widgets/auth_widgets.dart`로
- 추가: `test/review_fixes_test.dart` (위 수정 회귀 테스트 17개 — 앱 테마로 상세 그리기 포함)

### 2026-10-16 · 4d45ffa · BEAR\speed (v77 리메이크 × 261002 리팩토링 병합)
- 추가: v77 시안 기능 — 제안하기(LIVE 보드·상세·폼·전체·세계 제안 지도) `features/proposal`, 응모권·럭키드로우 `features/lucky`,
  커뮤니티 탭(우리 동네·여행·해외, 오늘의 질문, 피드 속 제안) `community/screens/community_view.dart`, 가는 김에 글 `features/trip`,
  중고장터·나눔 `features/market`, 현지 이웃 `overseas/widgets/local_neighbors.dart`, 여행 다트, `app/neighbor_store.dart` · `app/app_nav.dart`, `test/v77_test.dart`
- 변경: 하단 메뉴 홈 · 마켓 · 커뮤니티 · 채팅 · 마이 (`ShellTab.overseas` → 홈 맨 위 국내/해외 전환, `side`는 '마켓'으로 4칸).
  헤더 검색·연필 → 응모권 칩 · 글쓰기 · 알림 시트 (검색은 홈 '전체'로). `HeroCard`에 럭키드로우 말풍선(`bubble`),
  `AppSession.onTicket`(출석·미션·거래 완료·첫 부탁 → 응모권), `AppSession.addDelivery`(중고 전달 부탁), `TaskItem.extra`('used') 저장,
  `MeView`에 응모권 카드·내 제안 줄, 채팅 빈 화면 문구, v77 색 토큰 몇 개(`outline`·`greenDeep`·`liveBg` 등)
- 제거: `create_choice_screen.dart`(→ 글쓰기 시트), `going_board.dart`(→ 실제 '가는 김에' 글), 내 쪽 v77 1차본에서
  리팩토링과 겹치던 것 — 별도 홈(`features/home/`), 별도 마스코트·히어로, 별도 마켓·공동구매 데이터, 별도 마이·내역 화면,
  `kit.dart`의 카드·세그먼트·배지(→ `surface.dart` 공용 부품). 지어낸 숫자(커뮤니티 '이웃 312명', 히어로의 가짜 완료 소식)도 뺐다.
  LIVE 보드·커뮤니티 글은 체험용 예시라고 표시한다

### 2026-10-02 · 미커밋 · jyh (전체 리팩토링)
- 추가: `app/app_session.dart`(자료·저장·서버 동기화) · `app/session_store.dart` · `app/widgets/`(헤더·하단 메뉴·토스트·시작 화면),
  홈을 `errand/screens/home/`로 분리(부탁하기·돈벌기 탭, `HomeNav`, 조각 위젯), 부탁 쓰기를 `errand/screens/post/`로 분리(`RequestForm` + 단계 위젯),
  순수 로직 `errand/services/nearby_query.dart` · `benefits/services/mission_filter.dart`, `test/refactor_logic_test.dart`
- 변경: `home_shell.dart`는 화면 전환·로그인 확인만 담당. 미션·공구·마이·포인트샵·겸사페이·미션 실행기의 클래스를 파일별로 분리.
  `surface.dart`·`mascot.dart`는 묶음(export) 파일로. 동네 부탁 허브가 홈과 같은 조건 계산(`NearbyQuery`)·선택 상자를 쓰게 함.
  프로젝트 전체 `dart format`(줄 폭 130, `analysis_options.yaml`에 기록). 데이터·화면의 이모지를 선 아이콘 이름(`AppIcon`)으로 교체
- 제거: 안 쓰던 파일 7개(`news_card`·`wallet_summary`·`income_summary`·`news_detail_screen`·`job_guide_screen`·`home_news` 2개),
  `Country.flag`·`HomeAd.emoji/bg`(이모지 필드), 주석의 CSS 클래스·옛 시안 이름 괄호
- 남은 것: 주석 정리 2차(옛 시안·지난 작업 이야기 언급 약 120줄), `benefits_view`·`detail_page`·`job_post_screen` 분리, 기기에서 화면 확인

### 2026-10-02 · 미커밋 · jyh
- 추가: 포인트 관리 정리 — [백엔드_연결.md › 10. 포인트](백엔드_연결.md#10-포인트) (지금 구조·적립 키·빈틈 5가지·서버 이전 설계),
  WORKLOG에 '출시 준비'·'보류' 칸. 보류는 출시 후 · 조건부 · 아이디어로 나누고, docs에 흩어져 있던
  보류 항목(오퍼월·실제 충전/출금·걷기·친구 초대)과 v33에서 안 옮긴 시안 요소(응모권·출국 보드·가는 김에)를 모음
- 변경: 광고 보고 포인트 받기는 출시 후로 보류. 광고 붙이는 업데이트 때 할 일(광고 포함 표시·데이터 보안·AD_ID 권한) 기록

### 2026-10-02 · 미커밋 · jyh
- 추가: 미션·공구 › 미션 탭에 '광고 보고 포인트 받기' 카드 (카카오 애드핏 리워드 동영상, 하루 3번 · +5P).
  시청 전 안내 시트(보상 조건·지급·제외 사유, 애드핏 정책 5.3.3), `lib/core/ads/kakao_reward_ad.dart`,
  `lib/features/benefits/services/reward_ad_flow.dart`, `test/reward_ad_flow_test.dart`
- 변경: 광고 시청 미션의 제공사 AdMob → 카카오 애드핏 (`ADFIT_REWARD_ANDROID/IOS`). 매일 미션의 광고 항목도 같은 흐름·같은 하루 한도
- 제거: AdMob 리워드 연결(`admob` 제공사, `ADMOB_REWARDED_*` 키) — 광고 보상은 카카오만 쓰기로 함

### 2026-10-02 · 미커밋 · jyh
- 추가: v33 시안 디자인 적용 — 겸이 마스코트(`core/widgets/mascot.dart`), 공통 카드/탭 부품(`core/widgets/surface.dart`),
  해외 탭(`overseas_tab.dart`), 시작 화면(스플래시), 마이 화면 테스트(`test/me_view_test.dart`)
- 변경: 색 토큰 v33 팔레트, 하단 메뉴(부업→미션·공구, 해외 신설, 가운데 부탁하기 버튼 → 상단 연필),
  홈을 부탁하기/돈벌기 구조로, 미션·공구·채팅·마이 재구성, `PostRequest`에 `initialCat` 추가,
  `test/home_v9_test.dart` → `test/home_test.dart`
- 제거: 홈의 출석 달력(→ 마이 › 내역·출석), 겸사겸사 소식 카드(시안에 없음), 지갑 요약·가볍게 모으기(→ '전체' 시트 / 미션·공구),
  부업 탭의 '가볍게 시작해요'·파트너 안내 카드(→ '브랜드·가게 제휴 문의' 한 줄)
- 안 옮긴 시안 요소: 응모권·럭키드로우, 출국 이웃 보드, 예비금 30% (앱에 없는 기능·정책)

### 2026-09-23 · c5436dd · jyh
- 변경: 웹·데스크톱에서 마우스 드래그·트랙패드로 스크롤되게 (`main.dart`의 `dragDevices`)

### 2026-09-23 · b529b4a · jyh
- 변경: origin/main(260922 추가 개발) 병합

### 2026-09-23 · 05069e7 · jyh
- 추가: 일일 미션·퀴즈(`daily_missions`, `daily_quiz`, `mission_engine/runner/tracker`, `daily_mission_screen`),
  제휴 API 클라이언트(`core/net/` 쿠팡 파트너스·장소 검색), `api_keys.dart` + `secrets.example.json`, 관련 테스트
- 제거: `attend_streak` 위젯, `mission_row` 위젯 (일일 미션 행으로 대체)

### 2026-09-22 · 9f062c9 · BEAR\speed
- 추가: 시안 refined 적용 — 부업 탭(`side_job_view`), 출석 카드, 미션 상세 메타, 단기알바 모집 등록·상세,
  부탁 갈래 선택(`create_choice_screen`), 홈 소식(`news_card`), 브랜드 협업·제휴 제안 화면, 앱 아이콘 교체
- 제거: `attend_streak` 데이터/위젯 (출석 모델 `attendance`로 대체)

### 2026-09-17 · 7362b38 · BEAR\speed
- 추가: Pretendard 폰트, v9 디자인 시스템(`app_theme`, `app_icon`), Firebase 백엔드·계정별 DB(`user_repository`,
  `request_repository`, Firestore 규칙), 겸사페이(`pay/`), 신뢰 레벨, 동네 부탁 허브

### 2026-09-15 · 36dd0e6 · jyh
- 추가: 홈 v9, 단기알바(`dayjob/`), 회원 전용가(`deals/`), 누적 수익, 고지 문구(`disclosures`)
- 제거: 홈 옛 카드들 `featured/nearby/reco_card`, `together_row`, `trust_line` (v9 홈에서 미사용)

### 2026-08-25 ~ 2026-09-11 (요약)
- Flutter 이식 초기 커밋 → 코드 분리 → 로그인·Firebase → 리팩토링·폴더 구조 → Navigator 전환 →
  네이버 지도 → 안드로이드 가상버튼 대응 → 추가 업데이트·버그 수정 (ee21da7 ~ 441cd6d)
