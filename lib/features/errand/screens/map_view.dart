import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/tag.dart';
import '../data/categories.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import 'map/map_canvas.dart';

/// 지역별 지도 초기 중심 좌표.
const _regionCenters = {
  '서울 서초구': (37.4837, 127.0324),
  '서울 강남구': (37.5172, 127.0473),
  '서울 성동구': (37.5634, 127.0367),
  '부산 수영구': (35.1455, 129.1132),
  '대전 유성구': (36.3623, 127.3560),
};
const _koreaCenter = (36.5, 127.8);

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

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  List<TaskItem> get _pinItems => widget.items
      .where((i) => i.mode != 'sea' && i.lat != null && i.lng != null && _inScope(i))
      .where((i) => filter == 'all' ? true : i.mode == filter)
      .toList();

  List<MapPin> get _pins => [
        for (final it in _pinItems)
          MapPin(item: it, lat: it.lat!, lng: it.lng!, label: _markerLabel(it), color: _markerColor(it)),
      ];

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

  void _select(TaskItem? it) {
    if (preview?.id == it?.id) return;
    setState(() => preview = it);
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
          child: MapCanvas(
            pins: _pins,
            selectedId: preview?.id,
            centerLat: center.$1,
            centerLng: center.$2,
            zoom: zoom,
            onPinTap: _select,
          ),
        ),
      ),
      Positioned(
        top: safeTop + mapMargin + 10, left: 16, right: 16,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                child: const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.ink)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const Text('지도', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                Text('${shortRegion(widget.scope)} 주변 부탁', style: const TextStyle(fontSize: 11, color: AppColors.sub)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final e in [['all', '전체'], ['ask', '부탁해요'], ['together', '같이해요']])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: InkWell(
                    onTap: () => setState(() {
                      filter = e[0];
                      preview = null;
                    }),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
          onClose: () => _select(null),
          onOpen: () {
            final p = preview!;
            _select(null);
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
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(99),
                child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.close_rounded, size: 18, color: AppColors.faint)),
              ),
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
