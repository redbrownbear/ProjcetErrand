import '../../../core/utils/stable_sort.dart';

/// 여행 · 출국 일정 (개발 To-do A11, `users/{uid}/travels/{id}`). 본인만 읽고 쓴다.
/// 해외 사다주기(B04)가 열리면 '그 나라 부탁을 먼저 알려 주기'에 쓴다. 지금은 모아 두기만 한다.
/// 날짜는 'YYYY-MM-DD' 문자열로 저장한다(시간대에 흔들리지 않고, 보안 규칙에서 글자 순서로 비교할 수 있게).
class TravelPlan {
  /// 한 사람당 일정 수(앱에서만 막는다)
  static const maxPlans = 10;

  /// 출국일은 오늘부터 이 날수 안
  static const maxAheadDays = 730;

  /// 한 번 여행 길이 상한
  static const maxStayDays = 365;

  final String id;

  /// 나라 코드(`countries`의 cc)
  final String cc;
  final String city;
  final DateTime depart;
  final DateTime back;

  /// 가는 길에 해외 부탁을 받아 볼 생각이 있는지
  final bool takeAsks;
  final String note;

  const TravelPlan({
    required this.id,
    required this.cc,
    this.city = '',
    required this.depart,
    required this.back,
    this.takeAsks = false,
    this.note = '',
  });

  static String ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseYmd(Object? v) {
    if (v is! String) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
    if (m == null) return null;
    return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 며칠 일정(당일치기 = 1일)
  int get days => _day(back).difference(_day(depart)).inDays + 1;

  /// 오늘 기준: upcoming(출국 전) · away(여행 중) · past(귀국함)
  String stateOn(DateTime today) {
    final t = _day(today);
    if (t.isBefore(_day(depart))) return 'upcoming';
    if (t.isAfter(_day(back))) return 'past';
    return 'away';
  }

  /// 출국까지 남은 날(출국 전일 때만 의미)
  int daysLeft(DateTime today) => _day(depart).difference(_day(today)).inDays;

  /// 저장 전에 확인. 문제가 있으면 안내 문구, 없으면 null (보안 규칙보다 조금 더 엄격하다)
  String? problemOn(DateTime today, {bool isNew = true}) {
    if (!RegExp(r'^[a-z]{2}$').hasMatch(cc)) return '나라를 골라 주세요';
    if (city.length > 30) return '도시는 30자까지예요';
    if (note.length > 60) return '메모는 60자까지예요';
    if (back.isBefore(_day(depart))) return '귀국일이 출국일보다 빨라요';
    if (days > maxStayDays) return '한 번 여행은 $maxStayDays일까지 적을 수 있어요';
    final t = _day(today);
    if (isNew && _day(back).isBefore(t)) return '이미 지난 일정이에요';
    if (_day(depart).difference(t).inDays > maxAheadDays) return '2년 안의 일정만 적을 수 있어요';
    return null;
  }

  Map<String, Object?> toMap() => {
    'cc': cc,
    'city': city.trim(),
    'depart': ymd(depart),
    'back': ymd(back),
    'takeAsks': takeAsks,
    'note': note.trim(),
  };

  static TravelPlan? fromDoc(String id, Map<String, dynamic> m) {
    final depart = parseYmd(m['depart']), back = parseYmd(m['back']);
    if (m['cc'] is! String || depart == null || back == null) return null;
    return TravelPlan(
      id: id,
      cc: m['cc'] as String,
      city: m['city'] is String ? m['city'] as String : '',
      depart: depart,
      back: back,
      takeAsks: m['takeAsks'] == true,
      note: m['note'] is String ? m['note'] as String : '',
    );
  }

  /// 목록 순서: 여행 중 → 다가오는 일정(가까운 순) → 지난 일정(최근 순)
  static List<TravelPlan> sorted(List<TravelPlan> list, DateTime today) {
    int rank(TravelPlan p) => switch (p.stateOn(today)) {
      'away' => 0,
      'upcoming' => 1,
      _ => 2,
    };
    final out = [...list];
    out.sortStable((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return rank(a) == 2 ? b.back.compareTo(a.back) : a.depart.compareTo(b.depart);
    });
    return out;
  }
}

