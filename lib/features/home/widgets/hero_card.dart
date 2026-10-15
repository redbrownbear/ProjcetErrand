import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/gyeom_mascot.dart';
import '../../../core/widgets/kit.dart';

/// 방금 일어난 일 한 줄 (히어로의 초록 점 줄)
typedef LiveLine = ({String bold, String meta});

/// 탭 맨 위의 히어로 (.h2) — 같은 캐릭터 '겸이', 탭마다 다른 한 줄.
///
/// 캐릭터 옆 말풍선은 이달의 럭키드로우로 이어진다(시안 '겸이의 말풍선').
/// 해외 탭은 파란색이다.
class HeroCard extends StatefulWidget {
  final bool blue;
  final String sub;

  /// 제목 조각. true인 조각이 강조색으로 칠해진다.
  final List<(String, bool)> title;
  final List<LiveLine> live;
  final String drawLabel;
  final String bubbleSub;
  final VoidCallback onBubble;
  final String cta;
  final String ctaIcon;
  final VoidCallback onCta;
  final String note;
  final List<String> floats;

  const HeroCard({
    super.key,
    this.blue = false,
    required this.sub,
    required this.title,
    required this.live,
    required this.drawLabel,
    required this.bubbleSub,
    required this.onBubble,
    required this.cta,
    this.ctaIcon = 'plus',
    required this.onCta,
    required this.note,
    this.floats = const ['box', 'heart', 'pet'],
  });

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> {
  int live = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.live.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
        if (mounted) setState(() => live = (live + 1) % widget.live.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.blue ? AppColors.blue : AppColors.orange;
    final top = widget.blue ? AppColors.heroBlue : AppColors.heroYellow;
    final glow = widget.blue ? const Color(0x593A7BF5) : const Color(0x59B47800);
    final l = widget.live.isEmpty ? null : widget.live[live % widget.live.length];

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, Colors.white], stops: const [0, 0.7]),
        borderRadius: BorderRadius.circular(AppRadius.surface),
      ),
      child: Column(children: [
        Text(widget.sub, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.blue ? AppColors.blue : AppColors.yellowInk)),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(children: [
            for (final (t, on) in widget.title)
              TextSpan(text: t, style: on ? TextStyle(color: accent, fontWeight: FontWeight.w900) : null),
          ]),
          textAlign: TextAlign.center,
          style: AppType.hero,
        ),
        if (l != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Row(
                key: ValueKey(live),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: l.bold, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                        TextSpan(text: ' ${l.meta}'),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.sub),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        SizedBox(
          height: 130,
          child: LayoutBuilder(builder: (context, box) {
            final mx = (box.maxWidth / 2 - 66 - 34).clamp(36.0, double.infinity);
            return Stack(clipBehavior: Clip.none, children: [
              Positioned(left: mx, top: 0, child: const GyeomMascot(width: 132)),
              Positioned(left: mx - 32, top: 26, child: _float(widget.floats[0], 32, glow)),
              Positioned(left: mx - 6, bottom: 12, child: _float(widget.floats[1], 26, glow)),
              Positioned(left: mx + 126, bottom: 4, child: _float(widget.floats[2], 28, glow)),
              Positioned(right: -4, top: 2, child: _bubble()),
            ]);
          }),
        ),
        const SizedBox(height: 4),
        BigButton(
          label: widget.cta,
          icon: widget.ctaIcon,
          bg: widget.blue ? AppColors.blue : AppColors.yellow,
          fg: widget.blue ? Colors.white : AppColors.ink,
          glow: true,
          onTap: widget.onCta,
        ),
        const SizedBox(height: 9),
        Text(widget.note, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
      ]),
    );
  }

  Widget _float(String icon, double size, Color glow) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: glow, blurRadius: 10, spreadRadius: -4, offset: const Offset(0, 4))],
        ),
        child: AppIcon(icon, size: size * 0.5, color: widget.blue ? AppColors.blue : AppColors.orange),
      );

  Widget _bubble() => GestureDetector(
        onTap: widget.onBubble,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 176),
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.yellowLine),
            boxShadow: const [BoxShadow(color: Color(0x59785A00), blurRadius: 16, spreadRadius: -6, offset: Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.confirmation_number_outlined, size: 11, color: AppColors.yellowInk),
              const SizedBox(width: 3),
              Flexible(
                child: Text(widget.drawLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.yellowInk, letterSpacing: 0.3)),
              ),
            ]),
            const SizedBox(height: 2),
            const Text('도쿄 왕복 항공권 + 호텔 추첨 중!', maxLines: 2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 1),
            Text(widget.bubbleSub, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.sub)),
          ]),
        ),
      );
}
