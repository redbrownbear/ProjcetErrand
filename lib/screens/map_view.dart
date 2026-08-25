import 'package:flutter/material.dart';

import '../data/items.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';

class MapView extends StatefulWidget {
  final Map<int, String> status;
  final void Function(TaskItem) onOpenDetail;
  const MapView({super.key, required this.status, required this.onOpenDetail});
  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final pins = items.where((i) => filter == 'all' ? true : filter == 'hot' ? i.hot : i.mode == filter).toList();
    return Stack(children: [
      Container(color: const Color(0xFFE7ECE4)),
      Positioned.fill(
        child: LayoutBuilder(builder: (context, box) {
          return Stack(children: [
            Positioned(left: box.maxWidth * .5, top: box.maxHeight * .35, child: Container(width: box.maxWidth * .25, height: 90, decoration: BoxDecoration(color: const Color(0xFFCDE6CD), shape: BoxShape.circle))),
            Positioned(left: box.maxWidth * .05, top: 30, child: Container(width: box.maxWidth * .35, height: 120, decoration: BoxDecoration(color: const Color(0xFFDDE4D6), borderRadius: BorderRadius.circular(6)))),
            Positioned(right: box.maxWidth * .05, top: 60, child: Container(width: box.maxWidth * .35, height: 100, decoration: BoxDecoration(color: const Color(0xFFDDE4D6), borderRadius: BorderRadius.circular(6)))),
            Positioned(left: box.maxWidth * .1, bottom: 60, child: Container(width: box.maxWidth * .3, height: 140, decoration: BoxDecoration(color: const Color(0xFFDDE4D6), borderRadius: BorderRadius.circular(6)))),
            Positioned(left: box.maxWidth * .5, top: box.maxHeight * .44 - 20, child: Container(
              width: 40, height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
              child: Container(width: 16, height: 16, decoration: BoxDecoration(color: AppColors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))),
            )),
            for (final it in pins)
              Positioned(
                left: box.maxWidth * (it.x / 100) - 24,
                top: box.maxHeight * (it.y / 100) - 40,
                child: _Pin(it: it, status: widget.status[it.id], onTap: () => widget.onOpenDetail(it)),
              ),
          ]);
        }),
      ),
      Positioned(
        top: 14, left: 14, right: 14,
        child: SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final e in [['all', '전체'], ['hot', '🔥 급한 일'], ['ask', '부탁'], ['together', '같이'], ['share', '나눔']])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: InkWell(
                    onTap: () => setState(() => filter = e[0]),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      ),
      Positioned(
        bottom: 16, left: 14, right: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 16)]),
          child: const Text('핀을 눌러 자세히 · 🔥빨강=급한 일, 검정=부탁, 초록=나눔', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.sub)),
        ),
      ),
    ]);
  }
}

class _Pin extends StatelessWidget {
  final TaskItem it;
  final String? status;
  final VoidCallback onTap;
  const _Pin({required this.it, required this.status, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final paid = it.mode == 'ask';
    final share = it.mode == 'share';
    final bg = status == 'matched' ? AppColors.green : it.hot ? AppColors.hot : paid ? AppColors.black : share ? AppColors.green : AppColors.card;
    final fg = share || it.hot || paid || status != null ? Colors.white : AppColors.ink;
    final label = status == 'matched' ? '완료' : it.hot ? '🔥${(it.price / 1000).round()}천' : paid ? '${(it.price / 1000).round()}천원' : share ? '나눔' : '같이';
    return InkWell(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12),
            border: (!paid && !share && !it.hot && status == null) ? Border.all(color: AppColors.line, width: 1.5) : null,
            boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
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
