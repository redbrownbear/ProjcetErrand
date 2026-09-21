import 'reward_ledger.dart';

/// 출석 보상 규칙. 시안(`gyumsa-refined`의 `G3Attendance`)을 그대로 옮겼다.
///
/// 매일 1P, 연속 [streakEvery]일마다 [streakBonus]P, 월 누적 [monthTarget]일을
/// 채우는 날 [monthBonus]P를 함께 받는다. 지급 단위는 원이 아니라 포인트(P)다.
class AttendRules {
  static const daily = 1;
  static const streakEvery = 7;
  static const streakBonus = 10;
  static const monthTarget = 20;
  static const monthBonus = 100;

  static const guide = '매일 1P, 7일 연속마다 10P, 월 누적 20일 달성 시 100P를 추가로 받아요. '
      '한국 시간 자정 기준이며 하루 쉬면 연속 일수만 초기화돼요. 월 누적은 매월 1일 새로 시작해요.';
}

/// 달력에 찍힌 출석 이력.
///
/// 개편 전에는 `benefit:attend` 한 키에 **마지막으로 받은 날짜**만 남아서
/// "오늘 받았는지"밖에 알 수 없었다. 달력과 연속·누적 보상을 그리려면 지나간
/// 날짜가 그대로 남아야 하므로, 하루에 한 칸씩 [keyFor]로 원장에 쌓는다.
/// 원장은 로그인 시 `users/{uid}/ledger`로도 올라가므로 기기를 바꿔도 이어진다.
class Attendance {
  /// 하루치 출석 키. 예) `benefit:attend:2026-09-21`
  static const keyPrefix = 'benefit:attend:';
  static String keyFor(String day) => '$keyPrefix$day';

  /// 개편 전 한 줄 출석이 쓰던 키. 이미 오늘 받은 기기에서 또 받지 않도록 같이 본다.
  static const legacyKey = 'benefit:attend';

  /// 출석한 날짜(한국 시간 기준 `yyyy-MM-dd`)
  final Set<String> days;

  /// 오늘 날짜. 화면을 열어둔 채 자정을 넘겨도 같은 기준으로 계산하려고 들고 있는다.
  final String today;

  const Attendance({required this.days, required this.today});

  /// 적립 원장에서 출석 이력만 뽑는다.
  factory Attendance.fromLedger(Map<String, String> entries, {String? today}) {
    final day = today ?? RewardLedger.todayKey();
    final days = <String>{
      for (final key in entries.keys)
        if (key.startsWith(keyPrefix)) key.substring(keyPrefix.length),
      // 개편 전 키로 오늘 이미 출석했다면 오늘 칸도 채워 준다.
      if (entries[legacyKey] == day) day,
    };
    return Attendance(days: days, today: day);
  }

  bool get attendedToday => days.contains(today);

  /// 오늘(또는 오늘 아직이면 어제)부터 거꾸로 이어진 출석 일수.
  int get streak {
    var cursor = attendedToday ? today : _prev(today);
    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = _prev(cursor);
    }
    return count;
  }

  /// 이번 달 출석 일수. 월 누적은 매월 1일에 새로 시작한다.
  int get monthCount {
    final month = today.substring(0, 7);
    return days.where((d) => d.startsWith(month)).length;
  }

  /// 연속 게이지에 쓰는 값. 7일을 채운 순간에는 7/7로 보여 준다.
  int get streakInWeek {
    final s = streak;
    if (s > 0 && s % AttendRules.streakEvery == 0) return AttendRules.streakEvery;
    return s % AttendRules.streakEvery;
  }

  /// 지금 출석하면 받는 포인트. 이미 받았으면 0.
  int get todayReward {
    if (attendedToday) return 0;
    final next = streak + 1;
    var reward = AttendRules.daily;
    if (next % AttendRules.streakEvery == 0) reward += AttendRules.streakBonus;
    if (monthCount == AttendRules.monthTarget - 1) reward += AttendRules.monthBonus;
    return reward;
  }

  /// [today]가 속한 달의 일수
  int get daysInMonth {
    final (year, month) = _yearMonth;
    return DateTime.utc(year, month + 1, 0).day;
  }

  /// 1일이 무슨 요일인지. 일요일 0 … 토요일 6 (달력 첫 줄 빈 칸 수)
  int get firstWeekday {
    final (year, month) = _yearMonth;
    return DateTime.utc(year, month, 1).weekday % 7;
  }

  int get todayDay => int.parse(today.substring(8));

  String dateOf(int day) => '${today.substring(0, 8)}${day.toString().padLeft(2, '0')}';

  bool attendedOn(int day) => days.contains(dateOf(day));

  (int, int) get _yearMonth => (int.parse(today.substring(0, 4)), int.parse(today.substring(5, 7)));

  static String _prev(String day) {
    final d = DateTime.parse('${day}T00:00:00Z').subtract(const Duration(days: 1));
    return d.toIso8601String().substring(0, 10);
  }
}
