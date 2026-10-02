import '../models/task_item.dart';

/// 홈 '지금 내 주변 부탁'의 조건과 그 결과 계산.
///
/// 화면을 모르는 순수 계산이다. 목록·지도·상단 건수가 모두 같은 [apply] 결과를 쓴다.
class NearbyQuery {
  /// 탐색 대상 — ask(동네 부탁) | job(단기알바)
  final String kind;
  final String cat;

  /// 반경(km)
  final double radius;
  final String sort;

  /// 30분 안에 끝나는 부탁만
  final bool shortOnly;
  final bool showMap;

  const NearbyQuery({
    this.kind = 'ask',
    this.cat = 'all',
    this.radius = 3,
    this.sort = 'dist',
    this.shortOnly = false,
    this.showMap = false,
  });

  static const sortLabels = {'dist': '가까운순', 'price': '금액 높은순', 'time': '짧은순', 'deadline': '마감임박', 'new': '최신순'};

  static const sortOptions = [
    ('dist', '가까운순'),
    ('price', '금액 높은순'),
    ('time', '소요시간 짧은순'),
    ('deadline', '마감 임박순'),
    ('new', '최신순'),
  ];

  static const radiusOptions = [
    (0.5, '500m 이내'),
    (1.0, '1km 이내'),
    (3.0, '3km 이내'),
    (5.0, '5km 이내'),
    (10.0, '10km 이내'),
    (20.0, '20km 이내'),
    (30.0, '30km 이내'),
  ];

  /// 조건에 맞는 부탁이 없을 때 넓혀 보는 값
  static const widest = NearbyQuery(radius: 30);

  NearbyQuery copyWith({String? kind, String? cat, double? radius, String? sort, bool? shortOnly, bool? showMap}) => NearbyQuery(
    kind: kind ?? this.kind,
    cat: cat ?? this.cat,
    radius: radius ?? this.radius,
    sort: sort ?? this.sort,
    shortOnly: shortOnly ?? this.shortOnly,
    showMap: showMap ?? this.showMap,
  );

  String get radiusLabel => radius < 1 ? '${(radius * 1000).round()}m' : '${radius % 1 == 0 ? radius.toInt() : radius}km';

  static bool inScope(TaskItem i, String scope) => scope == '전국' || i.region == scope;

  /// 거리를 뺀 공통 조건 (지역 · 마감 · 종류 · 30분)
  bool matches(TaskItem i, String scope) =>
      i.mode == 'ask' &&
      inScope(i, scope) &&
      !i.isExpired &&
      (cat == 'all' || i.cat == cat) &&
      (!shortOnly || (i.mins > 0 && i.mins <= 30));

  /// 화면에 뿌릴 목록 = 직접 올린 부탁(최신순) + 예시(반경·정렬 적용).
  ///
  /// 새로 올린 부탁은 좌표가 없어서(`distM == null`) 반경 조건에 걸리면 통째로 사라진다.
  /// 방금 올린 내 부탁이 안 보이면 안 되므로 반경·정렬과 무관하게 맨 앞에 붙인다.
  List<TaskItem> apply(List<TaskItem> items, String scope) {
    final real = items.where((i) => !i.sample && matches(i, scope)).toList()..sort((a, b) => b.id.compareTo(a.id));
    final samples = items.where((i) => i.sample && matches(i, scope) && i.distM != null && i.distM! <= radius * 1000).toList()
      ..sort(_comparator);
    return [...real, ...samples];
  }

  int Function(TaskItem, TaskItem) get _comparator => switch (sort) {
    'price' => (a, b) => b.price - a.price,
    'time' => (a, b) => a.mins.compareTo(b.mins),
    'deadline' => _byDeadline,
    'new' => (a, b) => b.id.compareTo(a.id),
    _ => (a, b) => a.distSort.compareTo(b.distSort),
  };

  /// 마감이 없는 부탁은 뒤로 보낸다
  static int _byDeadline(TaskItem a, TaskItem b) {
    final x = a.deadline, y = b.deadline;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }
}
