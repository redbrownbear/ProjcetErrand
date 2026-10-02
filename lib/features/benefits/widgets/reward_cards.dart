import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../data/reward_brands.dart';
import '../models/reward_product.dart';

/// 인기 교환 상품의 작은 카드
class RewardMini extends StatelessWidget {
  final RewardProduct p;
  final int points;
  final VoidCallback onOpen;
  const RewardMini({super.key, required this.p, required this.points, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final b = brandOf(p.brand);
    final afford = points >= p.points;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(10)),
              child: AppIcon(b.icon, size: 26, color: AppColors.ink2),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                b.name,
                style: const TextStyle(fontSize: 11, color: AppColors.sub, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: SizedBox(
                height: 34,
                child: Text(
                  p.name,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.35),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Text(
              '${nf(p.points)}P',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: afford ? AppColors.ink : AppColors.faint),
            ),
          ],
        ),
      ),
    );
  }
}

/// 교환 상품 한 줄 — 찜 · 교환 · 모으기
class RewardCard extends StatelessWidget {
  final RewardProduct p;
  final int points;
  final bool wished;
  final VoidCallback onWish, onRedeem, onGather;
  const RewardCard({
    super.key,
    required this.p,
    required this.points,
    required this.wished,
    required this.onWish,
    required this.onRedeem,
    required this.onGather,
  });
  @override
  Widget build(BuildContext context) {
    final b = brandOf(p.brand);
    final afford = points >= p.points;
    final remain = p.points - points;
    final pct = (points / p.points).clamp(0, 1).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
                child: AppIcon(b.icon, size: 24, color: AppColors.ink2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          b.name,
                          style: const TextStyle(fontSize: 11, color: AppColors.sub, fontWeight: FontWeight.w700),
                        ),
                        if (p.hot) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(6)),
                            child: const Text(
                              '인기',
                              style: TextStyle(fontSize: 10, color: AppColors.red, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        const Spacer(),
                        InkWell(
                          onTap: onWish,
                          child: Icon(
                            wished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 17,
                            color: wished ? AppColors.red : AppColors.faint,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        p.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ),
                    Text(
                      '${nf(p.points)}P',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (afford)
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRedeem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    elevation: 0,
                  ),
                  child: const Text('교환하기', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.page,
                            color: AppColors.yellow,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pct * 100).round()}%',
                        style: const TextStyle(fontSize: 11, color: AppColors.sub, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 12, color: AppColors.sub),
                        children: [
                          TextSpan(
                            text: '${nf(remain)}P',
                            style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                          ),
                          const TextSpan(text: '만 더 모으면 교환할 수 있어요'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onGather,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                      child: const Text('포인트 모으러 가기 ›', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
