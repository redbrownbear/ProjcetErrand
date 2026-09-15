/// 생활비 아끼기 > 회원 전용가 상품.
///
/// MOU·제휴 영업 전략 가이드 §10을 코드로 옮긴 것.
/// 핵심은 "최저가를 약속하지 않고, 회원 전용가와 비교 기준가를 투명하게 같이 보여준다"는 것이라
/// 기준가([basePrice])와 그 근거([baseSource])를 회원가와 함께 필수로 받는다.
class MemberDeal {
  final String id;
  final String icon;
  final String brand;
  final String title;

  /// 2차 메뉴 키 — deal(겸사특가) | service(생활서비스) | finance(금융 혜택)
  final String menu;

  /// 세부 유형 — 지역업체 | 프랜차이즈 | 공동구매 | 생활서비스 | 금융
  final String kind;

  /// 비교 기준가와 그 출처. 출처 없는 기준가는 표시하지 않는다.
  final int basePrice;
  final String baseSource;

  /// 겸사겸사 회원 전용가
  final int memberPrice;

  /// 이 특가가 어떻게 만들어졌는지 (§10의 5가지 중 하나). 사용자에게 그대로 노출한다.
  final String howMade;

  /// 지역·이용 조건
  final String area;
  final String cond;

  /// 규제 검토가 필요한 메뉴(금융 등)에서 쓸 고지 키. [Disclosures]의 키.
  final String disclosureKey;

  const MemberDeal({
    required this.id,
    required this.icon,
    required this.brand,
    required this.title,
    required this.menu,
    required this.kind,
    required this.basePrice,
    required this.baseSource,
    required this.memberPrice,
    required this.howMade,
    required this.area,
    required this.cond,
    this.disclosureKey = 'pricing',
  });

  int get save => basePrice - memberPrice;
  int get percent => basePrice <= 0 ? 0 : (save * 100 / basePrice).round();

  /// 금액이 아니라 혜택(무료 체험·캐시백 등)으로 표현되는 건
  bool get isPriced => basePrice > 0 && memberPrice > 0;
}
