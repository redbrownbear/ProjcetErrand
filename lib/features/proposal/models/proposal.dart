import 'package:cloud_firestore/cloud_firestore.dart';

/// 제안 한 건의 최대 모집 인원 (서버 `MAX_PEOPLE`과 같다)
const proposalMaxPeople = 15;

/// 제안 — "가는 김에 사다 드려요".
///
/// 부탁(요청자가 먼저 올림)과 반대 방향이다. 이동하는 이웃이 먼저
/// "도쿄 가는데 도쿄바나나 원하시는 분?" 하고 가격·인원을 정해 올리고,
/// 원하는 이웃이 '저 구매할래요!'를 눌러 자리를 잡는다. (시안 v43~v44)
///
/// 국내는 다른 지역으로 이동할 때만 올릴 수 있다(예: 대전 → 서울).
///
/// 서버에 연결되면 `proposals/{id}`에 올라가고 신청 · 취소 · 진행 결정은 서버 함수가 한다(A15, functions/src/proposal).
/// 서버 연결 전에는 이 기기에만 저장된다.
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

  /// 1명당 심부름료 (물건값과 별도). 0이면 받지 않거나 정하지 않음
  final int fee;

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

  /// 서버 제안의 주인 uid. 이 기기에만 있는 제안 · 예시는 null
  final String? ownerUid;

  /// 전달 방식 — each(구매자마다 따로 전달) · meet(정한 장소 · 시간에 한꺼번에 받기)
  final String delivery;
  final String? meetPlace;
  final String? meetTime;

  /// open(모집 중) · proceeding(제안자가 진행하기로 함 — 새 신청 안 받음) · cancelled
  final String state;

  /// 서버가 센 신청 인원(나 포함). 서버 제안에만 있다 — 있으면 [joined] 대신 쓴다
  final int? serverCount;

  /// 정원이 차서 자리를 기다리는 인원(A30, 서버 제안만)
  final int waitCount;

  const Proposal({
    required this.id,
    required this.abroad,
    required this.from,
    this.to = '서울',
    this.cc,
    required this.item,
    this.spec,
    required this.price,
    this.fee = 0,
    required this.day,
    required this.max,
    this.joined = 0,
    required this.who,
    this.area = '',
    this.ago = '방금',
    this.note = '',
    this.departVerified = false,
    this.mine = false,
    this.ownerUid,
    this.delivery = 'each',
    this.meetPlace,
    this.meetTime,
    this.state = 'open',
    this.serverCount,
    this.waitCount = 0,
  });

  /// 서버에 올라간 제안
  bool get onServer => ownerUid != null;

  /// 예시 제안(체험용) — 서버에 연결된 뒤에는 신청할 수 없다
  bool get sample => !onServer && !mine;

  bool get cancelled => state == 'cancelled';
  bool get proceeding => state == 'proceeding';

  /// 전달 방식 한 줄
  String get deliveryLabel => delivery == 'meet'
      ? '한꺼번에 받기 · ${[meetPlace, meetTime].where((s) => s != null && s.isNotEmpty).join(' · ')}'
      : '구매자마다 따로 전달 · 채팅으로 정해요';

  bool get unlimited => max == 0;

  /// 1명이 내는 돈 = 물건값 + 심부름료
  int get total => price + fee;

  int countWith(bool meJoined) => serverCount ?? joined + (meJoined ? 1 : 0);

  int left(bool meJoined) => unlimited ? 999 : (max - countWith(meJoined)).clamp(0, max);

  bool isFull(bool meJoined) => !unlimited && left(meJoined) == 0;

  /// 지난 날짜의 제안은 마감으로 본다
  bool get expired {
    final now = DateTime.now();
    return day.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// 정원만 찬 상태 — 대기 예약을 받을 수 있다(A30, 서버 제안만)
  bool waitable(bool meJoined) => onServer && !cancelled && !proceeding && !expired && isFull(meJoined);

  /// 지금 신청할 수 있는가
  bool openFor(bool meJoined) => !cancelled && !proceeding && !expired && !isFull(meJoined);

  /// 보드 행의 오른쪽 상태 — '3/5' · '1자리' · '2명' · '마감'
  String status(bool meJoined) {
    if (cancelled) return '취소';
    if (proceeding) return '진행';
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
    'fee': fee,
    'day': day.toIso8601String(),
    'max': max,
    'who': who,
    'area': area,
    'note': note,
    'delivery': delivery,
    'meetPlace': meetPlace,
    'meetTime': meetTime,
  };

  /// 서버 함수 createProposal에 보낼 값. 날짜는 한국 날짜 'YYYY-MM-DD'
  Map<String, Object?> toServer() => {
    'abroad': abroad,
    'from': from,
    if (!abroad) 'to': to,
    if (abroad) 'cc': cc,
    'item': item,
    'spec': spec ?? '',
    'price': price,
    'fee': fee,
    'day': '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
    'max': max,
    'delivery': delivery,
    if (delivery == 'meet') 'meetPlace': meetPlace ?? '',
    if (delivery == 'meet') 'meetTime': meetTime ?? '',
    'note': note,
    'area': area,
  };

  /// 서버 문서(`proposals/{id}`). [myUid]와 주인이 같으면 내 제안
  static Proposal? fromDoc(String docId, Map<String, dynamic> m, {String? myUid}) {
    final id = int.tryParse(docId);
    final dayStr = m['day'];
    final day = dayStr is String ? DateTime.tryParse(dayStr) : null;
    final owner = m['ownerUid'];
    if (id == null || day == null || owner is! String || m['item'] is! String || m['price'] is! int) return null;
    String? s(String k) => m[k] is String && (m[k] as String).isNotEmpty ? m[k] as String : null;
    int n(String k) => m[k] is int ? m[k] as int : 0;
    final abroad = m['abroad'] == true;
    final created = m['createdAt'];
    return Proposal(
      id: id,
      abroad: abroad,
      from: s('from') ?? '',
      to: abroad ? '한국' : (s('to') ?? '서울'),
      cc: s('cc'),
      item: m['item'] as String,
      spec: s('spec'),
      price: m['price'] as int,
      fee: n('fee'),
      day: day,
      max: n('max'),
      who: s('who') ?? '이웃',
      area: s('area') ?? '',
      ago: created is Timestamp ? agoLabel(created.toDate()) : '',
      note: s('note') ?? '',
      mine: myUid != null && owner == myUid,
      ownerUid: owner,
      delivery: m['delivery'] == 'meet' ? 'meet' : 'each',
      meetPlace: s('meetPlace'),
      meetTime: s('meetTime'),
      state: s('status') ?? 'open',
      serverCount: n('joinedCount'),
      waitCount: n('waitCount'),
    );
  }

  static Proposal? fromJson(dynamic j) {
    if (j is! Map) return null;
    final day = DateTime.tryParse('${j['day']}');
    if (j['id'] is! int || j['item'] is! String || j['price'] is! int || day == null) return null;
    return Proposal(
      id: j['id'] as int,
      abroad: j['abroad'] == true,
      from: '${j['from'] ?? ''}',
      to: '${j['to'] ?? '서울'}',
      cc: j['cc'] is String ? j['cc'] as String : null,
      item: j['item'] as String,
      spec: j['spec'] is String ? j['spec'] as String : null,
      price: j['price'] as int,
      fee: j['fee'] is int ? j['fee'] as int : 0,
      day: day,
      max: j['max'] is int ? j['max'] as int : 0,
      who: '${j['who'] ?? '나'}',
      area: '${j['area'] ?? ''}',
      note: '${j['note'] ?? ''}',
      mine: true,
      delivery: j['delivery'] == 'meet' ? 'meet' : 'each',
      meetPlace: j['meetPlace'] is String ? j['meetPlace'] as String : null,
      meetTime: j['meetTime'] is String ? j['meetTime'] as String : null,
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

/// '방금' · '20분 전' · '3시간 전' · '2일 전'
String agoLabel(DateTime t, [DateTime? now]) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return '방금';
  if (d.inHours < 1) return '${d.inMinutes}분 전';
  if (d.inDays < 1) return '${d.inHours}시간 전';
  return '${d.inDays}일 전';
}

bool isNearDay(DateTime d) {
  final t = dayTag(d);
  return t == '오늘' || t == '내일';
}
