import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/tag.dart';
import '../models/task_item.dart';

class NearbyCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  final bool done;
  const NearbyCard({super.key, required this.it, required this.onOpen, this.done = false});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 176,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              child: Row(children: [
                if (it.hot) const Tag(label: '🔥 급해요', c: AppColors.red, bg: AppColors.redSoft),
                if (it.hot && done) const SizedBox(width: 6),
                if (done) const Tag(label: '지원함', c: AppColors.green, bg: AppColors.greenSoft),
              ]),
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 44,
              child: Text(it.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.35)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('${distLabel(it)} · 약 ${it.mins}분', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
            ),
            Text(won(it.price), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
