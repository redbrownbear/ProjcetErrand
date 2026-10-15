import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/surface.dart';
import '../../errand/models/task_item.dart';
import '../../errand/navigation/errand_actions.dart';
import '../../gongu/repositories/gongu_repository.dart';
import '../../gongu/screens/gongu_detail_screen.dart';
import '../../gongu/screens/gongu_screen.dart';
import '../../gongu/widgets/gongu_grid.dart';
import '../../lucky/widgets/lucky_banner.dart';
import '../../market/widgets/used_list.dart';
import '../../partner/screens/brand_hub_screen.dart';
import '../models/coupon.dart';
import '../models/partner_mission.dart';
import '../models/reward_ledger.dart';
import '../models/reward_product.dart';
import 'mission_tab.dart';

/// 하단 '마켓' 탭 (v77 — 예전 '미션·공구').
///
/// 안쪽 밑줄 탭으로 미션([MissionTab]) · 공동구매 · 중고장터 · 나눔을 나눈다.
/// 미션·공동구매 위에는 이달의 럭키드로우 띠가 붙는다.
class SideJobView extends StatefulWidget {
  /// 처음 열 안쪽 탭 — 0 미션 · 1 공동구매 · 2 중고장터 · 3 나눔
  final int initialSub;
  final int points;
  final List<Coupon> coupons;
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;
  final int monthEarn;
  final int freeLeft;
  final List<String> doneMissions;
  final EarnFn earn;
  final IsClaimedFn isClaimed;
  final void Function(RewardProduct) redeem;
  final void Function(int id) useCoupon;
  final void Function(PartnerMission) completeMission;
  final VoidCallback goPointsHub;
  final void Function(String) flash;

  /// 럭키드로우 · 중고 · 나눔으로 가는 길 (v77)
  final AppNav social;

  const SideJobView({
    super.key,
    this.initialSub = 0,
    required this.points,
    required this.coupons,
    required this.items,
    required this.scope,
    required this.actions,
    required this.monthEarn,
    required this.freeLeft,
    required this.doneMissions,
    required this.earn,
    required this.isClaimed,
    required this.redeem,
    required this.useCoupon,
    required this.completeMission,
    required this.goPointsHub,
    required this.flash,
    required this.social,
  });

  @override
  State<SideJobView> createState() => _SideJobViewState();
}

class _SideJobViewState extends State<SideJobView> {
  late int _sub = widget.initialSub;

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final market = _sub >= 2; // 중고장터 · 나눔은 흰 바탕 목록
    return Stack(
      children: [
        if (market) const Positioned.fill(child: ColoredBox(color: AppColors.card)),
        ListView(
          padding: EdgeInsets.only(bottom: market ? 90 : 24),
          children: [
            if (!market) LuckyBanner(nav: widget.social),
            UnderlineTabs(
              tabs: const [('미션', null), ('공동구매', null), ('중고장터', null), ('나눔', null)],
              index: _sub,
              onChanged: (i) => setState(() => _sub = i),
              margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              fontSize: 15.5,
              gap: 20,
            ),
            switch (_sub) {
              0 => MissionTab(view: widget),
              1 => _gongu(),
              2 => UsedTab(nav: widget.social, items: widget.items),
              _ => ShareTab(nav: widget.social),
            },
            if (!market) _inquiry(),
          ],
        ),
        if (market)
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton(
              heroTag: 'used-fab',
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.ink,
              elevation: 3,
              shape: const CircleBorder(),
              tooltip: _sub == 3 ? '나눔 올리기' : '판매 올리기',
              onPressed: () => widget.social.openUsedForm(context, share: _sub == 3),
              child: const Icon(Icons.add_rounded, size: 30),
            ),
          ),
      ],
    );
  }

  Widget _gongu() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 14, 4),
          child: Row(
            children: [
              Expanded(
                child: Text('모집 인원이 늘수록 보상이 커져요', style: AppType.meta.copyWith(fontWeight: AppType.w500)),
              ),
              TextLink(
                label: '이용 안내',
                onTap: () => _push(GonguScreen(earn: widget.earn, isClaimed: widget.isClaimed)),
              ),
            ],
          ),
        ),
        SecCard(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: GonguGrid(
            items: LocalGonguRepository().fetchItems(),
            onOpen: (g) => _push(GonguDetailScreen(g: g, earn: widget.earn, isClaimed: widget.isClaimed)),
          ),
        ),
      ],
    );
  }

  Widget _inquiry() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: InkWell(
        onTap: () => _push(const BrandHubScreen()),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              Expanded(
                child: Text('브랜드·가게 제휴 문의', style: AppType.meta.copyWith(fontWeight: AppType.w700)),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.sub),
            ],
          ),
        ),
      ),
    );
  }
}
