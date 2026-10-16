import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../data/point_rules.dart';
import '../data/reward_products.dart';

/// 혜택 화면 맨 위 — 내 포인트, 다음 교환 상품까지 남은 포인트, 포인트샵·내 쿠폰 버튼.
class BenefitsWalletCard extends StatelessWidget {
  final int points;
  final int liveCoupons;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenCoupons;

  const BenefitsWalletCard({
    super.key,
    required this.points,
    required this.liveCoupons,
    required this.onOpenShop,
    required this.onOpenCoupons,
  });

  @override
  Widget build(BuildContext context) {
    final goal = nextRewardGoal(points);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // '오늘 최대 +8,430P'를 옆에 띄우던 자리였다. 근거 없는 숫자였고,
          // 실제로 받을 수 있는 양은 제휴 연동 상태에 따라 매일 달라진다.
          // 그 계산은 [MissionEngine.remainToday]가 하고 미션 화면에서 보여 준다.
          const Text('내 포인트', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${nf(points)}P',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.yellow),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: goal != null
                ? Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                      children: [
                        TextSpan(text: '${goal.name}까지 '),
                        TextSpan(
                          text: '${nf(goal.remain)}P',
                          style: const TextStyle(color: AppColors.yellow),
                        ),
                        const TextSpan(text: ' 남았어요'),
                      ],
                    ),
                  )
                : const Text('1P ≈ $pointValue원처럼 쓸 수 있어요', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 14,
                  child: ElevatedButton(
                    onPressed: onOpenShop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      elevation: 0,
                    ),
                    child: const Text('포인트 사용하기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 10,
                  child: OutlinedButton(
                    onPressed: onOpenCoupons,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: Text(
                      '내 쿠폰${liveCoupons > 0 ? ' $liveCoupons' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
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

/// 다른 허브로 들어가는 큰 줄 — 아이콘 칸 · 제목 · 한 줄 설명 · 오른쪽 버튼(또는 ›).
///
/// 공동구매 · 생활비 아끼기 · 부업 세 진입점이 색만 다르고 모양이 같아 하나로 묶었다.
class HubEntryCard extends StatelessWidget {
  final String icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  /// 오른쪽 작은 버튼 글자. 없으면 '›'만 그린다.
  final String? action;

  /// 어두운 바탕(부업 허브)이면 true
  final bool dark;

  /// 밝은 바탕일 때의 배경. null이면 흰 카드에 테두리.
  final Color? tint;

  const HubEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    this.action,
    this.dark = false,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.ink : (tint ?? AppColors.card);
    final iconBg = dark ? const Color(0xFF2A2C30) : (tint == null ? AppColors.yellowSoft : Colors.white);
    final subColor = dark ? Colors.white.withValues(alpha: .6) : (tint == null ? AppColors.sub : AppColors.yellowDeep);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: tint == null && !dark
                ? BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: AppIcon(icon, size: 19, color: dark ? Colors.white : AppColors.ink2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: dark ? Colors.white : AppColors.ink),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(sub, style: TextStyle(fontSize: 11.5, color: subColor)),
                      ),
                    ],
                  ),
                ),
                if (action == null)
                  const Text('›', style: TextStyle(fontSize: 20, color: AppColors.faint))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: dark ? AppColors.yellow : AppColors.ink,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      action!,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: dark ? AppColors.ink : Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 섹션 제목 — 굵은 제목 옆에 작은 설명, 오른쪽에 '더 보기' 같은 버튼.
class BenefitsSecTitle extends StatelessWidget {
  final String title;
  final String? sub;
  final Widget? action;
  const BenefitsSecTitle(this.title, {super.key, this.sub, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  if (sub != null)
                    TextSpan(
                      text: '  $sub',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.sub),
                    ),
                ],
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
