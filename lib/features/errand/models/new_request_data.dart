import 'task_item.dart';

/// 부탁 쓰기 화면이 만들어 넘기는 값.
///
/// 실제 부탁([TaskItem])으로 바꾸는 건 [toItem] 하나다. 글쓰기 화면의 '이렇게 올라가요' 미리보기와
/// 실제로 올라가는 글이 **같은 함수**로 만들어져야 쓰는 칸과 보이는 칸이 어긋나지 않는다.
class NewRequestData {
  /// ask | sea | going
  final String mode;
  final String cat, title, desc, place;
  final String? cc, city, country;
  final int mins, price;
  final bool hot;

  /// 미리보기에서는 아직 비어 있을 수 있다. 올릴 때는 폼이 반드시 채운다.
  final DateTime? deadline;
  final String deliveryPlace;

  /// 물품 예산 (사례비와 별도)
  final int budget;

  /// none | prepaid | reimburse
  final String payment;
  final String completion;

  /// trip('가는 김에 · 가는 분 찾아요') 등 덧붙은 갈래
  final String? extra;

  /// 동네 부탁의 위치(선택, A13 동선 추천용). 공개 문서에는 안 올라가고 private/detail로 간다
  final double? lat, lng;

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
    this.extra,
    this.lat,
    this.lng,
  });

  bool get sea => mode == 'sea';
  bool get going => mode == 'going';

  /// 다른 사람 목록·상세에 보일 지역.
  /// - 동네 부탁: 내 동네 이름(정확한 만날 장소는 수락된 사람만 본다)
  /// - 가는 김에(제가 가요): 가는 곳 — 내 위치가 아니라 공개해도 되는 정보다
  String? publicRegion(String scope) {
    if (sea) return null;
    if (going) return country == null ? (place.isEmpty ? null : place) : null;
    return scope == '전국' ? '우리 동네' : scope;
  }

  TaskItem toItem({
    required int id,
    required String scope,
    required String who,
    String? ownerUid,
    bool mine = true,
  }) {
    final abroad = sea || (going && cc != null);
    return TaskItem(
      id: id,
      mode: mode,
      cat: cat,
      title: title,
      desc: desc,
      // 가는 김에는 가는 곳이 곧 공개 장소다. 동네·해외 부탁의 장소는 공개 문서에 올라가지 않는다(private/detail)
      place: place.isEmpty ? null : place,
      cc: cc,
      city: city,
      country: country,
      region: publicRegion(scope),
      lat: lat,
      lng: lng,
      // 새 부탁은 실제 거리를 알 수 없어 임의의 거리를 붙이지 않는다.
      distM: abroad ? 9e9 : null,
      mins: (abroad || going) ? 0 : mins,
      price: price,
      who: who,
      // 방금 올린 글에 별점·본인인증을 자동으로 붙이지 않는다.
      rating: 0,
      reviews: 0,
      deals: 0,
      resp: 0,
      verified: false,
      helpCnt: 0,
      reqCnt: 0,
      hot: hot,
      deadline: deadline,
      deliveryPlace: deliveryPlace.isEmpty ? null : deliveryPlace,
      budget: budget,
      payment: going ? null : payment,
      completion: completion.isEmpty ? null : completion,
      extra: extra,
      sample: false,
      ownerUid: ownerUid,
      mine: mine,
    );
  }
}
