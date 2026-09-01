import 'package:flutter/material.dart';

import '../data/point_rules.dart';
import '../data/reward_products.dart';
import '../models/screen_route.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/screen_frame.dart';
import '../widgets/task_card.dart';
import '../widgets/walk_ring.dart';

class WalkScreen extends StatefulWidget {
  final List<TaskItem> items;
  final String scope;
  final int steps;
  final int points;
  final List<int> grabbed;
  final VoidCallback onClose;
  final void Function(int amt, String label) earn;
  final void Function(ScreenRoute) push;
  final void Function(TaskItem) openDetail;
  const WalkScreen({
    super.key, required this.items, required this.scope, required this.steps, required this.points,
    required this.grabbed, required this.onClose, required this.earn, required this.push, required this.openDetail,
  });
  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> {
  bool got = false;

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  @override
  Widget build(BuildContext context) {
    final claimable = walkClaimable(widget.steps);
    final goal = nextRewardGoal(widget.points);
    final near = widget.items.where((i) => i.mode == 'ask' && _inScope(i) && i.distM < 100000).toList()
      ..sort((a, b) => a.distM.compareTo(b.distM));
    final nearTop = near.take(4).toList();
    final next = nearTop.isNotEmpty ? nearTop.first : null;

    return ScreenFrame(
      title: '걷기 챌린지',
      subtitle: '걷다가 근처 부탁도 겸사겸사',
      onBack: widget.onClose,
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
                onTap: () {
                  if (!got) {
                    widget.earn(claimable, '걸음 적립');
                    setState(() => got = true);
                  }
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
                onTap: () => widget.push(const ScreenRoute(name: 'shop')),
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
                  Padding(padding: const EdgeInsets.only(top: 10), child: TaskCard(it: next, onOpen: () => widget.openDetail(next), done: widget.grabbed.contains(next.id))),
                ],
              ),
            ),
          const Padding(padding: EdgeInsets.fromLTRB(0, 14, 0, 4), child: Text('근처에서 할 수 있는 부탁', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink))),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(children: [for (final it in nearTop) TaskCard(it: it, onOpen: () => widget.openDetail(it), done: widget.grabbed.contains(it.id))]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton(
              onPressed: () => widget.push(const ScreenRoute(name: 'map')),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(double.infinity, 0)),
              child: const Text('🗺️ 지도에서 주변 부탁 보기', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
