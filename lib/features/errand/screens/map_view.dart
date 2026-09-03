import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../core/config/naver_map_config.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/tag.dart';
import '../data/categories.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';

const _regionCenters = {
  '서울 서초구': NLatLng(37.4837, 127.0324),
  '서울 강남구': NLatLng(37.5172, 127.0473),
  '서울 성동구': NLatLng(37.5634, 127.0367),
  '부산 수영구': NLatLng(35.1455, 129.1132),
  '대전 유성구': NLatLng(36.3623, 127.3560),
};
const _koreaCenter = NLatLng(36.5, 127.8);

class MapView extends StatefulWidget {
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;
  const MapView({super.key, required this.items, required this.scope, required this.actions});
  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  String filter = 'all';
  TaskItem? preview;
  NaverMapController? _controller;
  bool _following = false;

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  List<TaskItem> get _pins => widget.items
      .where((i) => i.mode != 'sea' && i.lat != null && i.lng != null && _inScope(i))
      .where((i) => filter == 'all' ? true : i.mode == filter)
      .toList();

  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.clearOverlays(type: NOverlayType.marker);
    await controller.addOverlayAll({
      for (final it in _pins)
        NMarker(
          id: it.id.toString(),
          position: NLatLng(it.lat!, it.lng!),
          iconTintColor: _markerColor(it),
          caption: NOverlayCaption(text: _markerLabel(it), textSize: 12.5),
        )..setOnTapListener((_) {
            setState(() => preview = it);
            _syncMarkers();
          }),
    });
  }

  Color _markerColor(TaskItem it) {
    final done = widget.actions.grabbed.contains(it.id);
    if (preview?.id == it.id) return AppColors.yellowDeep;
    if (done) return AppColors.faint;
    if (it.hot) return AppColors.red;
    return it.mode == 'ask' ? AppColors.black : AppColors.green;
  }

  String _markerLabel(TaskItem it) {
    if (it.mode != 'ask') return '같이해요';
    final done = widget.actions.grabbed.contains(it.id);
    return done ? '지원함' : (it.hot ? '🔥' : '') + kwon(it.price);
  }

  void _toggleFollow() {
    final controller = _controller;
    if (controller == null) return;
    final next = !_following;
    setState(() => _following = next);
    // follow만 사용 — face 모드는 나침반 방위에 따라 지도가 계속 회전해서 쓰지 않음.
    // 지도 회전은 오직 사용자의 두 손가락 제스처로만 일어나게 둔다.
    controller.setLocationTrackingMode(next ? NLocationTrackingMode.follow : NLocationTrackingMode.none);
  }

  @override
  Widget build(BuildContext context) {
    final center = _regionCenters[widget.scope] ?? _koreaCenter;
    final zoom = _regionCenters.containsKey(widget.scope) ? 13.5 : 7.0;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    const mapMargin = 14.0;

    return Stack(children: [
      Positioned(
        top: safeTop + mapMargin,
        left: 0, right: 0,
        bottom: safeBottom + mapMargin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: naverMapSupported
              ? NaverMap(
                  options: NaverMapViewOptions(
                    initialCameraPosition: NCameraPosition(target: center, zoom: zoom),
                    locationButtonEnable: false,
                  ),
                  onMapReady: (controller) {
                    setState(() => _controller = controller);
                    _syncMarkers();
                  },
                )
              : const _UnsupportedPlatformMap(),
        ),
      ),
      Positioned(
        top: safeTop + mapMargin + 10, left: 16, right: 16,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(99),
                  child: const Padding(padding: EdgeInsets.only(right: 6), child: Text('‹', style: TextStyle(fontSize: 22, color: AppColors.ink))),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  const Text('지도', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  Text('${shortRegion(widget.scope)} 주변 부탁', style: const TextStyle(fontSize: 11, color: AppColors.sub)),
                ]),
              ]),
            ),
            const Spacer(),
            _LocationButton(following: _following, loading: _controller?.myLocationTracker.isLoading, onTap: _toggleFollow),
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final e in [['all', '전체'], ['ask', '부탁해요'], ['together', '같이해요']])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        filter = e[0];
                        preview = null;
                      });
                      _syncMarkers();
                    },
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: filter == e[0] ? AppColors.black : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 8)],
                      ),
                      child: Text(e[1], style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: filter == e[0] ? Colors.white : AppColors.ink)),
                    ),
                  ),
                ),
            ],
          ),
        ]),
      ),
      if (preview != null)
        _MapPreview(
          it: preview!,
          done: widget.actions.grabbed.contains(preview!.id),
          safeBottom: safeBottom + mapMargin,
          onClose: () {
            setState(() => preview = null);
            _syncMarkers();
          },
          onOpen: () {
            final p = preview!;
            setState(() => preview = null);
            widget.actions.open(context, p);
          },
        )
      else
        Positioned(
          bottom: 16 + safeBottom + mapMargin, left: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 16)]),
            child: const Text('핀을 눌러 부탁을 훑어보세요 · 해외 대행은 홈에서 볼 수 있어요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
          ),
        ),
    ]);
  }
}

class _UnsupportedPlatformMap extends StatelessWidget {
  const _UnsupportedPlatformMap();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7ECE4),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Text(
        '지도는 모바일 앱(Android · iOS)에서만 볼 수 있어요',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppColors.sub),
      ),
    );
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

class _MapPreview extends StatelessWidget {
  final TaskItem it;
  final bool done;
  final double safeBottom;
  final VoidCallback onClose, onOpen;
  const _MapPreview({required this.it, required this.done, required this.safeBottom, required this.onClose, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final paid = it.mode == 'ask';
    return Positioned(
      bottom: 16 + safeBottom, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 28)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (it.hot) ...[const Tag(label: '🔥 급해요', c: AppColors.red, bg: AppColors.redSoft), const SizedBox(width: 6)],
              Tag(label: paid ? catOf(it.cat).label : '같이해요', c: AppColors.sub, bg: AppColors.page),
              const Spacer(),
              InkWell(onTap: onClose, child: const Text('✕', style: TextStyle(fontSize: 18, color: AppColors.faint))),
            ]),
            const SizedBox(height: 8),
            Text(it.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 5),
            Text(metaOf(it), style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(paid ? won(it.price) : '무료', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
                ElevatedButton(
                  onPressed: onOpen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(done ? '지원함 ✓' : '상세보기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
