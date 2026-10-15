import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/surface.dart';
import '../../../data/categories.dart';
import '../../../models/task_item.dart';
import 'home_buttons.dart';

/// '이거 하나 하고 갈래요?' — 주변 부탁을 한 장씩 넘겨 본다.
class PickCarousel extends StatefulWidget {
  final List<TaskItem> picks;
  final void Function(TaskItem) onOpen;
  const PickCarousel({super.key, required this.picks, required this.onOpen});

  @override
  State<PickCarousel> createState() => _PickCarouselState();
}

class _PickCarouselState extends State<PickCarousel> {
  final _ctrl = PageController();
  int _index = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go(int i) => _ctrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final picks = widget.picks;
    final idx = _index.clamp(0, picks.length - 1);
    return SecCard(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text('이거 하나 하고 갈래요?', style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600)),
                ),
                Text('${idx + 1} / ${picks.length}', style: AppType.meta.copyWith(color: AppColors.faint)),
                const SizedBox(width: 6),
                RoundArrowButton(icon: Icons.chevron_left_rounded, enabled: idx > 0, onTap: () => _go(idx - 1)),
                const SizedBox(width: 4),
                RoundArrowButton(icon: Icons.chevron_right_rounded, enabled: idx < picks.length - 1, onTap: () => _go(idx + 1)),
              ],
            ),
          ),
          SizedBox(
            height: 97,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: picks.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _PickCard(it: picks[i], onOpen: () => widget.onOpen(picks[i])),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  const _PickCard({required this.it, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final where = [catOf(it.cat).label, it.place ?? it.region ?? '', if (it.sample) '예시'].where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CatEmblem(cat: it.cat, size: 22, radius: 7, iconSize: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    where,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.meta.copyWith(fontWeight: AppType.w500),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                it.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body.copyWith(fontSize: 16, fontWeight: AppType.w700, letterSpacing: -0.56),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '+${nf(it.price)}'),
                      const TextSpan(text: '원', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  style: const TextStyle(fontSize: 18, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -0.54),
                ),
                const Spacer(),
                MetaChip(icon: Icons.schedule_rounded, label: '약 ${it.mins > 0 ? it.mins : 10}분'),
                const SizedBox(width: 6),
                MetaChip(icon: Icons.place_outlined, label: distLabel(it)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
