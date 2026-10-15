import '../models/mission_meta.dart';
import '../models/partner_mission.dart';

/// 미션 목록의 상태 탭
enum MissionStatus { all, active, done }

/// 미션 목록의 조건과 그 결과 계산. 화면을 모르는 순수 계산이다.
class MissionFilter {
  final String text;
  final String cat;
  final String sort;
  final MissionStatus status;

  /// 3분 이내
  final bool shortOnly;

  /// 구매 없음
  final bool freeOnly;

  const MissionFilter({
    this.text = '',
    this.cat = 'all',
    this.sort = 'basic',
    this.status = MissionStatus.all,
    this.shortOnly = false,
    this.freeOnly = false,
  });

  /// 종류 칩. 연구와 상담은 한 칸으로 묶는다.
  static const cats = [
    ('all', '전체'),
    ('survey', '설문조사'),
    ('signup', '가입'),
    ('visit', '방문'),
    ('shopping', '쇼핑'),
    ('experience', '앱·체험'),
    ('blog', '블로그·SNS'),
    ('research', '연구·상담'),
  ];

  static const sorts = [('basic', '기본순'), ('point', '포인트 높은순'), ('time', '소요시간 짧은순')];

  MissionFilter copyWith({String? text, String? cat, String? sort, MissionStatus? status, bool? shortOnly, bool? freeOnly}) =>
      MissionFilter(
        text: text ?? this.text,
        cat: cat ?? this.cat,
        sort: sort ?? this.sort,
        status: status ?? this.status,
        shortOnly: shortOnly ?? this.shortOnly,
        freeOnly: freeOnly ?? this.freeOnly,
      );

  bool _inCat(PartnerMission m) {
    if (cat == 'all') return true;
    if (cat == 'research') return m.cat == 'research' || m.cat == 'consult';
    return m.cat == cat;
  }

  /// 조건에 맞는 미션. 적립을 끝낸 미션은 정렬과 무관하게 아래로 내린다.
  List<PartnerMission> apply(
    List<PartnerMission> missions, {
    required bool Function(PartnerMission) isDone,
    required bool Function(PartnerMission) isActive,
  }) {
    final q = text.trim();
    final list = missions.where((m) {
      if (!_inCat(m)) return false;
      if (shortOnly && m.minutes > 3) return false;
      if (freeOnly && !m.isFree) return false;
      if (status == MissionStatus.active && !isActive(m)) return false;
      if (status == MissionStatus.done && !isDone(m)) return false;
      return q.isEmpty || '${m.title} ${m.brand} ${m.desc}'.contains(q);
    }).toList();

    list.sort((a, b) {
      final doneOrder = (isDone(a) ? 1 : 0) - (isDone(b) ? 1 : 0);
      if (doneOrder != 0) return doneOrder;
      return switch (sort) {
        'point' => b.points - a.points,
        'time' => a.minutes - b.minutes,
        _ => 0,
      };
    });
    return list;
  }
}
