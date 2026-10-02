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
- 자세한 설계 근거는 `docs/`의 개별 문서에 두고, 여기서는 한 줄 + 링크만.

## 현재 상태

- Flutter 앱 `gyeomsa` — 동네 심부름·해외 사다주기·단기알바·미션/공동구매.
- 디자인 기준: **기획 시안 v33** ([v33_디자인_적용.md](v33_디자인_적용.md)).
  하단 메뉴 홈 · 미션·공구 · 해외 · 채팅 · 마이. 홈은 부탁하기/돈벌기 전환.
- 백엔드: Firebase(Auth·Firestore). 서버 연결이 안 되면 `LocalStore`(이 기기)에 저장 ([백엔드_연결.md](백엔드_연결.md)).
- 지도: 네이버 지도(`flutter_naver_map`). 제휴 미션·퀴즈 API 연동 ([제휴_API_연동.md](제휴_API_연동.md)).
- 원칙: 지어낸 숫자를 사실처럼 보여 주지 않는다(예시 데이터엔 '예시' 표시). 겸사페이(원)와 포인트(P)는 섞지 않는다.

## 다음 할 일

- [ ] v33 디자인 적용분 커밋 (아래 `미커밋` 항목)
- [ ] 로그인 상태의 마이 화면을 실제 기기에서 확인 (브라우저에선 로그아웃 상태만 확인함)
- [ ] 쓰이지 않게 된 위젯 정리 여부 결정 — `news_card.dart`, `wallet_summary.dart`, `income_summary.dart`

## 환경 메모

- (불곰 PC) pub 캐시가 `C:\src\pub-cache` (`PUB_CACHE` 사용자 환경변수). Android Studio가
  `AppData\Local\Pub\Cache`를 못 읽는 문제로 옮겼다. 경로가 다시 AppData로 보이면 환경변수가 풀린 것.
  바꾼 뒤엔 Android Studio를 완전히 종료 후 재시작.

## 기록

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
