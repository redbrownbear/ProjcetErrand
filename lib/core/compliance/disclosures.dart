/// 제휴 카테고리별 필수 고지 문구.
///
/// MOU·제휴 영업 전략 가이드 §19(규제·신뢰 측면에서 법률검토가 필요한 영역)에 따라,
/// 화면마다 문구를 따로 쓰지 않고 여기 한 곳에서만 관리한다.
/// 제휴사 준법부서가 승인한 문구로 바뀌면 이 파일만 고치면 된다.
class Disclosure {
  /// 화면 상단 배지에 쓰는 짧은 라벨 (예: 광고·제휴)
  final String label;

  /// 참여 전 반드시 보여줘야 하는 본문
  final String body;
  const Disclosure(this.label, this.body);
}

class Disclosures {
  /// 모든 제휴 캠페인 공통 — 광고임을 명확히 표시 (§4 파일럿 원칙)
  static const partner = Disclosure(
    '광고·제휴',
    '제휴사가 비용을 부담하는 광고·제휴 캠페인이에요. 지급 조건과 시점은 제휴사 정책에 따라 달라질 수 있어요.',
  );

  /// 보험 (§4) — 겸사겸사가 모집 주체로 보이지 않게 한다
  static const insurance = Disclosure(
    '보험 · 준법확인 필요',
    '제휴 GA·보험사의 준법감시 확인을 거친 캠페인만 노출돼요. 겸사겸사는 보험을 모집하거나 추천하지 않으며, 리워드는 적법한 범위의 상담·설명 완료 기준으로만 지급돼요. 실제 가입 여부는 리워드 조건이 아니에요.',
  );

  /// 임상시험 (§5) — 승인된 모집정보 전달만 한다
  static const clinical = Disclosure(
    '임상시험 참여정보',
    '제휴 기관이 승인한 참여자 모집 정보를 그대로 전달해요. 겸사겸사는 시험 내용을 임의로 바꾸거나 참여를 권유하지 않고, 신청과 상담은 공식 모집처에서 진행돼요. 시험 목적·조건·위험·보상은 승인본 안내를 확인하세요.',
  );

  /// 대학 연구실·연구소 (§14)
  static const research = Disclosure(
    '연구 참여 기회',
    '연구책임자가 승인한 모집 문구와 참여 조건을 그대로 표시해요. IRB 승인이 필요한 연구는 승인본만 노출되며, 앱이 연구 내용을 수정하지 않아요.',
  );

  /// 모델하우스·분양 (§3) — 방문 성과와 중개 성과를 분리한다
  static const realEstate = Disclosure(
    '분양 홍보 · 방문 캠페인',
    '제휴사가 승인한 홍보물을 노출하고, 리워드는 예약·방문 인증 완료 기준으로 지급돼요. 분양 계약 성사와는 무관하며 겸사겸사는 중개를 하지 않아요.',
  );

  /// 카드·증권 등 금융 (§12)
  static const finance = Disclosure(
    '금융 제휴 프로모션',
    '금융사 또는 정식 제휴 마케팅 사업자의 승인된 프로모션이에요. 겸사겸사는 금융상품을 비교·추천하는 금융자문을 하지 않고, 리워드 조건과 문구는 제휴사 준법감시 확인을 거쳐요.',
  );

  /// 일급·일당, 행사 스태프 (§6, §11) — 직업소개·파견 성격 구분
  static const labor = Disclosure(
    '구인 정보 · 근로계약 별도',
    '겸사겸사는 구인 정보를 게시하고 연결하는 역할이에요. 근로계약·임금 지급·현장 지휘는 구인업체와 직접 이뤄지며, 지급일과 조건은 공고 기준을 따라요.',
  );

  /// 회원 전용가 (§10) — '최저가'를 약속하지 않는다
  static const pricing = Disclosure(
    '회원 전용가',
    '최저가를 보장하는 가격이 아니라 제휴로 만든 겸사겸사 회원 전용가예요. 비교 기준가는 판매처 정상가를 그대로 표시해요.',
  );

  /// 기업 심부름 (§7) — 검증 수행자 B2B
  static const b2b = Disclosure(
    '기업 심부름 · 검증 수행자',
    '기업 업무는 개인 미션을 일정 횟수 이상 완료하고 평점 기준을 충족한 수행자만 신청할 수 있어요. 고가품·현금·민감 서류는 취급하지 않고, 사진·QR·인수증으로 완료를 증빙해요.',
  );

  /// 키로 찾아 쓰기 위한 표 (데이터 파일에서 문자열로 지정할 때 사용)
  static const byKey = <String, Disclosure>{
    'partner': partner,
    'insurance': insurance,
    'clinical': clinical,
    'research': research,
    'realEstate': realEstate,
    'finance': finance,
    'labor': labor,
    'pricing': pricing,
    'b2b': b2b,
  };

  static Disclosure of(String? key) => byKey[key] ?? partner;
}
