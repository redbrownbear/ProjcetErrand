/// 제휴 성과보상 미션.
///
/// MOU·제휴 영업 전략 가이드를 반영해 세 가지를 더 들고 있는다.
/// - [group] : §15의 2차 메뉴(참여·리워드 / 간단 미션). 제휴가 늘어도 홈이 산만해지지 않게 하는 축.
/// - [verify]·[payout] : §3·§4가 요구한 "완료를 무엇으로 인정하고 언제 주는지"의 객관적 기준.
/// - [disclosureKey] : §19의 규제 영역별 필수 고지. [Disclosures]의 키를 쓴다.
class PartnerMission {
  final String id, cat, brand, icon, title, desc, time, cond, reason;
  final int points;

  /// §15 2차 메뉴 — reward(참여·리워드) | mission(간단 미션)
  final String group;

  /// 완료 인정 방식 (예: 현장 QR 체크인, 상담사 완료 처리, 확인코드 입력)
  final String verify;

  /// 지급 시점 (예: 즉시, 제휴사 검수 후 7일 내, 익월 정산)
  final String payout;

  /// 규제 고지 키 — partner | insurance | clinical | research | realEstate | finance
  final String disclosureKey;

  const PartnerMission({
    required this.id,
    required this.cat,
    required this.brand,
    required this.icon,
    required this.title,
    required this.desc,
    required this.points,
    required this.time,
    required this.cond,
    required this.reason,
    this.group = 'mission',
    this.verify = '앱에서 자동 확인',
    this.payout = '조건 충족 시 자동 적립',
    this.disclosureKey = 'partner',
  });
}
