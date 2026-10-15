import 'package:flutter/material.dart';

/// 마스코트 '겸이'. 원본은 200x180 SVG다.
///
/// SVG를 그대로 [CustomPainter]로 옮겼다. 패키지를 더하지 않으려고 경로를 손으로
/// 풀었고, 상대 좌표(`c`, `s`)는 전부 절대 좌표로 바꿔 적었다.
/// 화면에 올라가면 위아래로 천천히 떠 있는다 (기기 설정에서 애니메이션을 끄면 멈춘다).
class Gyeomi extends StatefulWidget {
  final double width;
  const Gyeomi({super.key, this.width = 148});

  @override
  State<Gyeomi> createState() => _GyeomiState();
}

class _GyeomiState extends State<Gyeomi> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _bob.stop();
    } else if (!_bob.isAnimating) {
      _bob.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    return SizedBox(
      width: w,
      height: w * 0.9,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (_, _) => CustomPaint(painter: _GyeomiPainter(Curves.easeInOut.transform(_bob.value))),
      ),
    );
  }
}

class _GyeomiPainter extends CustomPainter {
  /// 0~1. 몸이 떠오르는 정도. 그림자는 반대로 작아진다.
  final double lift;
  _GyeomiPainter(this.lift);

  static const _eye = Color(0xFF2A2522);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 180);

    // 그림자
    final shadowScale = 1 - lift * 0.12;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 168), width: 104 * shadowScale, height: 14 * shadowScale),
      Paint()..color = const Color(0x24B48200),
    );

    canvas.save();
    canvas.translate(0, -5 * lift);

    // 몸
    const bodyBox = Rect.fromLTRB(32, 44, 168, 162);
    final body = Path()
      ..moveTo(100, 44)
      ..cubicTo(144, 44, 168, 74, 168, 110)
      ..cubicTo(168, 144, 142, 162, 100, 162)
      ..cubicTo(58, 162, 32, 144, 32, 110)
      ..cubicTo(32, 74, 56, 44, 100, 44)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.16, -0.3),
          radius: 0.7,
          colors: [Color(0xFFFFE789), Color(0xFFFFD33D), Color(0xFFF7B81E)],
          stops: [0, 0.6, 1],
        ).createShader(bodyBox),
    );

    // 보자기 매듭선
    canvas.drawPath(
      Path()
        ..moveTo(50, 88)
        ..cubicTo(64, 96, 80, 100, 100, 100)
        ..cubicTo(120, 100, 136, 96, 150, 88),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x8CF2A81C),
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
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 50), width: 22, height: 16),
      Paint()..color = const Color(0xFFF29A1F),
    );

    // 눈
    final eye = Paint()..color = _eye;
    canvas.drawOval(Rect.fromCenter(center: const Offset(80, 112), width: 13, height: 17), eye);
    canvas.drawOval(Rect.fromCenter(center: const Offset(120, 112), width: 13, height: 17), eye);
    final glint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(82.5, 108.5), 2.4, glint);
    canvas.drawCircle(const Offset(122.5, 108.5), 2.4, glint);

    // 입
    canvas.drawPath(
      Path()
        ..moveTo(91, 128)
        ..cubicTo(96, 134, 104, 134, 109, 128),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..color = _eye,
    );

    // 볼
    final cheek = Paint()..color = const Color(0x8CFF9E8A);
    canvas.drawOval(Rect.fromCenter(center: const Offset(66, 126), width: 16, height: 10), cheek);
    canvas.drawOval(Rect.fromCenter(center: const Offset(134, 126), width: 16, height: 10), cheek);

    // 팔
    final arm = Paint()..color = const Color(0xFFFFD33D);
    canvas.drawPath(
      Path()
        ..moveTo(36, 118)
        ..cubicTo(28, 120, 24, 128, 28, 134)
        ..cubicTo(32, 139, 40, 136, 42, 130)
        ..close(),
      arm,
    );
    canvas.drawPath(
      Path()
        ..moveTo(164, 118)
        ..cubicTo(172, 120, 176, 128, 172, 134)
        ..cubicTo(168, 139, 160, 136, 158, 130)
        ..close(),
      arm,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GyeomiPainter old) => old.lift != lift;
}
