import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../errand/models/task_item.dart';
import '../../errand/navigation/errand_actions.dart';
import '../../errand/screens/map_screen.dart';
import '../../errand/widgets/task_card.dart';
import '../data/point_rules.dart';
import '../data/reward_products.dart';
import '../models/coupon.dart';
import '../models/reward_ledger.dart';
import '../models/reward_product.dart';
import '../widgets/walk_ring.dart';
import 'point_shop_screen.dart';

class WalkScreen extends StatefulWidget {
  final List<TaskItem> items;
  final String scope;
  final int steps;
  final int points;
  final List<Coupon> coupons;
  final ErrandActions actions;
  final EarnFn earn;
  final IsClaimedFn isClaimed;
  final void Function(RewardProduct) redeem;
  final void Function(int id) useCoupon;
  final VoidCallback goPointsHub;
  const WalkScreen({
    super.key, required this.items, required this.scope, required this.steps, required this.points, required this.coupons,
    required this.actions, required this.earn, required this.isClaimed, required this.redeem, required this.useCoupon, required this.goPointsHub,
  });
  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> {

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  @override
  Widget build(BuildContext context) {
    final claimable = walkClaimable(widget.steps);
    final got = widget.isClaimed(walkRewardKey);
    final goal = nextRewardGoal(widget.points);
    final near = widget.items.where((i) => i.mode == 'ask' && _inScope(i) && i.distSort < 100000).toList()
      ..sort((a, b) => a.distSort.compareTo(b.distSort));
    final nearTop = near.take(4).toList();
    final next = nearTop.isNotEmpty ? nearTop.first : null;

    return ScreenFrame(
      title: '걷기 챌린지',
      subtitle: '걷다가 근처 부탁도 겸사겸사',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Column(children: [
            WalkRing(steps: widget.steps, size: 140),
            Padding(padding: const EdgeInsets.only(top: 14), child: Text(nf(widget.steps), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ink))),
            Padding(padding: const EdgeInsets.only(top: 2), child: Text('목표 ${nf(walkGoal)}걸음', style: const TextStyle(fontSize: 13, color: AppColors.sub))),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: InkWell(
                onTap: () async {
                  if (got) return;
                  await widget.earn(claimable, '걸음 적립', key: walkRewardKey);
                  if (mounted) setState(() {}); // 원장이 바뀐 걸 이 화면에도 반영
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(color: got ? AppColors.page : AppColors.yellow, borderRadius: BorderRadius.circular(12)),
                  child: Text(got ? '오늘 적립 완료 ✓' : '+$claimable P 받기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: got ? AppColors.sub : AppColors.ink)),
                ),
              ),
            ),
          ]),
          if (goal != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PointShopScreen(
                  points: widget.points, redeem: widget.redeem, coupons: widget.coupons, useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
                ))),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
                  child: Text.rich(
                    TextSpan(style: const TextStyle(fontSize: 12.5, color: AppColors.ink), children: [
                      const TextSpan(text: '조금만 더 모으면 '),
                      TextSpan(text: goal.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      TextSpan(text: ' · ${nf(goal.remain)}P 남았어요 ›'),
                    ]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (next != null)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🚶 500m 더 걸으면 이 부탁도 할 수 있어요', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1B8A5A))),
                  Padding(padding: const EdgeInsets.only(top: 10), child: TaskCard(it: next, onOpen: () => widget.actions.open(context, next), done: widget.actions.grabbed.contains(next.id))),
                ],
              ),
            ),
          const Padding(padding: EdgeInsets.fromLTRB(0, 14, 0, 4), child: Text('근처에서 할 수 있는 부탁', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink))),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(children: [for (final it in nearTop) TaskCard(it: it, onOpen: () => widget.actions.open(context, it), done: widget.actions.grabbed.contains(it.id))]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(items: widget.items, scope: widget.scope, actions: widget.actions))),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(double.infinity, 0)),
              child: const Text('🗺️ 지도에서 주변 부탁 보기', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
