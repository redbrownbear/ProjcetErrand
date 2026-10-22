import 'dart:math' as math;

import '../../../../core/utils/geohash.dart';
import '../../models/task_item.dart';

/// 지도에 찍을 자리 하나. [approx]면 정확한 장소가 아니라 약 1km 칸(geohash 6자리) 가운데쯤이다.
class MapSpot {
  final TaskItem item;
  final double lat, lng;
  final bool approx;
  const MapSpot(this.item, this.lat, this.lng, {this.approx = false});
}

/// 부탁을 지도 자리로 바꾼다(A31).
///
/// 좌표가 있으면(내 글 · 가는 김에 핀 · 예시) 그 자리에, 없으면 서버가 붙인 공개 격자 `cell`의 가운데에 찍는다.
/// 남의 동네 부탁은 정확한 장소를 공개하지 않으니(private/detail) 칸 가운데가 최선이다.
/// 같은 칸에 여러 건이면 핀이 겹치지 않게 가운데를 둘러 작은 원(약 [ringM]m)에 나눠 놓는다 — id 순이라 매번 같은 자리.
/// 좌표도 칸도 없으면 빠진다.
List<MapSpot> mapSpots(Iterable<TaskItem> items, {double ringM = 150}) {
  final out = <MapSpot>[];
  final byCell = <String, List<TaskItem>>{};
  for (final it in items) {
    if (it.lat != null && it.lng != null) {
      out.add(MapSpot(it, it.lat!, it.lng!));
    } else if (it.cell case final c? when Geohash.isValid(c)) {
      byCell.putIfAbsent(c, () => []).add(it);
    }
  }
  for (final MapEntry(key: cell, value: list) in byCell.entries) {
    final (lat, lng) = Geohash.center(cell);
    list.sort((a, b) => a.id.compareTo(b.id));
    if (list.length == 1) {
      out.add(MapSpot(list.first, lat, lng, approx: true));
      continue;
    }
    final dLat = ringM / 111320;
    final dLng = dLat / math.cos(lat * math.pi / 180);
    for (var i = 0; i < list.length; i++) {
      final a = 2 * math.pi * i / list.length;
      out.add(MapSpot(list[i], lat + dLat * math.sin(a), lng + dLng * math.cos(a), approx: true));
    }
  }
  return out;
}
