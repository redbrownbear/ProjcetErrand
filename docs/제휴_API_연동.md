# 제휴 API 연동 — 무엇을 받아야 열리는가

'가볍게 모으기'의 미션은 더 이상 가상 브랜드가 아니다. 전부 **실제 회사의 공개
API·제휴 프로그램**에 연결돼 있고, 코드는 이미 붙어 있다. 남은 건 키를 받는 일뿐이다.

키는 소스에 적지 않고 빌드할 때 넣는다.

```bash
cp secrets.example.json secrets.json   # 값 채우기
flutter run --dart-define-from-file=secrets.json
```

키가 없는 미션은 목록에서 사라지지 않고 **'준비 중'으로 흐리게** 남는다.
`lib/features/benefits/data/mission_providers.dart`의 `LinkStatus`가 그 판정을 한다.
앱 화면 아래쪽 '이 포인트는 어디서 오나요?'에서 지금 상태를 바로 볼 수 있다.

---

## 0. 재원 없는 미션은 내려 뒀다

`dailyMissions`에는 **제휴사가 돈을 대는 미션만** 둔다. 출석·퀴즈·걷기처럼 우리
마케팅비로만 나가는 미션은 사람이 늘수록 손실이 정비례로 커져서, `parkedMissions`로
내려 두고 재원이 생기면 올린다. 되살릴 조건은 그 목록 주석에 적어 뒀다.

단가는 감이 아니라 **재원에서 역산한다.** `PointRules`의 각 상수 위에 얼마가
들어오는지를 같이 적어 뒀으니, 요율이 바뀌면 숫자만 고치지 말고 식부터 다시 본다.

| 서비스 중인 미션 | 재원 | 지급 |
|---|---|---|
| 광고 영상 (하루 3회) | AdMob 리워드 · 1회 11~21원 | 정액 5P (최악 eCPM에서도 45%) |
| 오늘의 특가로 주문 | 쿠팡 파트너스 · 주문액 1~3% | **주문액의 1%** (정률) |
| 오퍼월 | 제휴사 캠페인 단가 | 단가 × 0.65 (제휴사가 정함) |

쿠팡을 정액으로 주면 안 된다. 3% 기준 본전이 8만원어치라, 1만원짜리를 사고 정액을
받아 가면 건당 적자가 난다. 그래서 `PayoutKind.rate`로 두고 화면에도 숫자 대신
'주문액의 1%'라고 적는다.

**광고 말고는 눌러도 그 자리에서 적립되지 않는다** (`DailyMission.instant`).
쿠팡은 구매 확정, 오퍼월은 제휴사 콜백을 서버가 받은 뒤에 지급된다.

## 1. 지금 바로 받을 수 있는 것 (무료 · 가입 즉시)

둘 다 계정만 만들면 5분 안에 키가 나온다. **사업자등록은 필요 없다.**

| # | 받을 곳 | 넣을 키 | 무엇에 쓰나 |
|---|---------|---------|-----------|
| 1 | [카카오 디벨로퍼스 — 로컬 API](https://developers.kakao.com/docs/latest/ko/local/dev-guide) | `KAKAO_REST_KEY` | **내 좌표 반경 검색** — GPS 체크인 검증 |
| 2 | [네이버 개발자센터 — 검색(지역)](https://developers.naver.com/docs/serviceapi/search/local/local.md) | `NAVER_SEARCH_ID`, `NAVER_SEARCH_SECRET` | **키워드로 가게 확인** — 이름·주소·업종 |

**받는 순서**

1. **카카오**: 카카오 계정으로 로그인 → 내 애플리케이션 > 애플리케이션 추가하기 →
   앱 키 탭의 **REST API 키** 복사. `로컬`은 따로 신청할 필요 없이 바로 된다.
2. **네이버**: 네이버 계정으로 로그인 → Application > 애플리케이션 등록 →
   사용 API에서 **검색** 체크 → Client ID / Client Secret 복사.
   하루 25,000회까지 무료다.

**둘 중 무엇을 쓸지는 목적이 정한다.** 카카오만 반경(m) 검색이 되고 거리를 돌려준다.
네이버 지역검색은 좌표 반경 조건이 없고 한 번에 최대 5건이라, "이 가게가 실재하는가"를
확인하는 용도다. 체크인처럼 **그 앞에 서 있어야 하는** 검증은 카카오만 가능하다.

> 공공데이터포털(기상청·에어코리아)은 쓰지 않기로 해서 코드와 키를 모두 제거했다.

> 네이버 Secret은 원래 서버용 값이다. 스토어에 올리는 빌드에는 넣지 말고
> 아래 '서버 프록시' 절로 우회한다. 개발·검증 빌드에서만 직접 넣는다.

## 2. 심사가 있는 것 (실제 수익이 생기는 쪽)

포인트를 나눠 줄 재원이 여기서 나온다. 신청부터 승인까지 며칠 걸린다.

| # | 받을 곳 | 넣을 키 | 성격 |
|---|---------|---------|------|
| 5 | [쿠팡 파트너스](https://partners.coupang.com/) | `COUPANG_ACCESS_KEY`, `COUPANG_SECRET_KEY` | CPS — 구매 확정 금액의 일정 비율 |
| 6 | [Google AdMob](https://admob.google.com/) | `ADMOB_REWARDED_ANDROID`, `ADMOB_REWARDED_IOS` | 리워드 영상 시청 수익 |
| 7 | [애드픽](https://adpick.co.kr/) | (링크만 사용) | CPA — 설치·가입 건당. 개인도 가입 가능 |
| 8 | [링크프라이스](https://www.linkprice.com/) | (링크만 사용) | CPS — 국내 쇼핑몰 묶음 |

**쿠팡 파트너스** — 가입 후 심사를 통과하면 '내 정보 > Open API 키 발급'에서
Access/Secret이 나온다. 호출은 HMAC-SHA256 서명 방식이고, 서명 코드는
`lib/core/net/coupang_partners_api.dart`에 이미 있다.

**AdMob** — 앱을 등록하고 **리워드형** 광고 단위를 만들면
`ca-app-pub-…/…` 형태의 단위 ID가 나온다. 이건 키만으로는 안 되고
아래 '내가 더 필요한 것'의 패키지 추가가 함께 필요하다.

## 3. 사업자등록이 있어야 열리는 것

| # | 받을 곳 | 넣을 키 | 왜 막혀 있나 |
|---|---------|---------|---------------|
| 9 | [애드팝콘](https://www.adpopcorn.com/) 또는 [버즈빌](https://www.buzzvil.com/) | `OFFERWALL_APP_KEY` | 오퍼월은 매체사 계약이 필요하다 |
| 10 | [엠브레인 패널파워](https://www.panel.co.kr/) | — | 리서치 패널 모집 제휴 |

오퍼월 하나를 붙이면 캠페인 수십 개가 한 번에 들어온다. 초기에는 애드픽·링크프라이스
같은 개인 가입 가능한 CPA로 물량을 채우고, 사업자 준비가 끝나면 오퍼월로 갈아탄다.

### 오퍼월은 목록을 우리가 못 만든다

캠페인 목록·단가·노출 대상을 전부 제휴사가 정하고, **화면도 제휴사 SDK가 통째로
그린다.** 광고주 예산이 소진되면 캠페인이 사라지고, 이미 설치한 앱은 그 유저에게
노출되지 않고, 지역·OS·시간대별로 목록이 갈린다. 그래서 우리 쪽은 '오퍼월 열기'
버튼 하나가 전부다 (`MissionAction.offerwall`).

적립도 앱이 하지 않는다. **제휴사 서버 → 우리 서버 콜백(postback)**으로 들어온다.
오퍼월을 붙이려면 SDK만으로 안 되고 수신 엔드포인트가 함께 있어야 한다.

```
functions/
  rewards/
    offerwallPostback   제휴사 콜백 수신 → 서명 검증 → 원장 적립
```

세 가지를 반드시 지킨다.

- **서명 검증** — 콜백 URL을 알면 누구나 부를 수 있다. 제휴사가 주는 시크릿으로 해시를 맞춰 본다
- **멱등** — 같은 콜백이 여러 번 온다. 제휴사 트랜잭션 id를 문서 id로 써서 한 번만 적립한다
- **취소 콜백** — 어뷰징으로 판정되면 회수 콜백이 온다. 차감도 원장에 남긴다

쿠팡도 같은 이유로 서버가 필요하다. 구매 확정은 익월 25일 리포트에 올라오므로,
정산 리포트를 읽어 적립하는 배치가 있어야 한다. 앱은 주문 여부를 알 수 없다.

---

## 서버 프록시 (운영 빌드에 필요)

네이버 Secret과 쿠팡 Secret은 **앱에 넣으면 안 된다.** APK에서 문자열만 뽑아도
그대로 보이고, 새면 남이 우리 계정으로 API를 쓴다.

운영 빌드에서는 `PROXY_BASE`에 우리 서버 주소를 넣는다. 그러면 앱은 키 없이
프록시만 부르고, 서명·인증은 서버가 한다.

```
PROXY_BASE = https://asia-northeast3-<project>.cloudfunctions.net/api
```

프록시가 있어야 하는 경로 세 개:

| 앱이 부르는 곳 | 서버가 대신 할 일 |
|----------------|--------------------|
| `GET {PROXY_BASE}/kakao/local` | `Authorization: KakaoAK` 붙여 카카오로 중계 |
| `GET {PROXY_BASE}/naver/local` | Client ID/Secret 헤더 붙여 네이버로 중계 |
| `GET {PROXY_BASE}/coupang/goldbox` | HMAC 서명 만들어 쿠팡으로 중계 |

셋 다 쿼리는 그대로 넘기고 응답도 그대로 돌려주면 된다
(`lib/core/net/` 각 클라이언트의 파싱 코드가 원본 응답 형식을 그대로 읽는다).
Firebase 프로젝트는 이미 있으므로 Cloud Functions에 얹는 게 가장 빠르다.

---

## 내가(개발) 더 필요한 것

키 말고, 결정이나 추가 작업이 필요한 것들이다.

1. **리워드 광고를 실제로 붙일지** — 붙이려면 `google_mobile_ads` 패키지를 추가하고
   Android `AndroidManifest.xml`·iOS `Info.plist`에 AdMob 앱 ID를 넣어야 한다.
   앱 ID가 없으면 **앱이 시작하자마자 죽으므로**, AdMob 계정을 만든 뒤에 붙인다.
   지금은 미션 자리와 적립 처리(`MissionAction.rewardAd`)까지만 만들어 뒀다.

   ⚠️ **먼저 확인할 것**: [AdMob 리워드 광고 정책](https://support.google.com/admob/answer/7313578?hl=ko)은
   현금·암호화폐·**기프트카드 보상을 금지**하고, 보상이 앱 안에서만 쓰이고 양도·현금
   전환이 안 될 것을 요구한다. `광고 시청 → 포인트 → 스타벅스 기프티콘`은 이 문구에
   걸릴 소지가 있다. 셋 중 하나를 골라야 한다.
   1. 광고로 받은 포인트는 **앱 내 소비(수수료 할인)로만** 쓰게 분리
   2. 리워드 광고 대신 **오퍼월**을 쓴다 (기프티콘 교환을 전제로 설계된 쪽이다)
   3. 광고 재원은 배너·전면으로 받고, 포인트는 광고 시청과 끊어서 지급
2. **걷기를 되살릴지** — 걷기 적립은 재원이 없어 **화면에서만 내렸다.**
   `WalkScreen`·`walkClaimable`·`parkedMissions`의 걷기 미션·`parkedAds`의 배너가
   그대로 남아 있어서, 재원이 생기면 홈의 진입점 하나만 되살리면 된다.
   실제로 걸음을 세려면 Android는 Health Connect, iOS는 HealthKit 권한과
   `health` 패키지가 추가로 필요하다 (지금은 고정값 6,430보).
3. **초대 코드** — 친구 초대는 지금 링크 복사까지만 한다. 누가 누구를 데려왔는지는
   서버가 코드를 발급하고 가입 시 확인해야 실제 지급으로 이어진다.
4. **포인트 단가 재측정** — `lib/features/benefits/data/point_rules.dart`에 모아 뒀다.
   지금 값은 밴드 하단으로 잡은 보수적인 추정치다. AdMob eCPM을 3개월 실측한 뒤
   `adRevenueLow × adShare`로 다시 뽑는다. **낮게 시작해 올리는 방향으로만 간다** —
   내리는 건 약관 근거가 있어도 불만이 남는다.

5. **포인트 약관** — 유효기간(관행 180일)·소멸·단가 변경 권한을 약관에 명시해야
   나중에 단가를 조정할 근거가 생긴다. 기프티콘 교환을 열기 전에 필요하다.

6. **적립을 서버로 옮기기** — 지금은 앱이 포인트를 계산해 Firestore에 직접 쓴다.
   포인트가 기프티콘으로 바뀌는 순간 현금과 같아지므로, 겸사페이보다 **먼저**
   Cloud Functions로 옮겨야 한다.
7. **부업 탭에 미션 목록 붙이기** — 부업 탭이 `benefit:*` 키로 따로 굴리던 옛 미션
   목록(출석·광고·프로필·친구초대)은 전부 걷어냈다. 그 자리에 새 `MissionEngine`
   기반 목록을 넣으려면 `MissionRunner`를 연결해야 한다(걷기·프로필·부탁 올리기
   이동 콜백이 필요). 지금 데일리 미션은 홈 '가볍게 모으기'에서만 보인다.

---

## 코드에서 찾아볼 곳

| 무엇 | 파일 |
|------|------|
| 키 정의 | `lib/core/config/api_keys.dart` |
| API 호출 | `lib/core/net/` (`place_api` · `coupang_partners_api`) |
| 공급원 목록·연동 상태 | `lib/features/benefits/data/mission_providers.dart` |
| 미션 목록 · 보류 목록 | `lib/features/benefits/data/daily_missions.dart` |
| 단가와 재원 역산 | `lib/features/benefits/data/point_rules.dart` |
| 상태 계산 (테스트 대상) | `lib/features/benefits/services/mission_engine.dart` |
| 실행·API 호출·시트 | `lib/features/benefits/services/mission_runner.dart` |
| 화면 | `lib/features/benefits/screens/daily_mission_screen.dart` |
| 진행도 수집 | `lib/features/benefits/services/mission_tracker.dart` |
