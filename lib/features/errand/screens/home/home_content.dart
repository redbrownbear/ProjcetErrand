import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/surface.dart';
import '../../../benefits/models/coupon.dart';
import '../../../benefits/models/partner_mission.dart';
import '../../../benefits/models/reward_ledger.dart';
import '../../../benefits/models/reward_product.dart';
import '../../models/task_item.dart';
import '../../navigation/errand_actions.dart';
import 'ask_tab.dart';
import 'earn_tab.dart';
import 'home_nav.dart';
import '../../services/nearby_query.dart';

/// 홈. 맨 위 '부탁하기 | 돈벌기' 전환으로 두 갈래를 나눈다.
///
/// - 부탁하기: [HomeAskTab]
/// - 돈벌기: [HomeEarnTab]
///
/// 여기서는 지금 어느 갈래인지와 '지금 내 주변 부탁'의 조건([NearbyQuery])만 들고 있다.
/// 갈래를 오가도 조건이 유지되도록 조건을 탭이 아니라 이쪽에 둔다.
class HomeContent extends StatefulWidget {
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;

  /// 리워드 포인트(P)
  final int points;
  final int steps;

  /// 이번 달 완료한 부탁의 사례비(원)
  final int monthEarn;

  final VoidCallback goPay;
  final VoidCallback goProfile;

  final List<Coupon> coupons;
  final List<String> doneMissions;
  final EarnFn earn;
  final IsClaimedFn isClaimed;
  final void Function(RewardProduct) redeem;
  final void Function(int id) useCoupon;
  final void Function(PartnerMission) completeMission;
  final void Function(String) flash;
  final VoidCallback goPointsHub;

  /// 부탁하기 — 갈래(동네·해외·단기알바)부터 고른다
  final VoidCallback goPost;

  /// 종류를 정해 둔 동네 부탁 쓰기 / 해외 부탁 쓰기
  final void Function(String cat) goPostCat;
  final VoidCallback goPostSea;

  /// 하단 탭 전환 — 해외 · 미션·공구(0 미션, 1 공동구매)
  final VoidCallback goOverseasTab;
  final void Function(int sub) goSideTab;

  /// 진행 중인 지원 건수
  final int activeCount;
  final VoidCallback goActivity;

  /// 단기알바 모집 등록
  final VoidCallback openJobPost;

  const HomeContent({
    super.key,
    required this.items,
    required this.scope,
    required this.actions,
    required this.points,
    required this.steps,
    required this.monthEarn,
    required this.goPay,
    required this.goProfile,
    required this.coupons,
    required this.doneMissions,
    required this.isClaimed,
    required this.earn,
    required this.redeem,
    required this.useCoupon,
    required this.completeMission,
    required this.flash,
    required this.goPointsHub,
    required this.goPost,
    required this.goPostCat,
    required this.goPostSea,
    required this.goOverseasTab,
    required this.goSideTab,
    required this.activeCount,
    required this.goActivity,
    required this.openJobPost,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _earning = false;
  NearbyQuery _query = const NearbyQuery();
  final _nearbyKey = GlobalKey();

  /// 돈벌기로 넘어가 '지금 내 주변 부탁'까지 스크롤한다.
  void _showNearby([String? kind]) {
    setState(() {
      _earning = true;
      if (kind != null) _query = _query.copyWith(kind: kind, showMap: false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _nearbyKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = HomeNav(context, widget);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SegToggle(labels: const ['부탁하기', '돈벌기'], index: _earning ? 1 : 0, onChanged: (i) => setState(() => _earning = i == 1)),
        if (widget.activeCount > 0) _ActiveBanner(count: widget.activeCount, onTap: widget.goActivity),
        if (_earning)
          HomeEarnTab(
            home: widget,
            nav: nav,
            query: _query,
            onQuery: (q) => setState(() => _query = q),
            nearbyKey: _nearbyKey,
            onShowNearby: _showNearby,
          )
        else
          HomeAskTab(home: widget, nav: nav, onShowNearby: _showNearby),
      ],
    );
  }
}

/// 진행 중 배너 — 지원한 부탁이 있을 때만 보인다.
class _ActiveBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ActiveBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                const IconTile(icon: 'clipboard', bg: AppColors.yellowSoft, fg: AppColors.yellowInk, size: 36, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '진행 중 '),
                        TextSpan(
                          text: '$count건',
                          style: const TextStyle(color: AppColors.heroAccent),
                        ),
                        const TextSpan(
                          text: ' · 다음 할 일 확인',
                          style: TextStyle(fontWeight: AppType.w500, color: AppColors.sub),
                        ),
                      ],
                    ),
                    style: AppType.body.copyWith(fontWeight: AppType.w700),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
