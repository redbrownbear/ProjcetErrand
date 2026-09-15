/// 제휴 카테고리가 늘어나도 홈이 산만해지지 않게 잡는 2축 구조.
///
/// MOU·제휴 영업 전략 가이드 §15 그대로다.
/// 사용자는 '돈 벌기'와 '돈 아끼기' 두 목적만 이해하면 되고,
/// 늘어나는 제휴는 전부 2차 메뉴 아래로 들어간다.
class TrackMenu {
  /// 화면 필터 키
  final String key;

  /// 2차 메뉴 이름
  final String label;
  final String icon;

  /// 이 메뉴에 들어가는 제휴 (설명 문구로도 쓴다)
  final String includes;
  const TrackMenu(this.key, this.label, this.icon, this.includes);
}

/// 1차 메뉴: 오늘 벌기
class EarnTrack {
  static const title = '오늘 벌기';
  static const sub = '지금 할 수 있는 일과 참여';

  static const errand = TrackMenu('errand', '심부름', '🤝', '지역 픽업 · 개인/기업 심부름');
  static const reward = TrackMenu('reward', '참여·리워드', '📝', '설문 · 현장 서비스 점검 · 모델하우스 · 임상/연구');
  static const dayjob = TrackMenu('dayjob', '단기알바', '🎪', '공연/행사 · 전시 · 단기 · 프로젝트');
  static const mission = TrackMenu('mission', '간단 미션', '✨', '오퍼월 · 브랜드 미션');

  static const menus = [errand, reward, dayjob, mission];
}

/// 1차 메뉴: 생활비 아끼기
class SaveTrack {
  static const title = '생활비 아끼기';
  static const sub = '회원 전용가로 고정비 줄이기';

  static const deal = TrackMenu('deal', '겸사특가', '🏷️', '지역업체 · 프랜차이즈 · 공동구매');
  static const service = TrackMenu('service', '생활서비스', '🧺', '세탁 · 인쇄 · 렌탈 등 지역 생활서비스');
  static const finance = TrackMenu('finance', '금융 혜택', '💳', '카드 · 증권 등 규제 검토 후 제공');

  static const menus = [deal, service, finance];
}
