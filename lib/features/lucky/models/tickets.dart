import '../../../core/storage/local_store.dart';

/// 응모권을 받는 방법. 시안(v77) '응모권 모으는 방법' 표를 그대로 옮겼다.
///
/// [once]가 true면 계정당 한 번, [daily]면 하루 한 번, 둘 다 아니면 할 때마다 받는다.
class TicketRule {
  final String key;
  final String group;
  final String label;
  final int n;
  final bool once;
  final bool daily;
  const TicketRule(this.key, this.group, this.label, this.n, {this.once = false, this.daily = false});
}

class TicketRules {
  static const attend = TicketRule('attend', '매일', '출석 체크', 1, daily: true);
  static const helpDone = TicketRule('helpDone', '부탁', '부탁 해주기 완료', 3);
  static const myDone = TicketRule('myDone', '부탁', '내 부탁 완료 확인', 2);
  static const seaDone = TicketRule('seaDone', '부탁', '해외 사다주기 완료', 3);
  static const visit = TicketRule('visit', '미션', '가게 방문 인증', 2);
  static const survey = TicketRule('survey', '미션', '설문·앱 체험 완료', 1);
  static const review = TicketRule('review', '미션', '거래 후기 남기기', 1);
  static const community = TicketRule('community', '커뮤니티', '커뮤니티 글·답글', 1);
  static const push = TicketRule('push', '최초', '푸시 알림 동의', 10, once: true);
  static const photo = TicketRule('photo', '최초', '프로필 사진 등록', 3, once: true);
  static const firstPost = TicketRule('firstPost', '최초', '첫 부탁 올리기', 5, once: true);

  static const all = [attend, helpDone, myDone, seaDone, visit, survey, review, community, push, photo, firstPost];
}

/// 미션 종류별 응모권 — 방문 인증 +2, 연구·상담 +3, 나머지(설문·앱 체험 등) +1
TicketRule missionTicketRule(String cat) => cat == 'visit' ? TicketRules.visit : TicketRules.survey;
int missionTickets(String cat) => switch (cat) {
  'visit' => TicketRules.visit.n,
  'research' || 'consult' => 3,
  _ => TicketRules.survey.n,
};

/// 이달의 럭키드로우. 상품과 마감일은 매달 바뀐다.
class LuckyDraw {
  final DateTime now;
  const LuckyDraw(this.now);

  int get month => now.month;

  /// 그달 마지막 날까지 남은 날
  int get dday {
    final last = DateTime(now.year, now.month + 1, 0);
    return DateTime(last.year, last.month, last.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  String get label => '$month월 LUCKY DRAW · D-$dday';
  String get monthKey => '${now.year}-${now.month.toString().padLeft(2, '0')}';

  static const prizes = [
    (rank: '1st', title: '도쿄 왕복 항공권 + 호텔', short: '도쿄 + 호텔', people: 1),
    (rank: '2nd', title: '제주 왕복+호텔', short: '제주 + 호텔', people: 3),
    (rank: '3rd', title: '상품권 10만원', short: '상품권 10만원', people: 10),
    (rank: '4th', title: '상품권 1만원', short: '상품권 1만원', people: 40),
  ];
}

/// 내 응모권 지갑.
///
/// 응모권은 겸사겸사 활동으로만 받는다. 산 것도, 현금으로 바꿀 것도 아니라서
/// 포인트(P)·겸사페이(원)와 섞지 않고 따로 센다. 이 기기에 보관된다(`LocalStore`).
class TicketWallet {
  static const _key = 'tickets';

  /// 지금 가지고 있는 장수 (응모하면 줄어든다)
  final int have;

  /// 이번 달에 응모한 장수
  final int entered;

  /// 이번 달에 모은 장수 (보너스 계산용)
  final int earnedThisMonth;

  /// 위 두 값이 어느 달 것인지 (yyyy-mm)
  final String month;

  /// 받은 기록. once는 'key', daily는 'key:yyyy-mm-dd'로 남는다.
  final Set<String> claimed;

  const TicketWallet({this.have = 0, this.entered = 0, this.earnedThisMonth = 0, this.month = '', this.claimed = const {}});

  static TicketWallet load(DateTime now) {
    final j = LocalStore.read<Map<String, dynamic>>(_key, const {});
    final w = TicketWallet(
      have: j['have'] is int ? j['have'] as int : 0,
      entered: j['entered'] is int ? j['entered'] as int : 0,
      earnedThisMonth: j['earned'] is int ? j['earned'] as int : 0,
      month: j['month'] is String ? j['month'] as String : '',
      claimed: {
        for (final k in (j['claimed'] is List ? j['claimed'] as List : const []))
          if (k is String) k,
      },
    );
    return w._rollMonth(now);
  }

  void save() => LocalStore.write(_key, {
    'have': have,
    'entered': entered,
    'earned': earnedThisMonth,
    'month': month,
    'claimed': claimed.toList(),
  });

  /// 달이 바뀌면 이번 달 응모·모은 장수를 0으로. 가진 장수는 남는다.
  TicketWallet _rollMonth(DateTime now) {
    final m = LuckyDraw(now).monthKey;
    if (m == month) return this;
    return TicketWallet(have: have, entered: 0, earnedThisMonth: 0, month: m, claimed: claimed);
  }

  static String _day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool canClaim(TicketRule r, DateTime now) {
    if (r.once) return !claimed.contains(r.key);
    if (r.daily) return !claimed.contains('${r.key}:${_day(now)}');
    return true;
  }

  /// 규칙대로 응모권을 준다. 이미 받은 one-time/daily면 null.
  TicketWallet? gain(TicketRule r, DateTime now, {int? n}) {
    if (!canClaim(r, now)) return null;
    final rolled = _rollMonth(now);
    final add = n ?? r.n;
    return TicketWallet(
      have: rolled.have + add,
      entered: rolled.entered,
      earnedThisMonth: rolled.earnedThisMonth + add,
      month: rolled.month,
      claimed: {...rolled.claimed, if (r.once) r.key, if (r.daily) '${r.key}:${_day(now)}'},
    );
  }

  /// [n]장 응모. 가진 것보다 많이 낼 수 없다.
  TicketWallet? enter(int n, DateTime now) {
    final rolled = _rollMonth(now);
    if (n <= 0 || n > rolled.have) return null;
    return TicketWallet(
      have: rolled.have - n,
      entered: rolled.entered + n,
      earnedThisMonth: rolled.earnedThisMonth,
      month: rolled.month,
      claimed: rolled.claimed,
    );
  }
}
