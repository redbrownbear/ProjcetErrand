/// 홈 상단 '겸사겸사 소식' 한 장. 시안(`gyumsa-refined`)의 `g4News`.
///
/// 서비스 업데이트·새 기능 안내와, 같은 자리를 쓰는 브랜드 광고 지면을 함께 담는다.
/// 광고 카드([isAd])는 '광고' 표시를 달고 브랜드 협업 안내로 간다.
class HomeNews {
  final String id;

  /// 카드 오른쪽 위 꼬리표 (업데이트 · 새로운 기능 · 광고 · 예시)
  final String tag;
  final String title;
  final String body;

  /// 카드 아래 행동 문구
  final String action;
  final String icon;
  final NewsTone tone;

  /// 상세에서 읽을 내용. 광고 카드는 상세 대신 브랜드 협업 안내로 간다.
  final String? lead;
  final List<({String title, String body})> sections;

  const HomeNews({
    required this.id,
    required this.tag,
    required this.title,
    required this.body,
    required this.action,
    required this.icon,
    required this.tone,
    this.lead,
    this.sections = const [],
  });

  bool get isAd => id == 'ad';
}

enum NewsTone { blue, peach, mint }
