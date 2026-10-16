import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../../deals/screens/save_hub_screen.dart';
import '../../errand/models/task_item.dart';
import '../../errand/navigation/errand_actions.dart';
import '../../errand/screens/list_screen.dart';
import '../../errand/screens/overseas_screen.dart';
import '../../errand/widgets/task_card.dart';
import '../../gongu/screens/gongu_screen.dart';
import '../data/partner_missions.dart';
import '../data/point_rules.dart';
import '../models/partner_mission.dart';
import '../models/point_wallet.dart';
import '../models/reward_ledger.dart';
import '../widgets/benefits_parts.dart';
import '../widgets/partner_card.dart';
import 'earn_hub_screen.dart';
import 'my_coupons_screen.dart';
import 'partner_mission_detail_screen.dart';
import 'point_shop_screen.dart';

class BenefitsView extends StatefulWidget {
  final PointWallet wallet;
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;
  final int monthEarn;
  final int freeLeft;
  final List<String> doneMissions;
  final EarnFn earn;
  final IsClaimedFn isClaimed;
  final void Function(PartnerMission) completeMission;
  final VoidCallback goPointsHub;

  /// 하단 토스트. 일급·일당 지원처럼 아직 서버가 없는 동작의 안내에 쓴다.
  final void Function(String) flash;
  const BenefitsView({
    super.key,
    required this.wallet,
    required this.items,
    required this.scope,
    required this.actions,
    required this.monthEarn,
    required this.freeLeft,
    required this.doneMissions,
    required this.earn,
    required this.completeMission,
    required this.goPointsHub,
    required this.isClaimed,
    required this.flash,
    this.showHeader = true,
  });

  /// 마이 > 매일의 혜택처럼 화면 프레임이 제목을 그리는 경우 false.
  final bool showHeader;
  @override
  State<BenefitsView> createState() => _BenefitsViewState();
}

class _BenefitsViewState extends State<BenefitsView> {
  // 예전에는 여기서 출석·광고·프로필·친구초대 같은 미션을 `benefit:*` 키로 따로
  // 굴렸다. 전부 제휴사가 돈을 대지 않는 자체 지급이라, 사람이 늘수록 손실이
  // 정비례로 커지는 구조였다. 게다가 홈의 `daily:*` 미션과 항목이 겹쳐서
  // 어느 쪽이 진짜인지 코드만 봐서는 알 수 없었다.
  //
  // 지금은 미션을 [dailyMissions] 한 곳에서만 관리한다. 여기 남은 건 실제 값이
  // 있는 것(내 포인트·이번 달 수익·수수료 면제)과 제휴 캠페인 목록뿐이다.

  void _push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  /// 오늘 벌기 허브 (§15 1차 메뉴)
  void _openEarnHub() => _push(
    EarnHubScreen(
      doneMissions: widget.doneMissions,
      completeMission: widget.completeMission,
      onOpenErrand: () => _openList(title: '심부름으로 벌기', subtitle: '지역 픽업 · 개인/기업 심부름'),
      onApplyDayJob: (j) => widget.flash('${j.org}에 지원 의사를 전달했어요 · 근로계약은 구인업체와 진행돼요'),
    ),
  );

  /// 생활비 아끼기 허브 (§15 1차 메뉴)
  void _openSaveHub() => _push(
    SaveHubScreen(
      earn: widget.earn,
      isClaimed: widget.isClaimed,
      onUse: (d) => widget.flash('${d.brand} 회원 전용가를 준비 중이에요 · 제휴 확정 후 열려요'),
    ),
  );

  /// 돈벌기 부탁 목록. '근처에서 벌기'는 가까운 순으로 연다.
  void _openList({required String title, required String subtitle, String? defaultSort}) => _push(
    ListScreen(
      config: ScreenRoute(
        name: 'list',
        title: title,
        subtitle: subtitle,
        base: 'earn',
        sortable: true,
        defaultSort: defaultSort,
        catChips: true,
        mapBtn: true,
      ),
      items: widget.items,
      scope: widget.scope,
      actions: widget.actions,
    ),
  );

  Widget _missionRowScroll(String cat) {
    final list = missionsByCat(cat);
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = list[i];
          return PartnerCard(
            m: m,
            done: widget.doneMissions.contains(m.id),
            onOpen: () => _push(
              PartnerMissionDetailScreen(m: m, done: widget.doneMissions.contains(m.id), onComplete: widget.completeMission),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // '근처에서 벌기'는 지금 지원할 수 있는 동네 부탁만. 예전엔 해외 부탁·마감된 부탁도 섞였다.
    final nearby = widget.items.where((it) => it.mode == 'ask' && !it.isExpired).take(2).toList();
    final seaCount = widget.items.where((it) => it.mode == 'sea').length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 26),
      children: [
        if (widget.showHeader) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 2),
            child: Text(
              '혜택',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text('오늘 내가 더 벌 수 있는 방법', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
          ),
        ],

        BenefitsWalletCard(
          points: widget.wallet.points,
          liveCoupons: widget.wallet.liveCoupons,
          onOpenShop: () => _push(PointShopScreen(wallet: widget.wallet, goPointsHub: widget.goPointsHub)),
          onOpenCoupons: () => _push(MyCouponsScreen(wallet: widget.wallet, goPointsHub: widget.goPointsHub)),
        ),

        // 이번 달 수익. 옆에 있던 '이번 달 적립(P)'은 뺐다 — 셸이 늘 0을 넘기고
        // 있어서 아무 값도 못 보여주는 칸이었다. 포인트 원장을 월별로 집계할 수
        // 있게 되면 그때 되살린다.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이번 달 겸사 수익', style: TextStyle(fontSize: 11, color: AppColors.sub)),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '+${nf(widget.monthEarn)}원',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.freeLeft > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const AppIcon('sparkles', size: 13, color: AppColors.ink2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '신규 첫 3거래 수수료 0% · 남은 무료 거래 ${widget.freeLeft}회',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.yellowDeep),
                  ),
                ),
              ],
            ),
          ),

        BenefitsSecTitle(
          '근처에서 벌기',
          action: InkWell(
            onTap: () => _openList(title: '근처에서 벌기', subtitle: '가까운 순', defaultSort: 'dist'),
            child: const Text(
              '더 보기 ›',
              style: TextStyle(color: AppColors.sub, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final it in nearby)
                TaskCard(it: it, onOpen: () => widget.actions.open(context, it), done: widget.actions.grabbed.contains(it.id)),
            ],
          ),
        ),

        // 걷기 적립(WalkRing·WalkScreen)은 재원이 없어 화면에서 내렸다.
        // 출석은 홈의 달력 카드 한 곳으로 모았다. 여기서 또 받을 수 있으면 같은 보상 진입점이 두 곳이 된다.
        HubEntryCard(
          icon: 'bag',
          title: '같이 사고 벌기 · 공동구매',
          sub: '공구를 안 만들어도 — 추천으로 같이 사면 보상',
          action: '공구 보기',
          tint: AppColors.yellowSoft,
          onTap: () => _push(GonguScreen(earn: widget.earn, isClaimed: widget.isClaimed)),
        ),
        HubEntryCard(icon: 'ticket', title: '생활비 아끼기 · 회원 전용가', sub: '지역업체 · 프랜차이즈 · 공동구매 · 생활서비스', onTap: _openSaveHub),
        HubEntryCard(
          icon: 'brief',
          title: '부업 · 제휴 성과보상',
          sub: '가입·콘텐츠·의견·방문을 한곳에서',
          action: '전체보기',
          dark: true,
          onTap: _openEarnHub,
        ),

        const BenefitsSecTitle('가입하고 벌기', sub: '카드·통신·서비스 가입 등'),
        _missionRowScroll('signup'),
        const BenefitsSecTitle('콘텐츠로 벌기', sub: '블로그·SNS·리뷰 콘텐츠로 사례비'),
        _missionRowScroll('blog'),
        const BenefitsSecTitle('의견 주고 벌기', sub: '설문·인터뷰·좌담회·UX 테스트'),
        _missionRowScroll('survey'),
        const BenefitsSecTitle('방문하고 벌기', sub: '가는 길에 들러서'),
        _missionRowScroll('visit'),

        const BenefitsSecTitle('여행하며 벌기'),
        InkWell(
          onTap: () => _push(OverseasScreen(items: widget.items, actions: widget.actions)),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // '도쿄에서 14개'는 어디에도 없는 숫자였다. 실제 목록에서 센다.
                Text(
                  '여행 가는 김에, ${won(seaMin)}부터',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    seaCount > 0 ? '지금 올라온 해외 부탁 $seaCount개 · 보러 가기 ›' : '해외 부탁 보러 가기 ›',
                    style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: .9)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
