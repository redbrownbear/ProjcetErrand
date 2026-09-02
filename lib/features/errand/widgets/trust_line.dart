import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../models/task_item.dart';

class TrustLine extends StatelessWidget {
  final TaskItem it;
  const TrustLine({super.key, required this.it});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text('거래 ${it.deals}회', style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
        Text('·', style: const TextStyle(color: AppColors.faint)),
        Text('★ ${it.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w700)),
        if (it.verified) ...[
          const Text('·', style: TextStyle(color: AppColors.faint)),
          const Text('✓ 본인인증', style: TextStyle(fontSize: 11.5, color: AppColors.green, fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }
}
