import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../data/point_rules.dart';

class WalkRing extends StatelessWidget {
  final int steps;
  final double size;
  const WalkRing({super.key, required this.steps, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final pct = (steps / walkGoal).clamp(0, 1).toDouble();
    return SizedBox(
      width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size(size, size), painter: _RingPainter(pct)),
        Text('🚶', style: TextStyle(fontSize: size * 0.27)),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  _RingPainter(this.pct);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    final bg = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final fg = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, bg);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -pi / 2, 2 * pi * pct, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.pct != pct;
}
