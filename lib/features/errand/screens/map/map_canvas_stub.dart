import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../models/task_item.dart';
import 'map_canvas.dart' show MapPin;

/// 웹용 지도 캔버스. flutter_naver_map은 Android/iOS만 지원하므로
/// 웹에서는 이 구현이 대신 쓰이고, 해당 패키지를 import 하지 않는다.
class MapCanvas extends StatelessWidget {
  final List<MapPin> pins;
  final int? selectedId;
  final double centerLat, centerLng, zoom;
  final void Function(TaskItem) onPinTap;

  const MapCanvas({
    super.key,
    required this.pins,
    required this.selectedId,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.onPinTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7ECE4),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 34, color: AppColors.faint),
          const SizedBox(height: 10),
          const Text(
            '지도는 모바일 앱(Android · iOS)에서만 볼 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.sub),
          ),
          const SizedBox(height: 4),
          Text(
            '주변 부탁 ${pins.length}건',
            style: const TextStyle(fontSize: 12, color: AppColors.faint),
          ),
        ],
      ),
    );
  }
}
