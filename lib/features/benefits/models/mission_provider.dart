import '../../../core/config/api_keys.dart';

/// 포인트가 어디서 나오는지. 재원이 다르면 지급 방식과 한도도 달라진다.
enum ProviderKind {
  /// 우리 앱 안의 행동. 재원은 마케팅비라 단가를 우리가 정한다.
  inApp,

  /// 리워드 광고 — 영상 1회 재생당 광고 수익
  rewardAd,

  /// 오퍼월 — 제휴사 캠페인 묶음을 통째로 받아 온다
  offerwall,

  /// 제휴 마케팅(CPS/CPA) — 구매·가입이 일어나야 수수료가 생긴다
  affiliate,

  /// 공공·무료 오픈 API — 수익은 없고 미션 '내용'을 만든다
  openData,

  /// 리서치 패널 — 설문·좌담회 참여비
  survey,
}

/// 지금 이 제휴처를 실제로 쓸 수 있는 상태인지.
enum LinkStatus {
  /// 바로 동작한다 (키 불필요이거나 키가 들어와 있음)
  live,

  /// 코드는 다 붙었고 키만 넣으면 된다
  needsKey,

  /// 온라인 가입·심사가 필요하다 (개인도 신청 가능)
  needsApply,

  /// 사업자등록·계약이 있어야 열린다
  needsBiz,
}

/// 미션 공급원 한 곳.
///
/// 기존 [PartnerMission]이 "무엇을 하면 얼마"였다면, 이쪽은 "그 돈이 어디서
/// 나오고 지금 붙일 수 있느냐"를 들고 있다. MOU를 새로 맺어야 열리는 제휴와,
/// 오늘 가입 신청만 하면 열리는 오픈 API를 화면에서 구분해 보여주기 위해서다.
class MissionProvider {
  final String id;

  /// 실제 회사·서비스 이름
  final String name;
  final ProviderKind kind;
  final LinkStatus status;

  /// 한 줄 설명 — 미션 상세의 '공급' 줄에 쓴다
  final String note;

  /// 필요한 dart-define 키 이름들. 비어 있으면 키 없이 동작한다.
  final List<String> keys;

  /// 발급·가입 페이지
  final String docUrl;

  /// 정산 방식 (우리가 제휴처에서 돈을 받는 기준)
  final String settle;

  /// 우리 서버 프록시([ApiKeys.proxyBase])로도 부를 수 있는 API인지.
  /// true면 앱에 키를 안 넣어도 프록시만 있으면 동작한다.
  final bool proxyable;

  const MissionProvider({
    required this.id,
    required this.name,
    required this.kind,
    required this.status,
    required this.note,
    required this.docUrl,
    required this.settle,
    this.keys = const [],
    this.proxyable = false,
  });

  /// 키가 실제로 들어왔는지까지 본 최종 상태.
  /// [status]가 needsKey여도 dart-define이 채워졌으면 live로 올라간다.
  LinkStatus get effective {
    if (status != LinkStatus.needsKey) return status;
    if (proxyable && ApiKeys.hasProxy) return LinkStatus.live;
    return ApiKeys.filled([for (final k in keys) _value(k)]) ? LinkStatus.live : LinkStatus.needsKey;
  }

  bool get usable => effective == LinkStatus.live;

  String get statusLabel => switch (effective) {
        LinkStatus.live => '연동 완료',
        LinkStatus.needsKey => 'API 키 등록 필요',
        LinkStatus.needsApply => '제휴 가입 신청 필요',
        LinkStatus.needsBiz => '사업자 계약 필요',
      };

  String get kindLabel => switch (kind) {
        ProviderKind.inApp => '자체',
        ProviderKind.rewardAd => '리워드 광고',
        ProviderKind.offerwall => '오퍼월',
        ProviderKind.affiliate => '제휴 마케팅',
        ProviderKind.openData => '공공 오픈API',
        ProviderKind.survey => '리서치 패널',
      };

  /// dart-define 이름을 실제 값으로. [ApiKeys]가 컴파일 상수라 표로 잇는다.
  static String _value(String key) => switch (key) {
        'NAVER_SEARCH_ID' => ApiKeys.naverSearchId,
        'NAVER_SEARCH_SECRET' => ApiKeys.naverSearchSecret,
        'KAKAO_REST_KEY' => ApiKeys.kakaoRest,
        'COUPANG_ACCESS_KEY' => ApiKeys.coupangAccess,
        'COUPANG_SECRET_KEY' => ApiKeys.coupangSecret,
        'ADMOB_REWARDED_ANDROID' => ApiKeys.admobRewardedAndroid,
        'ADMOB_REWARDED_IOS' => ApiKeys.admobRewardedIos,
        'OFFERWALL_APP_KEY' => ApiKeys.offerwallAppKey,
        _ => '',
      };
}
