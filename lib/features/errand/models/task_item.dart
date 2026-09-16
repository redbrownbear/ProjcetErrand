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

  /// 미리 만들어 둔 예시 데이터인지.
  ///
  /// 시드 목록은 화면을 채워 보여주기 위한 **예시**이지 실제 모집 중인 부탁이 아니다.
  /// 그래서 기본값이 true이고(시드 리터럴을 한 줄도 고치지 않아도 되도록),
  /// 사용자가 '부탁하기'로 직접 올린 것만 `sample: false`로 만든다.
  /// 화면에서는 예시에 '(예시)'를 붙이고, 진짜 부탁을 목록 맨 위에 올린다.
  final bool sample;

  /// 이 부탁을 올린 사람의 Firebase uid. 서버에서 내려온 글에만 있다.
  /// (예시 데이터와 로그아웃 상태에서 올린 글은 null)
  final String? ownerUid;

  /// 이 기기에서 내가 직접 올린 글.
  ///
  /// uid 비교만으로는 부족하다. 다음에 앱을 켰을 때 Firebase 초기화가 실패하면
  /// [currentUid]가 null이라 내 글을 못 알아본다. 작성자 이름도 서버에 올라가면
  /// 닉네임으로 바뀌므로 믿을 수 없다. 그래서 올린 순간에 표시를 남겨 둔다.
  final bool mine;

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
    this.sample = true,
    this.ownerUid,
    this.mine = false,
  });

  /// 지금 로그인한 사람의 uid. 로그인 상태가 바뀔 때 [HomeShell]이 갱신한다.
  ///
  /// 목록 카드·상세·지원 버튼 등 수십 곳에서 '내 글인가'를 물어보는데, 그때마다
  /// uid를 인자로 내려보내면 위젯 시그니처가 전부 바뀐다. 화면 전체가 한 사람의
  /// 시점으로만 그려지므로 여기 한 곳에 둔다.
  static String? currentUid;

  /// 주인 표시만 바꾼 사본. 다른 값은 그대로 둔다.
  TaskItem copyWith({String? ownerUid, bool? mine}) => TaskItem(
        id: id, mode: mode, cat: cat, tcat: tcat, title: title, region: region, place: place,
        country: country, cc: cc, city: city, distM: distM, mins: mins, price: price, who: who,
        rating: rating, reviews: reviews, deals: deals, resp: resp, verified: verified,
        helpCnt: helpCnt, reqCnt: reqCnt, x: x, y: y, desc: desc, hot: hot, extra: extra, ago: ago,
        likes: likes, joinCur: joinCur, joinMax: joinMax, comments: comments, lat: lat, lng: lng,
        deadline: deadline, deliveryPlace: deliveryPlace, budget: budget, payment: payment,
        completion: completion, sample: sample,
        ownerUid: ownerUid ?? this.ownerUid, mine: mine ?? this.mine,
      );

  /// 로그인 전에 이 기기에만 저장돼 있던 글을 내 계정 글로 만들 때 쓴다.
  /// (첫 로그인 이관 — HomeShell 참고)
  TaskItem withOwner(String uid) => copyWith(ownerUid: uid);

  /// 정렬용 거리. 거리 미확인은 맨 뒤로 보낸다.
  double get distSort => distM ?? double.infinity;

  /// 내가 올린 부탁인지. 서버 글은 uid로, 이 기기에만 있는 글은 작성자 이름으로 가린다.
  /// 세 가지 중 하나라도 맞으면 내 글이다.
  /// 올릴 때 남긴 표시 · 로그인한 uid와 같은 주인 · 이 기기에만 있던 옛 글의 작성자 이름.
  bool get isMine =>
      mine || (ownerUid != null && currentUid != null && ownerUid == currentUid) || who == '나';

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
        'payment': payment, 'completion': completion, 'sample': sample, 'ownerUid': ownerUid,
        'mine': mine,
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
      // 이 기기에 보관되는 건 사용자가 올린 진짜 부탁뿐이다.
      // (sample 필드가 없던 시절에 저장된 기록도 예시가 아니다)
      sample: json['sample'] == true,
      ownerUid: s('ownerUid'),
      // 이 기기에 보관된 건 내가 올린 글뿐이다 (mine 필드가 없던 시절 기록 포함)
      mine: true,
    );
  }
}
