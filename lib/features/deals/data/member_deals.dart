import '../models/member_deal.dart';

/// 체험용 회원 전용가 데이터.
/// 실제 상품은 지역업체(§2)·프랜차이즈 본사(§8)·공동구매 셀러(§9) 제휴로 채운다.
const memberDeals = [
  MemberDeal(
    id: 's1', icon: '🎂', brand: '동네 베이커리', title: '시그니처 홀케이크 1호',
    menu: 'deal', kind: '지역업체',
    basePrice: 18000, baseSource: '매장 정상가', memberPrice: 12900,
    howMade: '제휴사가 신규고객 획득 비용 일부를 할인으로 제공',
    area: '서초구 3개 매장', cond: '예약 후 매장 픽업 · 1일 20개 한정',
  ),
  MemberDeal(
    id: 's2', icon: '💐', brand: '동네 꽃집', title: '계절 꽃다발 (중)',
    menu: 'deal', kind: '지역업체',
    basePrice: 35000, baseSource: '매장 정상가', memberPrice: 26900,
    howMade: '비수기·당일 마감 재고를 전용가로 판매',
    area: '서초구 · 강남구', cond: '당일 픽업 · 수량 소진 시 마감',
  ),
  MemberDeal(
    id: 's3', icon: '🍱', brand: '반찬가게', title: '주간 반찬 5종 세트',
    menu: 'deal', kind: '공동구매',
    basePrice: 32000, baseSource: '온라인 판매가', memberPrice: 23900,
    howMade: '공동구매로 주문량을 모아 도매 단가 확보',
    area: '서초구 픽업', cond: '10인 이상 모이면 확정 · 목요일 픽업',
  ),
  MemberDeal(
    id: 's4', icon: '☕', brand: '프랜차이즈 카페', title: '아메리카노 2잔 쿠폰',
    menu: 'deal', kind: '프랜차이즈',
    basePrice: 9000, baseSource: '본사 고시 판매가', memberPrice: 5900,
    howMade: '본사 신메뉴 프로모션 예산으로 구성한 회원 전용가',
    area: '전국 가맹점', cond: '월 2회 한정 · 앱 쿠폰 제시',
  ),
  MemberDeal(
    id: 's5', icon: '🧺', brand: '동네 세탁소', title: '드라이클리닝 5점 묶음',
    menu: 'service', kind: '생활서비스',
    basePrice: 30000, baseSource: '매장 정상가', memberPrice: 24000,
    howMade: '겸사겸사 수수료를 낮추고 차액을 가격에 반영',
    area: '서초구', cond: '수거·전달은 근거리 심부름으로 연결 가능',
  ),
  MemberDeal(
    id: 's6', icon: '🖨️', brand: '인쇄소', title: '흑백 100매 + 제본',
    menu: 'service', kind: '생활서비스',
    basePrice: 12000, baseSource: '매장 정상가', memberPrice: 8900,
    howMade: '빈 작업 슬롯(비수기 시간대)을 전용가로 판매',
    area: '서초구 · 관악구', cond: '평일 14~17시 접수분',
  ),
  MemberDeal(
    id: 's7', icon: '💳', brand: '제휴 카드', title: '카드 신청 프로모션',
    menu: 'finance', kind: '금융',
    basePrice: 0, baseSource: '', memberPrice: 0,
    howMade: '금융사가 승인한 제휴 프로모션 노출',
    area: '전국', cond: '만 19세 이상 · 제휴사 심사 기준 적용',
    disclosureKey: 'finance',
  ),
];

List<MemberDeal> dealsByMenu(String menu) {
  if (menu == 'all') return memberDeals;
  return memberDeals.where((d) => d.menu == menu).toList();
}
