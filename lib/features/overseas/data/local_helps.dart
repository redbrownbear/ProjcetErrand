/// 현지 이웃 — 그 나라에 사는 이웃이 직접 만나서 해주는 일 (시안 v44-4).
///
/// 택배·배송은 받지 않는다. 현지에서 직접 만나 해줄 수 있는 일(쉐어하우스·가이드·
/// 통역·예약 대행·쇼핑 동행·매장 확인·정착 도움)만 제안할 수 있고, 현지 거주가
/// 확인된 이웃에게만 배지가 붙는다.
class LocalHelp {
  final int id;
  final String who;
  final String cc;
  final String city;
  final String lives; // '도쿄 신주쿠 거주 · 6년째'
  final String kind;
  final String title;
  final String detail;
  final int price;
  final int applied;
  final int max;
  const LocalHelp({
    required this.id,
    required this.who,
    required this.cc,
    required this.city,
    required this.lives,
    required this.kind,
    required this.title,
    required this.detail,
    required this.price,
    required this.applied,
    required this.max,
  });
}

const localHelpKinds = ['쉐어하우스', '현지 가이드', '통역·예약 대행', '쇼핑 동행', '매장·재고 확인', '정착 도움'];

const localHelps = [
  LocalHelp(id: 5001, who: '신주쿠집', cc: 'jp', city: '도쿄', lives: '도쿄 신주쿠 거주 · 6년째', kind: '쉐어하우스', title: '도쿄에서 쉐어하우스를 내어드려요', detail: '1박 · 4인 공용방 침대 1개', price: 38000, applied: 1, max: 4),
  LocalHelp(id: 5002, who: '난바언니', cc: 'jp', city: '오사카', lives: '오사카 난바 거주 · 4년째', kind: '쉐어하우스', title: '오사카에서 쉐어하우스를 내어드려요', detail: '한 달 단기 · 1인실', price: 650000, applied: 0, max: 3),
  LocalHelp(id: 5003, who: '시부야집사', cc: 'jp', city: '도쿄', lives: '도쿄 시부야 거주 · 5년째', kind: '현지 가이드', title: '도쿄에 사는데 현지 가이드 해드릴까요?', detail: '시부야·하라주쿠 3시간 코스', price: 35000, applied: 2, max: 6),
  LocalHelp(id: 5004, who: '하카타댁', cc: 'jp', city: '후쿠오카', lives: '후쿠오카 거주 · 3년째', kind: '통역·예약 대행', title: '후쿠오카에 사는데 통역·예약 대행 해드릴까요?', detail: '식당·병원 예약 전화와 동행 통역', price: 30000, applied: 1, max: 5),
  LocalHelp(id: 5005, who: '아키바', cc: 'jp', city: '도쿄', lives: '도쿄 아키하바라 거주 · 7년째', kind: '쇼핑 동행', title: '도쿄에 사는데 쇼핑 동행 해드릴까요?', detail: '돈키호테·드럭스토어 2시간', price: 25000, applied: 0, max: 4),
  LocalHelp(id: 5006, who: '이케부쿠로', cc: 'jp', city: '도쿄', lives: '도쿄 이케부쿠로 거주 · 8년째', kind: '정착 도움', title: '도쿄에서 정착을 도와드려요', detail: '휴대폰 개통·은행 계좌 동행', price: 40000, applied: 1, max: 3),
  LocalHelp(id: 5007, who: '방콕댁', cc: 'th', city: '방콕', lives: '방콕 거주', kind: '현지 가이드', title: '방콕에 사는데 현지 가이드 해드릴까요?', detail: '시내 2시간 코스', price: 30000, applied: 2, max: 6),
];

/// 이번 주 출국 이웃 (출국 보드)
const departures = [
  (cc: 'JP', city: '도쿄', date: '출국', plusDays: 2, people: 5),
  (cc: 'US', city: 'LA', date: '출국', plusDays: 4, people: 2),
  (cc: 'VN', city: '다낭', date: '출국', plusDays: 6, people: 4),
];
