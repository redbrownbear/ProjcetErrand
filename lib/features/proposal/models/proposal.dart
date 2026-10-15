/// 제안 — "가는 김에 사다 드려요".
///
/// 부탁(요청자가 먼저 올림)과 반대 방향이다. 이동하는 이웃이 먼저
/// "도쿄 가는데 도쿄바나나 원하시는 분?" 하고 가격·인원을 정해 올리고,
/// 원하는 이웃이 '저 구매할래요!'를 눌러 자리를 잡는다. (시안 v43~v44)
///
/// 국내는 다른 지역으로 이동할 때만 올릴 수 있다(예: 대전 → 서울).
class Proposal {
  final int id;

  /// 해외 제안이면 true. 국내는 지역 간 이동.
  final bool abroad;

  /// 사 오는 곳. 국내는 지역 이름, 해외는 도시 이름.
  final String from;

  /// 가는 곳. 국내만 쓴다.
  final String to;

  /// 해외 나라 코드 (소문자, countries.dart와 같다)
  final String? cc;

  final String item;
  final String? spec;

  /// 1명당 물건 가격 (영수증 기준)
  final int price;

  /// 이동하는 날
  final DateTime day;

  /// 받을 인원. 0이면 제한 없음.
  final int max;

  /// 지금까지 요청한 인원 (나 제외)
  final int joined;

  /// 올린 사람 (제안자 스토어 이름)
  final String who;
  final String area;
  final String ago;
  final String note;

  /// 해외 제안자가 항공권·탑승권 확인을 마쳤다 (출국 확인 배지)
  final bool departVerified;

  /// 내가 올린 제안
  final bool mine;

  const Proposal({
    required this.id,
    required this.abroad,
    required this.from,
    this.to = '서울',
    this.cc,
    required this.item,
    this.spec,
    required this.price,
    required this.day,
    required this.max,
    this.joined = 0,
    required this.who,
    this.area = '',
    this.ago = '방금',
    this.note = '',
    this.departVerified = false,
    this.mine = false,
  });

  bool get unlimited => max == 0;

  int countWith(bool meJoined) => joined + (meJoined ? 1 : 0);

  int left(bool meJoined) => unlimited ? 999 : (max - countWith(meJoined)).clamp(0, max);

  bool isFull(bool meJoined) => !unlimited && left(meJoined) == 0;

  /// 지난 날짜의 제안은 마감으로 본다
  bool get expired {
    final now = DateTime.now();
    return day.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// 보드 행의 오른쪽 상태 — '3/5' · '1자리' · '2명' · '마감'
  String status(bool meJoined) {
    if (expired || isFull(meJoined)) return '마감';
    if (unlimited) return '${countWith(meJoined)}명';
    if (left(meJoined) == 1) return '1자리';
    return '${countWith(meJoined)}/$max';
  }

  /// '여수에서 10/16에 서울로 올라가는데 갓김치 원하시는 분?'
  String get headline {
    if (abroad) return '$from 가는데 $item 원하시는 분?';
    final d = '${day.month}/${day.day}';
    final verb = to == '서울' ? '올라가는데' : '가는데';
    return '$from에서 $d에 $to로 $verb $item 원하시는 분?';
  }

  String get route => abroad ? from : '$from → $to';

  Map<String, dynamic> toJson() => {
    'id': id,
    'abroad': abroad,
    'from': from,
    'to': to,
    'cc': cc,
    'item': item,
    'spec': spec,
    'price': price,
    'day': day.toIso8601String(),
    'max': max,
    'who': who,
    'area': area,
    'note': note,
  };

  static Proposal? fromJson(dynamic j) {
    if (j is! Map) return null;
    final day = DateTime.tryParse('${j['day']}');
    if (j['id'] is! int || j['item'] is! String || j['price'] is! int || day == null) return null;
    return Proposal(
      id: j['id'] as int,
      abroad: j['abroad'] == true,
      from: '${j['from'] ?? ''}',
      to: '${j['to'] ?? '서울'}',
      cc: j['cc'] as String?,
      item: j['item'] as String,
      spec: j['spec'] as String?,
      price: j['price'] as int,
      day: day,
      max: j['max'] is int ? j['max'] as int : 0,
      who: '${j['who'] ?? '나'}',
      area: '${j['area'] ?? ''}',
      note: '${j['note'] ?? ''}',
      mine: true,
    );
  }
}

/// 날짜 표시. 오늘·내일만 글자로, 나머지는 '10/18'. (시안 v44-2 정리)
String dayTag(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
  if (diff == 0) return '오늘';
  if (diff == 1) return '내일';
  return '${d.month}/${d.day}';
}

bool isNearDay(DateTime d) {
  final t = dayTag(d);
  return t == '오늘' || t == '내일';
}
