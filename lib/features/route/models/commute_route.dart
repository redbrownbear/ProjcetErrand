import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/geohash.dart';

/// 동선의 출발 · 도착. 사람이 고른 이름(역 · 동)과 약 1km 격자만 — 정확한 좌표는 저장하지 않는다.
class RoutePoint {
  final String label;
  final String? area;
  final String cell6;
  const RoutePoint({required this.label, this.area, required this.cell6});

  /// 고른 장소 좌표를 격자로 줄인다. 좌표 자체는 버린다
  factory RoutePoint.at(String label, double lat, double lng, {String? area}) =>
      RoutePoint(label: label, area: area, cell6: Geohash.encode(lat, lng));

  Map<String, Object?> toMap() => {'label': label, 'area': ?area, 'cell6': cell6};

  static RoutePoint? fromMap(Object? raw) {
    if (raw is! Map || raw['label'] is! String || raw['cell6'] is! String) return null;
    if (!Geohash.isValid(raw['cell6'] as String)) return null;
    return RoutePoint(label: raw['label'] as String, area: raw['area'] is String ? raw['area'] as String : null, cell6: raw['cell6'] as String);
  }
}

/// 정기 동선 (설계 W6 · 개발 To-do A02, `users/{uid}/routes/{id}`).
/// 요일 · 시간대 · 이동수단 · 반경. 매칭용 격자(`cells`)는 서버가 계산해 붙인다(onRouteWrite).
class CommuteRoute {
  /// 한 사람당 동선 수 상한(시안 v80 · 서버 MAX_ROUTES)
  static const maxRoutes = 6;
  static const minRadius = 100;
  static const maxRadius = 8000;
  static const modes = {'walk': '도보', 'transit': '대중교통', 'car': '자동차', 'bike': '자전거'};
  static const dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  final String id;
  final String name;
  final RoutePoint from;
  final RoutePoint to;

  /// 1(월) ~ 7(일)
  final List<int> days;
  final String start;
  final String end;
  final String mode;
  final int radiusM;
  final bool active;

  /// 서버가 계산한 매칭 격자 수(0이면 아직 계산 전이거나 상한 초과)
  final int cellCount;
  final bool overLimit;
  final DateTime? createdAt;

  const CommuteRoute({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.days,
    required this.start,
    required this.end,
    this.mode = 'transit',
    this.radiusM = 500,
    this.active = true,
    this.cellCount = 0,
    this.overLimit = false,
    this.createdAt,
  });

  static final _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// 저장 전에 확인. 문제가 있으면 안내 문구, 없으면 null (보안 규칙과 같은 기준)
  String? get problem {
    if (name.trim().isEmpty || name.length > 20) return '동선 이름을 20자 안으로 적어 주세요';
    if (from.cell6 == to.cell6 && from.label == to.label) return '출발과 도착이 같아요';
    if (days.isEmpty) return '요일을 하나 이상 골라 주세요';
    if (!_time.hasMatch(start) || !_time.hasMatch(end)) return '시간을 다시 골라 주세요';
    if (!modes.containsKey(mode)) return '이동수단을 골라 주세요';
    if (radiusM < minRadius || radiusM > maxRadius) return '반경은 100m ~ 8km예요';
    return null;
  }

  String get dayLabel {
    final d = [...days]..sort();
    if (d.length == 7) return '매일';
    if (d.length == 5 && d.every((x) => x <= 5)) return '평일';
    if (d.length == 2 && d.contains(6) && d.contains(7)) return '주말';
    return d.map((x) => dayNames[x - 1]).join(' · ');
  }

  String get radiusLabel => radiusM < 1000 ? '${radiusM}m' : '${(radiusM / 1000).toStringAsFixed(radiusM % 1000 == 0 ? 0 : 1)}km';

  Map<String, Object?> toMap() => {
    'name': name.trim(),
    'from': from.toMap(),
    'to': to.toMap(),
    'days': ([...days]..sort()),
    'window': {'start': start, 'end': end},
    'mode': mode,
    'radiusM': radiusM,
    'active': active,
  };

  static CommuteRoute? fromDoc(String id, Map<String, dynamic> m) {
    final from = RoutePoint.fromMap(m['from']), to = RoutePoint.fromMap(m['to']);
    final w = m['window'];
    if (from == null || to == null || m['name'] is! String || w is! Map) return null;
    final at = m['createdAt'];
    return CommuteRoute(
      id: id,
      name: m['name'] as String,
      from: from,
      to: to,
      days: [
        for (final d in (m['days'] is List ? m['days'] as List : const []))
          if (d is int && d >= 1 && d <= 7) d,
      ],
      start: w['start'] is String ? w['start'] as String : '08:00',
      end: w['end'] is String ? w['end'] as String : '09:00',
      mode: modes.containsKey(m['mode']) ? m['mode'] as String : 'transit',
      radiusM: m['radiusM'] is int ? m['radiusM'] as int : 500,
      active: m['active'] != false,
      cellCount: m['cells'] is List ? (m['cells'] as List).length : 0,
      overLimit: m['overLimit'] == true,
      createdAt: at is Timestamp ? at.toDate() : null,
    );
  }

  CommuteRoute copyWith({bool? active}) => CommuteRoute(
    id: id,
    name: name,
    from: from,
    to: to,
    days: days,
    start: start,
    end: end,
    mode: mode,
    radiusM: radiusM,
    active: active ?? this.active,
    cellCount: cellCount,
    overLimit: overLimit,
    createdAt: createdAt,
  );
}
