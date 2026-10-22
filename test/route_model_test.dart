import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/core/utils/geohash.dart';
import 'package:gyeomsa/features/route/models/commute_route.dart';

/// W6 · A02 정기 동선: 격자 계산(서버와 같은 값) · 저장 모양 · 검증
void main() {
  test('geohash: 알려진 값과 같고 가운데 좌표가 가깝다', () {
    expect(Geohash.encode(57.64911, 10.40744, 11), 'u4pruydqqvj');
    final g = Geohash.encode(37.4979, 127.0276);
    expect(Geohash.isValid(g), isTrue);
    final (lat, lng) = Geohash.center(g);
    expect((lat - 37.4979).abs() < 0.01 && (lng - 127.0276).abs() < 0.01, isTrue);
    expect(Geohash.isValid('WYDM9X'), isFalse);
  });

  test('저장 문서에는 좌표가 없고 격자만, 읽으면 되돌아온다', () {
    final r = CommuteRoute(
      id: '',
      name: '출근',
      from: RoutePoint.at('방배역', 37.4814, 126.9976, area: '방배동'),
      to: RoutePoint.at('강남역', 37.4979, 127.0276),
      days: const [5, 1, 2, 3, 4],
      start: '08:00',
      end: '09:00',
    );
    final m = r.toMap();
    expect(m.toString().contains('37.48'), isFalse);
    expect((m['from'] as Map)['cell6'], Geohash.encode(37.4814, 126.9976));
    expect(m['days'], [1, 2, 3, 4, 5]);
    expect(r.dayLabel, '평일');
    expect(r.problem, isNull);
    final back = CommuteRoute.fromDoc('x', {...m, 'cells': ['a', 'b']})!;
    expect(back.from.label, '방배역');
    expect(back.cellCount, 2);
    expect(back.radiusLabel, '500m');
  });

  test('검증: 요일 · 시간 · 반경', () {
    CommuteRoute make({List<int> days = const [1], String start = '08:00', int radius = 500}) => CommuteRoute(
      id: '',
      name: '퇴근',
      from: const RoutePoint(label: 'A', cell6: 'wydm9q'),
      to: const RoutePoint(label: 'B', cell6: 'wydm9x'),
      days: days,
      start: start,
      end: '19:00',
      radiusM: radius,
    );
    expect(make(days: const []).problem, isNotNull);
    expect(make(start: '25:00').problem, isNotNull);
    expect(make(radius: 50).problem, isNotNull);
    expect(make(radius: 8000).radiusLabel, '8km');
    expect(make(days: const [6, 7]).dayLabel, '주말');
  });
}
