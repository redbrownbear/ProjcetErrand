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

  /// 카카오 로그인 — 카카오 디벨로퍼스 네이티브 앱 키. 안드로이드 매니페스트의 `kakao{키}://oauth`도 이 값으로 만든다
  static const kakaoNative = String.fromEnvironment('KAKAO_NATIVE_KEY');

  /// 네이버 로그인 — 네이버 개발자센터 애플리케이션(네이버 로그인)의 Client ID.
  /// Client Secret(`NAVER_LOGIN_SECRET`)은 안드로이드 매니페스트로만 들어간다(네이버 SDK가 앱에 두도록 설계됨).
  /// 검색 API(`NAVER_SEARCH_ID`)와는 다른 애플리케이션이어도 된다
  static const naverLoginId = String.fromEnvironment('NAVER_LOGIN_ID');

  /// 쿠팡 파트너스 Open API (HMAC 서명)
  static const coupangAccess = String.fromEnvironment('COUPANG_ACCESS_KEY');
  static const coupangSecret = String.fromEnvironment('COUPANG_SECRET_KEY');

  /// 카카오 애드핏 리워드 동영상 광고단위 ID (`DAN-…`). 플랫폼마다 따로 발급된다.
  /// 광고 보고 포인트 받기는 카카오 광고만 쓴다.
  static const adfitRewardAndroid = String.fromEnvironment('ADFIT_REWARD_ANDROID');
  static const adfitRewardIos = String.fromEnvironment('ADFIT_REWARD_IOS');

  /// 오퍼월 (애드팝콘 / 버즈빌 / Tnk) — 사업자 등록 후 발급
  static const offerwallAppKey = String.fromEnvironment('OFFERWALL_APP_KEY');

  static bool get hasProxy => proxyBase.isNotEmpty;

  /// 해당 키들이 모두 채워졌는지. 하나라도 비면 미션을 '준비 중'으로 그린다.
  static bool filled(List<String> values) => values.every((v) => v.isNotEmpty);
}
