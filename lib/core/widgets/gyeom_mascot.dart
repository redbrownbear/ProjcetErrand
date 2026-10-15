import 'package:flutter/material.dart';

/// 겸사겸사 캐릭터 '겸이'.
///
/// 시안(v77)의 `<svg class="gm" viewBox="0 0 200 180">`를 그대로 옮겨 그린다.
/// 패키지 없이 그리려고 SVG 경로의 상대 좌표(c·s)를 절대 좌표로 풀어 적었다.
/// [bob]이 true면 시안의 `.gm-b`처럼 몸이 위아래로 천천히 떠 있다.
class GyeomMascot extends StatefulWidget {
  final double width;
  final bool bob;
  const GyeomMascot({super.key, this.width = 120, this.bob = true});

  @override
  State<GyeomMascot> createState() => _GyeomMascotState();
}

class _GyeomMascotState extends State<GyeomMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void initState() {
    super.initState();
    if (widget.bob) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.width * 0.9,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(painter: _MascotPainter(Curves.easeInOut.transform(_c.value))),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  /// 0~1. 몸이 떠오른 정도
  final double lift;
  _MascotPainter(this.lift);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 180);

    // 바닥 그림자 — 몸이 뜰수록 살짝 작아진다
    final shadowScale = 1 - lift * 0.08;
    canvas.save();
    canvas.translate(100, 168);
    canvas.scale(shadowScale, 1);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 104, height: 14),
      Paint()..color = const Color(0x24B48200),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(0, -4 * lift);

    // 몸
    final body = Path()
      ..moveTo(100, 44)
      ..cubicTo(144, 44, 168, 74, 168, 110)
      ..cubicTo(168, 144, 142, 162, 100, 162)
      ..cubicTo(58, 162, 32, 144, 32, 110)
      ..cubicTo(32, 74, 56, 44, 100, 44)
      ..close();
    const bodyRect = Rect.fromLTRB(32, 44, 168, 162);
    canvas.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.16, -0.3),
          radius: 0.7,
          colors: [Color(0xFFFFE789), Color(0xFFFFD33D), Color(0xFFF7B81E)],
          stops: [0, 0.6, 1],
        ).createShader(bodyRect),
    );

    // 팔
    final fill = Paint()..color = const Color(0xFFFFD33D);
    canvas.drawPath(
      Path()
        ..moveTo(36, 118)
        ..cubicTo(28, 120, 24, 128, 28, 134)
        ..cubicTo(32, 139, 40, 136, 42, 130)
        ..close(),
      fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(164, 118)
        ..cubicTo(172, 120, 176, 128, 172, 134)
        ..cubicTo(168, 139, 160, 136, 158, 130)
        ..close(),
      fill,
    );

    // 배 주름
    canvas.drawPath(
      Path()
        ..moveTo(50, 88)
        ..cubicTo(64, 96, 80, 100, 100, 100)
        ..cubicTo(120, 100, 136, 96, 150, 88),
      Paint()
        ..color = const Color(0x8CF2A81C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 매듭
    final knot = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFB547), Color(0xFFF29A1F)],
      ).createShader(const Rect.fromLTRB(70, 18, 130, 50));
    canvas.drawPath(
      Path()
        ..moveTo(100, 50)
        ..cubicTo(90, 48, 78, 36, 70, 20)
        ..cubicTo(86, 18, 98, 28, 102, 42)
        ..close(),
      knot,
    );
    canvas.drawPath(
      Path()
        ..moveTo(100, 50)
        ..cubicTo(110, 48, 122, 36, 130, 20)
        ..cubicTo(114, 18, 102, 28, 98, 42)
        ..close(),
      knot,
    );
    canvas.drawOval(Rect.fromCenter(center: const Offset(100, 50), width: 22, height: 16), Paint()..color = const Color(0xFFF29A1F));

    // 눈
    final eye = Paint()..color = const Color(0xFF2A2522);
    canvas.drawOval(Rect.fromCenter(center: const Offset(80, 112), width: 13, height: 17), eye);
    canvas.drawOval(Rect.fromCenter(center: const Offset(120, 112), width: 13, height: 17), eye);
    final shine = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(82.5, 108.5), 2.4, shine);
    canvas.drawCircle(const Offset(122.5, 108.5), 2.4, shine);

    // 입
    canvas.drawPath(
      Path()
        ..moveTo(91, 128)
        ..cubicTo(96, 134, 104, 134, 109, 128),
      Paint()
        ..color = const Color(0xFF2A2522)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // 볼
    final cheek = Paint()..color = const Color(0x8CFF9E8A);
    canvas.drawOval(Rect.fromCenter(center: const Offset(66, 126), width: 16, height: 10), cheek);
    canvas.drawOval(Rect.fromCenter(center: const Offset(134, 126), width: 16, height: 10), cheek);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MascotPainter old) => old.lift != lift;
}
