import '../data/daily_missions.dart';
import '../data/mission_providers.dart';
import '../models/daily_mission.dart';
import '../models/mission_provider.dart';
import '../models/reward_ledger.dart';
import 'mission_tracker.dart';

/// 미션 하나의 지금 상태. 화면은 이 값만 보고 그린다.
class MissionState {
  final DailyMission m;
  final MissionProvider provider;

  /// 오늘(또는 계정 전체) 이미 받은 횟수
  final int claimed;

  /// 카운터형 미션의 진행도. 아닌 미션은 0.
  final int progress;

  const MissionState({
    required this.m,
    required this.provider,
    required this.claimed,
    required this.progress,
  });

  /// 받을 수 있는 만큼 다 받았다
  bool get done => claimed >= m.cap;

  /// 제휴 키·계약이 아직이라 누를 수 없다
  bool get locked => !provider.usable;

  /// 카운터형인데 아직 목표에 못 미쳤다 (누르면 해당 화면으로 보낸다)
  bool get short => m.target > 1 && progress < m.target;

  /// 남은 횟수
  int get left => (m.cap - claimed).clamp(0, m.cap);

  /// 이번에 받으면 들어오는 포인트.
  /// 변동 지급([PayoutKind.rate]·[PayoutKind.partner])은 미리 알 수 없어 0이다.
  int get nextPoints => done || m.payout != PayoutKind.fixed ? 0 : m.points;

  /// 눌러도 그 자리에서 적립되지 않는 미션인지.
  /// 구매 확정·제휴사 콜백을 서버가 확인한 뒤에 들어온다.
  bool get deferred => !m.instant;

  /// 목록 오른쪽에 붙는 한 줄
  String get statusLabel {
    if (done) return m.cap > 1 ? '오늘 $claimed/${m.cap} 완료' : '완료';
    if (locked) return provider.statusLabel;
    if (deferred) return '확정 후 지급';
    if (m.target > 1) return '$progress/${m.target}';
    if (m.cap > 1) return '$claimed/${m.cap}회';
    return '';
  }
}

/// 데일리 미션의 상태 계산. 화면이나 http를 모르는 순수 계산이라 그대로 테스트한다.
class MissionEngine {
  final IsClaimedFn isClaimed;

  /// 다룰 미션 목록. 기본은 지금 서비스 중인 [dailyMissions]이고,
  /// [parkedMissions]를 되살려 볼 때나 테스트에서 갈아 끼운다.
  final List<DailyMission> missions;

  const MissionEngine(this.isClaimed, {this.missions = dailyMissions});

  MissionState stateOf(DailyMission m) {
    var claimed = 0;
    if (m.cap > 1) {
      // 회차마다 키가 따로라, 앞에서부터 세다가 안 받은 회차를 만나면 멈춘다.
      for (var i = 0; i < m.cap; i++) {
        if (!isClaimed(m.ledgerKey(i), daily: m.daily)) break;
        claimed++;
      }
    } else if (isClaimed(m.ledgerKey(), daily: m.daily)) {
      claimed = 1;
    }

    return MissionState(
      m: m,
      provider: providerOf(m.providerId),
      claimed: claimed,
      progress: _progress(m),
    );
  }

  List<MissionState> all() => [for (final m in missions) stateOf(m)];

  /// 홈 '가볍게 모으기'에 올릴 것들. 지금 눌러서 실제로 뭔가 되는 것만 고른다.
  ///
  /// 잠긴 미션은 홈에 올리지 않는다 — 홈에서 '준비 중'을 보여 주면 누를 게 없는
  /// 화면이 된다. 순서는 **매일 되는 것 먼저, 그 안에서 포인트 큰 순**이다.
  /// 포인트만으로 줄을 세우면 '첫 부탁 올리기'(100P) 같은 계정당 1회짜리가 늘
  /// 위에 붙어서, 매일 들르는 사람에게는 어제와 똑같은 화면이 된다.
  ///
  /// 변동 지급 미션은 [MissionState.nextPoints]가 0이라 뒤로 밀린다. 금액을 모르는
  /// 미션을 위에 올려 봐야 "얼마 주는데?"에 답을 못 하니 그게 맞다. 같은 값끼리는
  /// 목록에 적은 순서를 지킨다 (Dart의 sort는 안정 정렬이 아니라 명시해야 한다).
  List<MissionState> forHome({int take = 3}) {
    final rows = all().where((s) => !s.done && !s.locked).toList();
    final order = {for (var i = 0; i < rows.length; i++) rows[i].m.id: i};
    rows.sort((a, b) {
      if (a.m.daily != b.m.daily) return a.m.daily ? -1 : 1;
      if (a.nextPoints != b.nextPoints) return b.nextPoints - a.nextPoints;
      return order[a.m.id]!.compareTo(order[b.m.id]!);
    });
    return rows.take(take).toList();
  }

  /// 아직 안 받은 포인트 합계 — 상단 배너에 쓴다.
  ///
  /// 정해진 값이 있는 미션만 더한다. 쿠팡·오퍼월은 얼마가 들어올지 눌러보기 전에는
  /// 알 수 없어서, 추정치를 섞으면 배너 숫자가 거짓말이 된다.
  int get remainToday {
    var sum = 0;
    for (final s in all()) {
      if (s.locked || s.m.payout != PayoutKind.fixed) continue;
      sum += s.m.points * s.left;
    }
    return sum;
  }

  /// 오늘 받은 미션 수 / 전체(잠긴 것 제외)
  (int, int) get todayProgress {
    final open = all().where((s) => !s.locked).toList();
    return (open.where((s) => s.done).length, open.length);
  }

  /// 앱 여기저기에서 세고 있는 행동을 미션 진행도로 바꾼다.
  static int _progress(DailyMission m) => switch (m.action) {
        MissionAction.browse => MissionTracker.count(MissionTracker.openDetail),
        MissionAction.bookmark => MissionTracker.count(MissionTracker.saveTask),
        MissionAction.post => MissionTracker.count(MissionTracker.postTask),
        _ => 0,
      };
}
