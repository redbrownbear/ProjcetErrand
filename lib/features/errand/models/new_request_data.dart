/// 부탁 쓰기 화면이 만들어 넘기는 값. 실제 부탁([TaskItem])으로 바꾸는 건 [AppSession.addRequest]다.
class NewRequestData {
  final String mode, cat, title, desc, place;
  final String? cc, city, country;
  final int mins, price;
  final bool hot;
  final DateTime deadline;
  final String deliveryPlace;

  /// 물품 예산 (사례비와 별도)
  final int budget;

  /// none | prepaid | reimburse
  final String payment;
  final String completion;

  const NewRequestData({
    required this.mode,
    required this.cat,
    required this.title,
    required this.desc,
    required this.place,
    this.cc,
    this.city,
    this.country,
    required this.mins,
    required this.price,
    required this.hot,
    required this.deadline,
    required this.deliveryPlace,
    required this.budget,
    required this.payment,
    required this.completion,
  });
}
