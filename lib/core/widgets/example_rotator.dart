import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_icon.dart';

/// 넘김 점
class PageDots extends StatelessWidget {
  final int count;
  final int index;
  const PageDots({super.key, required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: i == index ? 14 : 5,
            height: 5,
            decoration: BoxDecoration(
              color: i == index ? AppColors.ink : AppColors.soft2,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// '이런 것도 부탁해도 돼요' — 예시 한 줄이 몇 초마다 바뀐다.
///
/// 예시는 실제 부탁이 아니라 **이런 것도 올려도 된다는 안내**다. 누르면 부탁 쓰기로 간다.
class ExampleRotator extends StatefulWidget {
  final String question;
  final List<({String icon, String title, Color color})> items;
  final void Function(int index) onTap;
  final String footLabel;
  final VoidCallback onFoot;
  const ExampleRotator({
    super.key,
    required this.question,
    required this.items,
    required this.onTap,
    required this.footLabel,
    required this.onFoot,
  });

  @override
  State<ExampleRotator> createState() => _ExampleRotatorState();
}

class _ExampleRotatorState extends State<ExampleRotator> {
  int i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (mounted) setState(() => i = (i + 1) % widget.items.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.items[i];
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.question, style: AppType.sectionSmall.copyWith(fontSize: 15, letterSpacing: -0.6)),
          const SizedBox(height: 8),
          Material(
            color: AppColors.page,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: InkWell(
              onTap: () => widget.onTap(i),
              borderRadius: BorderRadius.circular(AppRadius.tile),
              child: SizedBox(
                height: 46,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    key: ValueKey(i),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(11)),
                          child: Icon(AppIcon.data(it.icon), size: 20, color: it.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            it.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.body.copyWith(fontSize: 13.5, fontWeight: AppType.w700, letterSpacing: -0.4),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          PageDots(count: widget.items.length, index: i),
          InkWell(
            onTap: widget.onFoot,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.footLabel,
                      textAlign: TextAlign.center,
                      style: AppType.meta.copyWith(fontWeight: AppType.w500, color: AppColors.sub),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.sub),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
