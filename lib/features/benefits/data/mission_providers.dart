import '../models/mission_provider.dart';

/// 실제 존재하는 미션 공급원 목록.
///
/// 지금까지 미션 데이터는 'OO 앱', 'OTT' 같은 가상 브랜드였다. 그건 MOU를
/// 맺어야 채워지는 자리라 개발 중에는 아무것도 눌러볼 수 없다.
/// 여기 있는 곳들은 **계약 없이 온라인 가입만으로 열리는 공개 API·제휴 프로그램**이라
/// 키만 발급받으면 오늘 바로 붙는다. 각 항목의 [MissionProvider.status]가
/// 지금 무엇이 막혀 있는지를 말해 준다.
const missionProviders = <MissionProvider>[
  // ── 우리 앱 안에서 끝나는 것. 키도 계약도 없다 ─────────────────────────
  MissionProvider(
    id: 'inapp',
    name: '겸사겸사',
    kind: ProviderKind.inApp,
    status: LinkStatus.live,
    note: '앱 안의 행동으로 바로 확인되는 미션',
    docUrl: '',
    settle: '자체 마케팅 예산',
  ),

  // ── 지도. 가입 즉시 무료 키 ────────────────────────────────────────────
  MissionProvider(
    id: 'kakao_local',
    name: '카카오 로컬 API',
    kind: ProviderKind.openData,
    status: LinkStatus.needsKey,
    note: '내 좌표 반경 안의 실제 매장을 찾아 체크인을 검증한다',
    keys: ['KAKAO_REST_KEY'],
    docUrl: 'https://developers.kakao.com/docs/latest/ko/local/dev-guide',
    settle: '무료 (일 할당량 있음)',
    proxyable: true,
  ),
  MissionProvider(
    id: 'naver_search',
    name: '네이버 검색 API (지역)',
    kind: ProviderKind.openData,
    status: LinkStatus.needsKey,
    note: '가게 이름으로 실재 여부와 주소를 확인한다',
    keys: ['NAVER_SEARCH_ID', 'NAVER_SEARCH_SECRET'],
    docUrl: 'https://developers.naver.com/docs/serviceapi/search/local/local.md',
    settle: '무료 (일 25,000회)',
    proxyable: true,
  ),

  // ── 실제 수익이 생기는 곳 ──────────────────────────────────────────────
  MissionProvider(
    id: 'coupang',
    name: '쿠팡 파트너스',
    kind: ProviderKind.affiliate,
    status: LinkStatus.needsKey,
    note: '골드박스 특가를 가져오고, 링크로 구매가 일어나면 수수료가 생긴다',
    keys: ['COUPANG_ACCESS_KEY', 'COUPANG_SECRET_KEY'],
    docUrl: 'https://partners.coupang.com/',
    settle: 'CPS — 구매 확정 금액의 일정 비율, 익익월 정산',
    proxyable: true,
  ),
  MissionProvider(
    id: 'admob',
    name: 'Google AdMob 리워드 광고',
    kind: ProviderKind.rewardAd,
    status: LinkStatus.needsKey,
    note: '영상 한 편을 끝까지 보면 광고 수익이 생기고 그중 일부를 포인트로 준다',
    keys: ['ADMOB_REWARDED_ANDROID'],
    docUrl: 'https://developers.google.com/admob/flutter/rewarded',
    settle: 'eCPM 기준 노출·시청 수익, 월 정산',
  ),
  MissionProvider(
    id: 'adpick',
    name: '애드픽 (ADPICK)',
    kind: ProviderKind.affiliate,
    status: LinkStatus.needsApply,
    note: '앱 설치·가입 CPA 캠페인. 개인도 가입할 수 있어 초기 물량을 채우기 좋다',
    docUrl: 'https://adpick.co.kr/',
    settle: 'CPA — 설치·가입 건당, 익월 정산',
  ),
  MissionProvider(
    id: 'linkprice',
    name: '링크프라이스',
    kind: ProviderKind.affiliate,
    status: LinkStatus.needsApply,
    note: '국내 쇼핑몰 CPS 제휴를 한 번에 묶어 받는다',
    docUrl: 'https://www.linkprice.com/',
    settle: 'CPS — 구매액 비율, 월 정산',
  ),
  MissionProvider(
    id: 'adpopcorn',
    name: '애드팝콘 오퍼월',
    kind: ProviderKind.offerwall,
    status: LinkStatus.needsBiz,
    note: '캠페인 수십 개를 통째로 받는 오퍼월. 사업자등록과 계약이 필요하다',
    keys: ['OFFERWALL_APP_KEY'],
    docUrl: 'https://www.adpopcorn.com/',
    settle: '캠페인별 단가 — 사업자 계약 기준 월 정산',
  ),
  MissionProvider(
    id: 'buzzvil',
    name: '버즈빌 오퍼월',
    kind: ProviderKind.offerwall,
    status: LinkStatus.needsBiz,
    note: '포인트 적립형 광고 SDK. 애드팝콘과 같은 자리라 한 곳만 골라 붙인다',
    keys: ['OFFERWALL_APP_KEY'],
    docUrl: 'https://www.buzzvil.com/',
    settle: '캠페인별 단가 — 사업자 계약 기준 월 정산',
  ),
  MissionProvider(
    id: 'embrain',
    name: '엠브레인 패널파워',
    kind: ProviderKind.survey,
    status: LinkStatus.needsBiz,
    note: '설문·좌담회 패널 모집. 지금은 링크 송출만 하고 참여비는 패널사가 준다',
    docUrl: 'https://www.panel.co.kr/',
    settle: '참여비는 리서치사 지급 · 우리는 모집 대가',
  ),
];

MissionProvider providerOf(String id) =>
    missionProviders.firstWhere((p) => p.id == id, orElse: () => missionProviders.first);

/// 지금 당장 쓸 수 있는 공급원 (키가 들어와 있거나 키가 필요 없는 것)
List<MissionProvider> get liveProviders => missionProviders.where((p) => p.usable).toList();
