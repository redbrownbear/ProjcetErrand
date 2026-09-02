import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../data/partner_missions.dart';
import '../widgets/earn_row_full.dart';

class EarnHubScreen extends StatefulWidget {
  final List<String> doneMissions;
  final VoidCallback onClose;
  final void Function(ScreenRoute) push;
  const EarnHubScreen({super.key, required this.doneMissions, required this.onClose, required this.push});
  @override
  State<EarnHubScreen> createState() => _EarnHubScreenState();
}

class _EarnHubScreenState extends State<EarnHubScreen> {
  String cat = 'all';

  @override
  Widget build(BuildContext context) {
    final list = missionsByCat(cat);
    final potential = partnerMissions.fold<int>(0, (s, m) => s + (widget.doneMissions.contains(m.id) ? 0 : m.points));
    final sorted = List.of(list)..sort((a, b) => b.points - a.points);

    return ScreenFrame(
      title: '부업',
      subtitle: '제휴 성과보상 · 행동하고 벌기',
      onBack: widget.onClose,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('지금 참여하면 받을 수 있는 포인트', style: TextStyle(fontSize: 12.5, color: Colors.white60)),
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text('+${nf(potential)}P', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.yellow))),
                ],
              ),
              const Text('💰', style: TextStyle(fontSize: 34)),
            ]),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(0, 8, 0, 4), child: Text('기업의 마케팅 비용을 내 부수입으로 — 브랜드 미션에 참여하고 포인트를 받으세요.', style: TextStyle(fontSize: 11.5, color: AppColors.sub))),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in missionCats)
                    Padding(padding: const EdgeInsets.only(right: 7), child: ChipWidget(label: c[1], active: cat == c[0], onTap: () => setState(() => cat = c[0]))),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text.rich(TextSpan(children: [
              const TextSpan(text: '오늘의 추천 부업 ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const TextSpan(text: '· 포인트 높은 순', style: TextStyle(fontSize: 11.5, color: AppColors.sub, fontWeight: FontWeight.w600)),
            ])),
          ),
          for (final m in sorted)
            EarnRowFull(m: m, done: widget.doneMissions.contains(m.id), onOpen: () => widget.push(ScreenRoute(name: 'mission', mission: m))),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(12)),
            child: const Text('광고·체험단 표기 등 관련 규정을 준수한 제휴 캠페인만 제공돼요. 지급 조건·시점은 제휴사 정책에 따라 달라질 수 있어요.', style: TextStyle(fontSize: 11.5, color: AppColors.purple, height: 1.6)),
          ),
        ],
      ),
    );
  }
}
