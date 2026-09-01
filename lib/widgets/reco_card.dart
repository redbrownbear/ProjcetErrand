import 'package:flutter/material.dart';

import '../data/countries.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import 'tag.dart';

/// 가로 스크롤용 추천 카드
class RecoCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  final bool done;
  const RecoCard({super.key, required this.it, required this.onOpen, this.done = false});

  @override
  Widget build(BuildContext context) {
    final sea = it.mode == 'sea';
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 166,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: it.hot ? AppColors.redSoft : AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 19,
              child: Row(children: [
                if (it.hot) ...[const Tag(label: '🔥 급해요', c: AppColors.red, bg: AppColors.redSoft), const SizedBox(width: 5)],
                if (sea) ...[Tag(label: '${countryOf(it.cc).flag} 해외', c: AppColors.purple, bg: AppColors.purpleSoft), const SizedBox(width: 5)],
                if (done) const Tag(label: '지원함', c: AppColors.green, bg: AppColors.greenSoft),
              ]),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: Text(it.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.35)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(sea ? (it.country ?? '') : '${distLabel(it)} · 약 ${it.mins}분', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(won(it.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                Text('★ ${it.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sub)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
