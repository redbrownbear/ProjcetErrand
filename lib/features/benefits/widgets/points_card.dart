import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../data/reward_products.dart';

/// 보유 포인트 카드. 다음 교환 상품까지 남은 포인트를 막대로 보여 준다.
class PointsCard extends StatelessWidget {
  final int points;
  final VoidCallback onOpenShop;
  const PointsCard({super.key, required this.points, required this.onOpenShop});

  @override
  Widget build(BuildContext context) {
    final goal = nextRewardGoal(points);
    final progress = goal == null ? 1.0 : points / (points + goal.remain);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('보유 포인트', style: AppType.meta.copyWith(fontWeight: AppType.w500)),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: nf(points)),
                          const TextSpan(
                            text: 'P',
                            style: TextStyle(fontSize: 13, color: AppColors.yellowInk),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -0.72),
                    ),
                  ],
                ),
              ),
              _shopButton(),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              minHeight: 3,
              backgroundColor: AppColors.soft2,
              valueColor: const AlwaysStoppedAnimation(AppColors.yellow),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            goal == null ? '포인트샵의 모든 상품으로 바꿀 수 있어요' : '${nf(goal.remain)}P 더 모으면 ${goal.name}(으)로 바꿀 수 있어요',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _shopButton() {
    return Material(
      color: AppColors.page,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onOpenShop,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 30,
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '포인트샵',
                style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w600, color: AppColors.ink2),
              ),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.ink2),
            ],
          ),
        ),
      ),
    );
  }
}
