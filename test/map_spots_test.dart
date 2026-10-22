import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/core/utils/geohash.dart';
import 'package:gyeomsa/features/errand/models/task_item.dart';
import 'package:gyeomsa/features/errand/repositories/request_repository.dart';
import 'package:gyeomsa/features/errand/screens/map/map_spots.dart';

/// A31 지도 핀: 좌표가 있으면 그 자리, 없으면 공개 격자(cell) 가운데, 같은 칸 여러 건은 겹치지 않게
void main() {
  TaskItem item(int id, {double? lat, double? lng, String? cell}) =>
      TaskItem(id: id, mode: 'ask', title: '부탁 $id', desc: '', who: '이웃', distM: null, lat: lat, lng: lng, cell: cell);

  const cell = 'wydm9x';

  test('서버 문서의 cell을 읽는다, 정확한 좌표는 공개 문서에 없다', () {
    final it = RequestRepository.fromDoc('7', {'mode': 'ask', 'title': 't', 'desc': '', 'cell': cell})!;
    expect(it.cell, cell);
    expect(it.lat, isNull);
    expect(TaskItem.fromJson(it.toJson())!.cell, cell);
  });

  test('좌표 우선 · 칸 가운데 · 위치 없으면 빠짐', () {
    final spots = mapSpots([item(1, lat: 37.5, lng: 127.0, cell: cell), item(2, cell: cell), item(3), item(4, cell: '잘못된값')]);
    expect(spots.map((s) => s.item.id), [1, 2]);
    expect(spots.first.approx, isFalse);
    expect(spots.first.lat, 37.5);
    final (lat, lng) = Geohash.center(cell);
    expect(spots[1].approx, isTrue);
    expect(spots[1].lat, lat);
    expect(spots[1].lng, lng);
  });

  test('같은 칸 여러 건은 가운데를 둘러 나눠 찍고, 순서가 바뀌어도 같은 자리', () {
    final a = mapSpots([item(3, cell: cell), item(1, cell: cell), item(2, cell: cell)]);
    final b = mapSpots([item(2, cell: cell), item(3, cell: cell), item(1, cell: cell)]);
    final pos = {for (final s in a) s.item.id: (s.lat, s.lng)};
    for (final s in b) {
      expect((s.lat, s.lng), pos[s.item.id]);
    }
    expect(pos.values.toSet().length, 3);
    final (lat, _) = Geohash.center(cell);
    for (final s in a) {
      expect((s.lat - lat).abs(), lessThan(0.002)); // 약 150m 원 안
    }
  });
}
