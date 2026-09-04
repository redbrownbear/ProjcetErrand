import 'package:flutter/material.dart';

import '../../models/task_item.dart';

/// 지도 캔버스. 실제 구현은 플랫폼에 따라 갈린다.
///
/// - 네이티브(Android·iOS): flutter_naver_map으로 실제 지도를 그린다.
/// - 웹: 안내 문구만 표시한다. flutter_naver_map은 Android/iOS 네이티브 SDK만
///   지원하므로, 웹 빌드에서는 **import 자체가 일어나지 않아야** 한다.
///   (조건부 import로 분리한 이유 — 웹 컴파일이 해당 패키지를 아예 참조하지 않게 하기 위함)
export 'map_canvas_stub.dart' if (dart.library.io) 'map_canvas_naver.dart';

/// 지도에 찍을 핀 하나의 표시 정보. 플랫폼 구현이 공통으로 사용한다.
class MapPin {
  final TaskItem item;
  final double lat, lng;
  final String label;
  final Color color;
  const MapPin({
    required this.item,
    required this.lat,
    required this.lng,
    required this.label,
    required this.color,
  });
}
