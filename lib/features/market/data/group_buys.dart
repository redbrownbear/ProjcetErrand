/// 공동구매 — 같이 사면 싸지고, 내 링크로 지인이 사면 판매가의 일부가 적립된다 (시안 v77 `renderGP`).
///
/// 체험용 상품이다. 판매자·배송·반품은 판매자 책임이며, 목표 인원에 못 미치면 전액 환불된다.
class GroupBuy {
  final int id;
  final String cat;
  final String title;
  final String icon;
  final int price;
  final int list;
  final int joined;
  final int target;
  final int daysLeft;

  /// 공유 적립률 (%)
  final int share;
  const GroupBuy({
    required this.id,
    required this.cat,
    required this.title,
    required this.icon,
    required this.price,
    required this.list,
    required this.joined,
    required this.target,
    required this.daysLeft,
    required this.share,
  });

  int get discount => ((list - price) / list * 100).round();
  String get left => daysLeft == 0 ? '오늘 마감' : '$daysLeft일 남음';

  /// [n]명이 내 링크로 사면 받는 적립(원). 구매 확정분만, 내림.
  int shareFor(int n) => (price * share / 100).floor() * n;
}

const groupBuyCats = ['전체', '생활·뷰티', '식품', '패션'];

const groupBuys = [
  GroupBuy(id: 1, cat: '생활·뷰티', title: '프리미엄 핸드워시 3종 세트', icon: 'soap', price: 29900, list: 39000, joined: 38, target: 50, daysLeft: 2, share: 8),
  GroupBuy(id: 2, cat: '식품', title: '수제 그래놀라 대용량 1kg', icon: 'granola', price: 18900, list: 24000, joined: 71, target: 100, daysLeft: 3, share: 10),
  GroupBuy(id: 3, cat: '패션', title: '무지 순면 양말 10족', icon: 'socks', price: 15900, list: 22000, joined: 22, target: 40, daysLeft: 5, share: 12),
  GroupBuy(id: 4, cat: '식품', title: '제주 감귤 5kg 산지직송', icon: 'citrus', price: 24900, list: 32000, joined: 88, target: 100, daysLeft: 0, share: 7),
];
