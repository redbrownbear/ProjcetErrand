import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/surface.dart';
import '../../errand/models/task_item.dart';
import '../../errand/navigation/errand_actions.dart';
import '../../gongu/repositories/gongu_repository.dart';
import '../../gongu/screens/gongu_detail_screen.dart';
import '../../gongu/screens/gongu_screen.dart';
import '../../gongu/widgets/gongu_grid.dart';
import '../../partner/screens/brand_hub_screen.dart';
import '../models/coupon.dart';
import '../models/partner_mission.dart';
import '../models/reward_ledger.dart';
import '../models/reward_product.dart';
import 'mission_tab.dart';

/// 하단 '미션·공구' 탭. 안쪽 밑줄 탭으로 미션([MissionTab])과 공동구매를 나눈다.
class SideJobView extends StatefulWidget {
  /// 처음 열 안쪽 탭 — 0 미션 · 1 공동구매
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
  });

  @override
  State<SideJobView> createState() => _SideJobViewState();
}

class _SideJobViewState extends State<SideJobView> {
  late int _sub = widget.initialSub;

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        UnderlineTabs(
          tabs: const [('미션', null), ('공동구매', null)],
          index: _sub,
          onChanged: (i) => setState(() => _sub = i),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          fontSize: 15.5,
          gap: 24,
        ),
        if (_sub == 0) MissionTab(view: widget) else _gongu(),
        _inquiry(),
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
