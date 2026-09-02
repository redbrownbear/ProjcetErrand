import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/tag.dart';
import '../../errand/models/task_item.dart';
import '../data/categories.dart';

/// 같이해요 피드 카드
class CommunityCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  final bool compact;
  const CommunityCard({super.key, required this.it, required this.onOpen, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final t = tcatOf(it.tcat);
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 30, height: 30, alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
                child: const Text('🙂', style: TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                        children: [
                          TextSpan(text: it.who),
                          if (it.verified) const TextSpan(text: ' ✓', style: TextStyle(fontSize: 11, color: AppColors.green)),
                        ],
                      ),
                    ),
                    Text('${shortRegion(it.region ?? '')} · ${it.ago ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.faint)),
                  ],
                ),
              ),
              Tag(label: '${t.icon} ${t.label}', c: AppColors.sub, bg: AppColors.page),
            ]),
            const SizedBox(height: 8),
            Text(it.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(it.desc, style: const TextStyle(fontSize: 13, color: AppColors.sub, height: 1.5)),
            ],
            Padding(
              padding: EdgeInsets.only(top: compact ? 2 : 8),
              child: Row(children: [
                Text('🙋 관심 ${it.likes}', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                const SizedBox(width: 12),
                Text('💬 ${it.comments.length}', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                if (it.joinMax > 0) ...[
                  const SizedBox(width: 12),
                  Text('참여 ${it.joinCur}/${it.joinMax}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green)),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
