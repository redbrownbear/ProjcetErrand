import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/task_item.dart';

/// "가는 길에 겸사겸사" 섹션의 대표 카드
class FeaturedCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  final bool done;
  const FeaturedCard({super.key, required this.it, required this.onOpen, this.done = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(7)),
                child: Text('지금 위치에서 ${distLabel(it)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              if (it.hot) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.red.withValues(alpha: .9), borderRadius: BorderRadius.circular(7)),
                  child: const Text('🔥 급해요', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            Text(it.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 5),
            Text('약 ${it.mins}분 · ${it.region ?? ''}', style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(won(it.price), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.yellow)),
                Text(done ? '지원함 ✓' : '겸사겸사 하기 ›', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
