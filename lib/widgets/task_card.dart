import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import 'tag.dart';
import 'trust_line.dart';

class TaskCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  final bool done;
  const TaskCard({super.key, required this.it, required this.onOpen, this.done = false});
  @override
  Widget build(BuildContext context) {
    final sea = it.mode == 'sea';
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: it.hot ? AppColors.redSoft : AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (it.hot) ...[
                  const Tag(label: '🔥 급해요', c: AppColors.red, bg: AppColors.redSoft),
                  const SizedBox(width: 6),
                ],
                if (sea) ...[
                  const Tag(label: '해외대행', c: AppColors.purple, bg: AppColors.purpleSoft),
                  const SizedBox(width: 6),
                ],
                Tag(label: catOf(it.cat).label, c: AppColors.sub, bg: AppColors.page),
                if (done) ...[
                  const Spacer(),
                  const Text('지원함', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.green)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(it.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.35)),
            const SizedBox(height: 6),
            Text(metaOf(it), style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
            Container(
              margin: const EdgeInsets.only(top: 13),
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: TrustLine(it: it)),
                  Text(won(it.price), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
