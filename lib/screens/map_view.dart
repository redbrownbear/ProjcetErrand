import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/tag.dart';

class MapView extends StatefulWidget {
  final List<TaskItem> items;
  final List<int> grabbed;
  final String scope;
  final void Function(TaskItem) openDetail;
  const MapView({super.key, required this.items, required this.grabbed, required this.scope, required this.openDetail});
  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  String filter = 'all';
  TaskItem? preview;

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  @override
  Widget build(BuildContext context) {
    final pins = widget.items
        .where((i) => i.mode != 'sea' && _inScope(i))
        .where((i) => filter == 'all' ? true : i.mode == filter)
        .toList();

    return Stack(children: [
      Container(color: const Color(0xFFE7ECE4)),
      Positioned.fill(
        child: LayoutBuilder(builder: (context, box) {
          return Stack(children: [
            Positioned(left: box.maxWidth * .5, top: box.maxHeight * .35, child: Container(width: box.maxWidth * .25, height: 90, decoration: const BoxDecoration(color: Color(0xFFCDE6CD), shape: BoxShape.circle))),
            Positioned(left: box.maxWidth * .05, top: 30, child: Container(width: box.maxWidth * .35, height: 120, decoration: BoxDecoration(color: const Color(0xFFDDE4D6), borderRadius: BorderRadius.circular(6)))),
            Positioned(right: box.maxWidth * .05, top: 60, child: Container(width: box.maxWidth * .35, height: 100, decoration: BoxDecoration(color: const Color(0xFFDDE4D6), borderRadius: BorderRadius.circular(6)))),
            Positioned(left: box.maxWidth * .1, bottom: 60, child: Container(width: box.maxWidth * .3, height: 140, decoration: BoxDecoration(color: const Color(0xFFDDE4D6), borderRadius: BorderRadius.circular(6)))),
            Positioned(
              left: box.maxWidth * .5 - 20, top: box.maxHeight * .44 - 20,
              child: Container(
                width: 40, height: 40, alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                child: Container(width: 15, height: 15, decoration: BoxDecoration(color: AppColors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))),
              ),
            ),
            for (final it in pins)
              Positioned(
                left: box.maxWidth * (it.x / 100) - 24,
                top: box.maxHeight * (it.y / 100) - 40,
                child: _Pin(
                  it: it,
                  done: widget.grabbed.contains(it.id),
                  selected: preview?.id == it.id,
                  onTap: () => setState(() => preview = it),
                ),
              ),
          ]);
        }),
      ),
      Positioned(
        top: 16, left: 16, right: 16,
        child: Row(
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
      ),
      if (preview != null)
        _MapPreview(
          it: preview!,
          done: widget.grabbed.contains(preview!.id),
          onClose: () => setState(() => preview = null),
          onOpen: () {
            final p = preview!;
            setState(() => preview = null);
            widget.openDetail(p);
          },
        )
      else
        Positioned(
          bottom: 16, left: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 16)]),
            child: const Text('핀을 눌러 부탁을 훑어보세요 · 해외 대행은 홈에서 볼 수 있어요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
          ),
        ),
    ]);
  }
}

class _Pin extends StatelessWidget {
  final TaskItem it;
  final bool done, selected;
  final VoidCallback onTap;
  const _Pin({required this.it, required this.done, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final paid = it.mode == 'ask';
    final bg = selected ? AppColors.yellow : done ? AppColors.faint : it.hot ? AppColors.red : paid ? AppColors.black : AppColors.card;
    final fg = selected ? AppColors.ink : (paid || it.hot || done) ? Colors.white : AppColors.ink;
    final label = paid ? (done ? '지원함' : (it.hot ? '🔥' : '') + kwon(it.price)) : '같이해요';
    return InkWell(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12),
            border: (!paid && !it.hot && !done && !selected) ? Border.all(color: AppColors.line, width: 1.5) : null,
            boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ),
        CustomPaint(size: const Size(12, 7), painter: _TrianglePainter(bg)),
      ]),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width / 2, size.height)..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}

class _MapPreview extends StatelessWidget {
  final TaskItem it;
  final bool done;
  final VoidCallback onClose, onOpen;
  const _MapPreview({required this.it, required this.done, required this.onClose, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final paid = it.mode == 'ask';
    return Positioned(
      bottom: 16, left: 16, right: 16,
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
