import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../models/gongu.dart';

/// 공동구매 상품 2열 격자
class GonguGrid extends StatelessWidget {
  final List<Gongu> items;
  final void Function(Gongu) onOpen;
  const GonguGrid({super.key, required this.items, required this.onOpen});

  /// 카드 바탕색·아이콘색. 순서대로 돌려 쓴다.
  static const _tones = [
    (Color(0xFFEAF4F4), Color(0xFF1D7E7E)),
    (Color(0xFFFFF1DC), Color(0xFFB26A00)),
    (Color(0xFFF1EEFF), Color(0xFF5B4BE0)),
    (Color(0xFFFFF0E3), Color(0xFFDA7419)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
        mainAxisExtent: 262,
      ),
      itemBuilder: (_, i) => _GonguCard(g: items[i], tone: _tones[i % _tones.length], onTap: () => onOpen(items[i])),
    );
  }
}

/// 위는 그림 칸, 아래는 할인율·가격·모집 막대
class _GonguCard extends StatelessWidget {
  final Gongu g;
  final (Color, Color) tone;
  final VoidCallback onTap;
  const _GonguCard({required this.g, required this.tone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final off = g.list <= 0 ? 0 : ((1 - g.price / g.list) * 100).round();
    final ratio = g.target <= 0 ? 0.0 : (g.joined / g.target).clamp(0, 1).toDouble();
    final (bg, fg) = tone;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
              child: Stack(
                children: [
                  Center(child: Icon(AppIcon.data(g.icon), size: 44, color: fg)),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        g.brand,
                        style: AppType.caption.copyWith(fontSize: 10, fontWeight: AppType.w600, color: AppColors.ink2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            g.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w600),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                if (off > 0)
                  TextSpan(
                    text: '$off% ',
                    style: const TextStyle(color: AppColors.red),
                  ),
                TextSpan(text: nf(g.price)),
                TextSpan(
                  text: ' ${nf(g.list)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: AppType.w400,
                    color: AppColors.faint,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 15, fontWeight: AppType.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 3,
              backgroundColor: AppColors.soft2,
              valueColor: const AlwaysStoppedAnimation(AppColors.ink),
            ),
          ),
          const SizedBox(height: 5),
          Text('${g.joined}/${g.target}명 모집', style: AppType.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
