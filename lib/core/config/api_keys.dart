/// 외부 제휴 API 키. 소스에 값을 적지 않고 빌드할 때 `--dart-define`으로 넣는다.
///
/// ```bash
/// flutter run --dart-define-from-file=secrets.json
/// ```
///
/// 키가 안 들어온 제휴는 미션 목록에서 '연동 준비 중'으로 보인다([MissionProvider]).
/// 앱을 고치지 않고 키만 넣으면 그 미션이 바로 살아나는 구조다.
///
/// ## 앱에 직접 넣으면 안 되는 키
/// 네이버 검색 secret과 쿠팡 파트너스 secret은 서버용이다. APK를 뜯으면 그대로
/// 나오므로 운영 빌드에서는 [proxyBase]에 우리 서버(Firebase Functions 등)를 넣고
/// 앱은 프록시만 부른다. dart-define으로 직접 넣는 경로는 개발·검증용으로만 둔다.
class ApiKeys {
  /// 우리 서버 프록시 주소. 예: https://asia-northeast3-xxx.cloudfunctions.net/api
  /// 값이 있으면 secret이 필요한 API는 전부 이쪽으로 나간다.
  static const proxyBase = String.fromEnvironment('PROXY_BASE');

  /// 네이버 개발자센터 — 검색 API(지역)
  static const naverSearchId = String.fromEnvironment('NAVER_SEARCH_ID');
  static const naverSearchSecret = String.fromEnvironment('NAVER_SEARCH_SECRET');

  /// 카카오 디벨로퍼스 REST API 키 — 로컬(장소) API
  static const kakaoRest = String.fromEnvironment('KAKAO_REST_KEY');

  /// 쿠팡 파트너스 Open API (HMAC 서명)
  static const coupangAccess = String.fromEnvironment('COUPANG_ACCESS_KEY');
  static const coupangSecret = String.fromEnvironment('COUPANG_SECRET_KEY');

  /// 구글 애드몹 리워드 광고 단위 (google_mobile_ads 추가 후 사용)
  static const admobRewardedAndroid = String.fromEnvironment('ADMOB_REWARDED_ANDROID');
  static const admobRewardedIos = String.fromEnvironment('ADMOB_REWARDED_IOS');

  /// 오퍼월 (애드팝콘 / 버즈빌 / Tnk) — 사업자 등록 후 발급
  static const offerwallAppKey = String.fromEnvironment('OFFERWALL_APP_KEY');

  static bool get hasProxy => proxyBase.isNotEmpty;

  /// 해당 키들이 모두 채워졌는지. 하나라도 비면 미션을 '준비 중'으로 그린다.
  static bool filled(List<String> values) => values.every((v) => v.isNotEmpty);
}
