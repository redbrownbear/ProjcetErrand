import 'comment.dart';

class TaskItem {
  final int id;
  final String mode; // ask | sea | together
  final String cat;
  final String? tcat; // together 카테고리
  final String title;
  final String? region;
  final String? place;
  final String? country;
  final String? cc; // 해외 국가 코드
  final String? city;
  final double? distM; // null이면 거리 미확인 (새로 올린 부탁 등)
  final int mins;
  final int price;
  final String who;
  final double rating;
  final int reviews;
  final int deals;
  final int resp;
  final bool verified;
  final int helpCnt;
  final int reqCnt;
  final double x, y;
  final String desc;
  final bool hot;
  final String? extra;
  final String? ago;
  final int likes;
  final int joinCur;
  final int joinMax;
  final List<Comment> comments;
  final double? lat, lng;
  // 거래 조건. 기존 샘플에는 없는 정보라 null이면 화면에서 "확인 필요"로 보여준다.
  final DateTime? deadline;
  final String? deliveryPlace;
  final int budget; // 물품 예산 (사례비와 별도)
  final String? payment; // none | prepaid | reimburse
  final String? completion; // 완료 확인 방법

  const TaskItem({
    required this.id,
    required this.mode,
    this.cat = 'etc',
    this.tcat,
    required this.title,
    this.region,
    this.place,
    this.country,
    this.cc,
    this.city,
    required this.distM,
    this.mins = 0,
    this.price = 0,
    required this.who,
    this.rating = 5.0,
    this.reviews = 0,
    this.deals = 0,
    this.resp = 100,
    this.verified = true,
    this.helpCnt = 0,
    this.reqCnt = 1,
    this.x = 50,
    this.y = 50,
    required this.desc,
    this.hot = false,
    this.extra,
    this.ago,
    this.likes = 0,
    this.joinCur = 0,
    this.joinMax = 0,
    this.comments = const [],
    this.lat,
    this.lng,
    this.deadline,
    this.deliveryPlace,
    this.budget = 0,
    this.payment,
    this.completion,
  });

  /// 정렬용 거리. 거리 미확인은 맨 뒤로 보낸다.
  double get distSort => distM ?? double.infinity;

  bool get isMine => who == '나';

  /// 마감 시각이 지났는지. 마감 시각과 정확히 같은 순간부터 마감으로 본다.
  bool isExpiredAt(DateTime now) => deadline != null && !deadline!.isAfter(now);
  bool get isExpired => isExpiredAt(DateTime.now());

  /// 이 기기에 보관하는 내가 올린 부탁용. 같이해요 댓글·지도 좌표는 담지 않는다.
  Map<String, dynamic> toJson() => {
        'id': id, 'mode': mode, 'cat': cat, 'title': title, 'region': region, 'place': place,
        'country': country, 'cc': cc, 'city': city, 'distM': distM, 'mins': mins, 'price': price,
        'who': who, 'rating': rating, 'reviews': reviews, 'deals': deals, 'resp': resp,
        'verified': verified, 'helpCnt': helpCnt, 'reqCnt': reqCnt, 'desc': desc, 'hot': hot,
        'deadline': deadline?.toIso8601String(), 'deliveryPlace': deliveryPlace, 'budget': budget,
        'payment': payment, 'completion': completion,
      };

  static TaskItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], mode = json['mode'], title = json['title'], desc = json['desc'];
    if (id is! int || mode is! String || title is! String || desc is! String) return null;
    String? s(String k) => json[k] is String ? json[k] as String : null;
    int n(String k) => json[k] is int ? json[k] as int : 0;
    return TaskItem(
      id: id, mode: mode, cat: s('cat') ?? 'etc', title: title, region: s('region'), place: s('place'),
      country: s('country'), cc: s('cc'), city: s('city'),
      distM: json['distM'] is num ? (json['distM'] as num).toDouble() : null,
      mins: n('mins'), price: n('price'), who: s('who') ?? '나',
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : 0,
      reviews: n('reviews'), deals: n('deals'), resp: n('resp'),
      verified: json['verified'] == true, helpCnt: n('helpCnt'), reqCnt: n('reqCnt'),
      desc: desc, hot: json['hot'] == true,
      deadline: DateTime.tryParse(s('deadline') ?? ''), deliveryPlace: s('deliveryPlace'),
      budget: n('budget'), payment: s('payment'), completion: s('completion'),
    );
  }
}
