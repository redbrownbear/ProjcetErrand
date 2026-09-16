import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/config/naver_map_config.dart';
import '../../../../core/theme/colors.dart';
import '../../models/task_item.dart';
import 'map_canvas.dart' show MapPin;

/// 네이티브(Android·iOS)용 지도 캔버스. 실제 네이버 지도를 그린다.
///
/// 이 파일은 조건부 import를 통해 네이티브 빌드에서만 컴파일된다.
/// 웹 빌드는 map_canvas_stub.dart를 대신 사용하므로 flutter_naver_map을
/// 아예 참조하지 않는다.
class MapCanvas extends StatefulWidget {
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
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  NaverMapController? _controller;
  bool _following = false;

  /// 지도에 올라가 있는 마커. 선택 색만 바꿀 때 전체를 다시 그리지 않기 위해 들고 있는다.
  final Map<int, NMarker> _markers = {};

  /// _syncMarkers가 겹쳐 실행될 때 늦게 시작한 쪽만 살아남게 하는 토큰.
  int _syncToken = 0;

  @override
  void didUpdateWidget(covariant MapCanvas old) {
    super.didUpdateWidget(old);
    // 핀 목록 자체가 바뀐 경우(필터 변경)에만 전체를 다시 그린다.
    if (!listEquals(old.pins.map((p) => p.item.id).toList(), widget.pins.map((p) => p.item.id).toList())) {
      _syncMarkers();
    } else if (old.selectedId != widget.selectedId) {
      _applySelection(old.selectedId);
    }
  }

  /// 마커 전체를 다시 그린다. 핀 목록이 달라질 때만 호출한다.
  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null) return;
    final token = ++_syncToken;

    final markers = {
      for (final pin in widget.pins)
        pin.item.id: NMarker(
          id: pin.item.id.toString(),
          position: NLatLng(pin.lat, pin.lng),
          iconTintColor: pin.color,
          caption: NOverlayCaption(text: pin.label, textSize: 12.5),
        )..setOnTapListener((_) => widget.onPinTap(pin.item)),
    };

    await controller.clearOverlays(type: NOverlayType.marker);
    if (token != _syncToken || !mounted) return; // 더 늦은 sync가 시작됐으면 이 회차는 버린다
    await controller.addOverlayAll(markers.values.toSet());
    if (token != _syncToken || !mounted) return;
    _markers
      ..clear()
      ..addAll(markers);
  }

  /// 선택만 바뀐 경우. 전체를 다시 그리지 않고 색이 달라진 마커만 갱신한다.
  void _applySelection(int? previousId) {
    for (final id in {previousId, widget.selectedId}) {
      if (id == null) continue;
      final pin = widget.pins.where((p) => p.item.id == id).firstOrNull;
      if (pin != null) _markers[id]?.setIconTintColor(pin.color);
    }
  }

  Future<void> _toggleFollow() async {
    final controller = _controller;
    if (controller == null) return;

    // 상태는 로컬 플래그가 아니라 플러그인의 실제 모드에서 읽는다.
    // 사용자가 지도를 손으로 밀면 플러그인이 내부적으로 follow -> noFollow로 내리기 때문에,
    // 로컬 플래그만 믿으면 버튼은 켜져 있는데 실제로는 안 따라가는 상태가 된다.
    final turningOn = controller.locationTrackingMode != NLocationTrackingMode.follow;
    setState(() => _following = turningOn);

    if (!turningOn) {
      controller.setLocationTrackingMode(NLocationTrackingMode.none);
      return;
    }

    // 캐시 위치 점프는 반드시 follow를 켜기 "전에" 끝내야 한다.
    // follow 상태에서 들어온 developer reason 카메라 이동은 플러그인이 noFollow로 강등시켜
    // 따라가기가 조용히 꺼진다. (my_location_tracker.onCameraChanged)
    await _jumpToLastKnownLocation(controller);
    if (!mounted || !_following) return;

    // follow만 사용 — face 모드는 나침반 방위에 따라 지도가 계속 회전해서 쓰지 않음.
    // 지도 회전은 오직 사용자의 두 손가락 제스처로만 일어나게 둔다.
    controller.setLocationTrackingMode(NLocationTrackingMode.follow);
  }

  // GPS 정확한 위치를 기다리는 동안(수 초 소요될 수 있음) 캐시된 마지막 위치로
  // 먼저 카메라를 옮겨서 체감 속도를 높인다. 실패해도 정확한 위치 추적은 그대로 진행된다.
  Future<void> _jumpToLastKnownLocation(NaverMapController controller) async {
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      if (!granted) return;
      final last = await Geolocator.getLastKnownPosition();
      if (last == null || !mounted || !_following) return;
      await controller.updateCamera(NCameraUpdate.scrollAndZoomTo(target: NLatLng(last.latitude, last.longitude)));
    } catch (_) {
      // 무시 — setLocationTrackingMode의 실제 위치 추적이 이어서 처리한다.
    }
  }

  /// 지도를 손으로 밀면 플러그인이 추적을 noFollow로 내린다. 버튼 색을 실제 모드에 맞춘다.
  void _syncFollowingState() {
    final isFollowing = _controller?.locationTrackingMode == NLocationTrackingMode.follow;
    if (isFollowing != _following && mounted) setState(() => _following = isFollowing);
  }

  @override
  Widget build(BuildContext context) {
    // dart.library.io에는 Windows·macOS·Linux도 포함되지만 네이버 지도 SDK는
    // Android·iOS만 지원한다. 데스크톱에서 NaverMap 위젯을 그리면 플러그인이 없어
    // 그 자리에서 죽으므로, 안내 화면으로 대신한다. (initNaverMap도 같은 조건으로 건너뛴다)
    if (!naverMapSupported) {
      return Container(
        color: const Color(0xFFE7ECE4),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.map_outlined, size: 34, color: AppColors.faint),
          const SizedBox(height: 10),
          const Text(
            '지도는 모바일 앱(Android · iOS)에서만 볼 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.sub),
          ),
          const SizedBox(height: 4),
          Text('주변 부탁 ${widget.pins.length}건', style: const TextStyle(fontSize: 12, color: AppColors.faint)),
        ]),
      );
    }

    return Stack(children: [
      Positioned.fill(
        child: NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: NLatLng(widget.centerLat, widget.centerLng),
              zoom: widget.zoom,
            ),
            locationButtonEnable: false,
          ),
          onMapReady: (controller) {
            setState(() => _controller = controller);
            _syncMarkers();
          },
          onCameraIdle: _syncFollowingState,
        ),
      ),
      Positioned(
        top: 10, right: 10,
        child: _LocationButton(
          following: _following,
          loading: _controller?.myLocationTracker.isLoading,
          onTap: _toggleFollow,
        ),
      ),
    ]);
  }
}

class _LocationButton extends StatelessWidget {
  final bool following;
  final ValueListenable<bool>? loading;
  final VoidCallback onTap;
  const _LocationButton({required this.following, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x1F000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42, height: 42,
          child: loading == null
              ? _icon()
              : ValueListenableBuilder<bool>(
                  valueListenable: loading!,
                  builder: (context, isLoading, _) => isLoading
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue))
                      : _icon(),
                ),
        ),
      ),
    );
  }

  Widget _icon() => Icon(Icons.my_location, size: 20, color: following ? AppColors.blue : AppColors.sub);
}
