import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_icon.dart';

/// 마스코트 '겸이' (시안 v33의 `.gm` SVG, viewBox 200x180).
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
    canvas.drawOval(Rect.fromCenter(center: const Offset(100, 50), width: 22, height: 16), Paint()..color = const Color(0xFFF29A1F));

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

/// 탭 맨 위의 겸이 카드 (시안 v33 `.h2.h3`).
///
/// 부탁하기 · 돈벌기 · 해외 부탁하기 · 해외 돈벌기가 모두 같은 틀에 문구만 다르다.
/// [blue]면 해외 톤(파란 바탕·파란 버튼)이 된다.
class HeroCard extends StatelessWidget {
  /// 맨 위 작은 문구 (.h2-sub)
  final String sub;

  /// 제목 두 줄. `**`로 감싼 부분이 강조색이 된다. 예: `'무엇이든 부탁해요\n**가까운 이웃**이 도와드려요'`
  final String title;

  /// 제목 아래 한 줄 (.h2-live). 굵은 앞부분과 나머지로 나눈다. 비우면 그리지 않는다.
  final String? liveBold;
  final String? liveRest;

  /// 마스코트 주변에 떠 있는 아이콘 네 개 (.h2-f f1~f4)
  final List<String> floats;

  final String cta;
  final String ctaIcon;
  final VoidCallback onCta;
  final String note;
  final bool blue;

  /// 돈벌기처럼 마스코트를 조금 작게 그릴 때
  final bool compact;

  const HeroCard({
    super.key,
    required this.sub,
    required this.title,
    this.liveBold,
    this.liveRest,
    required this.floats,
    required this.cta,
    required this.ctaIcon,
    required this.onCta,
    required this.note,
    this.blue = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = blue ? AppColors.blue : AppColors.heroAccent;
    final subColor = blue ? AppColors.blue : AppColors.yellowDeep;
    final artH = compact ? 112.0 : 130.0;
    final mascotW = compact ? 124.0 : 148.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.surface),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.72],
          colors: [blue ? const Color(0xFFEEF4FF) : const Color(0xFFFFFBEA), AppColors.card],
        ),
      ),
      child: Column(children: [
        Text(sub, style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: subColor)),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(children: _spans(title, accent)),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -0.99, height: 1.35),
        ),
        if (liveBold != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: liveBold, style: const TextStyle(fontWeight: AppType.w600, color: AppColors.ink2)),
                    if (liveRest != null) TextSpan(text: ' $liveRest'),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.meta.copyWith(color: AppColors.sub),
                ),
              ),
            ]),
          ),
        const SizedBox(height: 6),
        SizedBox(
          width: 220,
          height: artH,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: (220 - mascotW) / 2, top: 0, child: Gyeomi(width: mascotW)),
            if (floats.isNotEmpty) _float(floats[0], 6, 30, 32, 16, accent),
            if (floats.length > 1) _float(floats[1], 184, 18, 32, 16, accent),
            if (floats.length > 2) _float(floats[2], 24, artH - 32, 26, 14, blue ? accent : AppColors.red),
            if (floats.length > 3) _float(floats[3], 172, artH - 38, 28, 14, accent),
          ]),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: blue ? const Color(0xB33A7BF5) : const Color(0x99C88C00),
                  blurRadius: 18,
                  spreadRadius: -8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: blue ? AppColors.blue : AppColors.yellow,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: onCta,
                borderRadius: BorderRadius.circular(15),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(AppIcon.data(ctaIcon), size: 18, color: blue ? Colors.white : AppColors.ink),
                  const SizedBox(width: 5),
                  Text(cta,
                      style: AppType.button.copyWith(fontSize: 16, fontWeight: AppType.w700, color: blue ? Colors.white : AppColors.ink)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(note, textAlign: TextAlign.center, style: AppType.meta.copyWith(color: AppColors.sub)),
      ]),
    );
  }

  Widget _float(String icon, double left, double top, double size, double iconSize, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: blue ? const Color(0x593A7BF5) : const Color(0x59B47800),
              blurRadius: 10,
              spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(AppIcon.data(icon), size: iconSize, color: color),
      ),
    );
  }

  /// `**강조**` 표기를 강조색 조각으로 나눈다.
  static List<TextSpan> _spans(String text, Color accent) {
    final parts = text.split('**');
    return [
      for (int i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty)
          TextSpan(text: parts[i], style: i.isOdd ? TextStyle(color: accent) : null),
    ];
  }
}
