import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../models/task_item.dart';

class TogetherRow extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  const TogetherRow({super.key, required this.it, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            Container(
              width: 40, height: 40, alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
              child: const Text('🎬', style: TextStyle(fontSize: 19)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('${it.place ?? ''} · ${it.extra ?? '무료 동행'}', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                ],
              ),
            ),
            const Text('무료', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.sub)),
          ],
        ),
      ),
    );
  }
}
