import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../errand/models/task_item.dart';
import '../../errand/navigation/errand_actions.dart';
import '../../errand/screens/list_screen.dart';
import '../../errand/screens/overseas_screen.dart';
import '../../errand/widgets/task_card.dart';
import '../data/partner_missions.dart';
import '../data/point_rules.dart';
import '../data/reward_products.dart';
import '../models/coupon.dart';
import '../models/reward_ledger.dart';
import '../models/partner_mission.dart';
import '../models/reward_product.dart';
import '../widgets/partner_card.dart';
import '../../deals/screens/save_hub_screen.dart';
import '../../gongu/screens/gongu_screen.dart';
import 'earn_hub_screen.dart';
import 'my_coupons_screen.dart';
import 'partner_mission_detail_screen.dart';
import 'point_shop_screen.dart';

class BenefitsView extends StatefulWidget {
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

  /// 하단 토스트. 일급·일당 지원처럼 아직 서버가 없는 동작의 안내에 쓴다.
  final void Function(String) flash;
  const BenefitsView({
    super.key,
    required this.points,
    required this.coupons,
    required this.items,
    required this.scope,
    required this.actions,
    required this.monthEarn,
    required this.freeLeft,
    required this.doneMissions,
    required this.earn,
    required this.redeem,
    required this.useCoupon,
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

  Widget _secTitle(String t, {String? sub, Widget? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
              if (sub != null) TextSpan(text: '  $sub', style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
            ])),
          ),
          ?action,
        ],
      ),
    );
  }

  /// 오늘 벌기 허브 (§15 1차 메뉴)
  void _openEarnHub() => Navigator.push(context, MaterialPageRoute(builder: (_) => EarnHubScreen(
        doneMissions: widget.doneMissions,
        completeMission: widget.completeMission,
        onOpenErrand: _openEarnList,
        onApplyDayJob: (j) => widget.flash('${j.org}에 지원 의사를 전달했어요 · 근로계약은 구인업체와 진행돼요'),
      )));

  /// 생활비 아끼기 허브 (§15 1차 메뉴)
  void _openSaveHub() => Navigator.push(context, MaterialPageRoute(builder: (_) => SaveHubScreen(
        earn: widget.earn,
        isClaimed: widget.isClaimed,
        onUse: (d) => widget.flash('${d.brand} 회원 전용가를 준비 중이에요 · 제휴 확정 후 열려요'),
      )));

  void _openEarnList() => Navigator.push(context, MaterialPageRoute(builder: (_) => ListScreen(
        config: const ScreenRoute(name: 'list', title: '심부름으로 벌기', subtitle: '지역 픽업 · 개인/기업 심부름', base: 'earn', sortable: true, catChips: true, mapBtn: true),
        items: widget.items, scope: widget.scope, actions: widget.actions,
      )));

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
            m: m, done: widget.doneMissions.contains(m.id),
            onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerMissionDetailScreen(
              m: m, done: widget.doneMissions.contains(m.id), onComplete: widget.completeMission,
            ))),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = nextRewardGoal(widget.points);
    final liveCoupons = widget.coupons.where((c) => !c.used).length;
    final nearby = widget.items.where((it) => it.mode != 'together').take(2).toList();
    final seaCount = widget.items.where((it) => it.mode == 'sea').length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 26),
      children: [
        if (widget.showHeader) ...[
          const Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 2), child: Text('혜택', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink))),
          const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 4), child: Text('오늘 내가 더 벌 수 있는 방법', style: TextStyle(fontSize: 12.5, color: AppColors.sub))),
        ],

        // 내 포인트 + 오늘 예상
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // '오늘 최대 +8,430P'를 옆에 띄우던 자리였다. 근거 없는 숫자였고,
              // 실제로 받을 수 있는 양은 제휴 연동 상태에 따라 매일 달라진다.
              // 그 계산은 [MissionEngine.remainToday]가 하고 미션 화면에서 보여 준다.
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('내 포인트', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text('${nf(widget.points)}P', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.yellow))),
                  ],
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: goal != null
                    ? Text.rich(TextSpan(style: const TextStyle(fontSize: 11.5, color: Colors.white60), children: [
                        TextSpan(text: '${goal.name}까지 '),
                        TextSpan(text: '${nf(goal.remain)}P', style: const TextStyle(color: AppColors.yellow)),
                        const TextSpan(text: ' 남았어요'),
                      ]))
                    : Text('1P ≈ $pointValue원처럼 쓸 수 있어요', style: const TextStyle(fontSize: 11.5, color: Colors.white54)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(children: [
                  Expanded(
                    flex: 14,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PointShopScreen(
                        points: widget.points, redeem: widget.redeem, coupons: widget.coupons, useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
                      ))),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), elevation: 0),
                      child: const Text('포인트 사용하기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 10,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyCouponsScreen(
                        coupons: widget.coupons, useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
                      ))),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                      child: Text('🎟 내 쿠폰${liveCoupons > 0 ? ' $liveCoupons' : ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),

        // 이번 달 수익. 옆에 있던 '이번 달 적립(P)'은 뺐다 — 셸이 늘 0을 넘기고
        // 있어서 아무 값도 못 보여주는 칸이었다. 포인트 원장을 월별로 집계할 수
        // 있게 되면 그때 되살린다.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이번 달 겸사 수익', style: TextStyle(fontSize: 11, color: AppColors.sub)),
                Padding(padding: const EdgeInsets.only(top: 3), child: Text('+${nf(widget.monthEarn)}원', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink))),
              ],
            ),
          ),
        ),
        if (widget.freeLeft > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Text('🎉', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(child: Text('신규 첫 3거래 수수료 0% · 남은 무료 거래 ${widget.freeLeft}회', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.yellowDeep))),
            ]),
          ),

        // A. 근처에서 벌기
        _secTitle('📍 근처에서 벌기',
            action: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ListScreen(
                config: const ScreenRoute(name: 'list', title: '근처에서 벌기', subtitle: '가까운 순', base: 'earn', sortable: true, defaultSort: 'dist', catChips: true, mapBtn: true),
                items: widget.items, scope: widget.scope, actions: widget.actions,
              ))),
              child: const Text('더 보기 ›', style: TextStyle(color: AppColors.sub, fontSize: 12, fontWeight: FontWeight.w700)),
            )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [for (final it in nearby) TaskCard(it: it, onOpen: () => widget.actions.open(context, it), done: widget.actions.grabbed.contains(it.id))])),

        // 걷기 적립(WalkRing·WalkScreen)은 재원이 없어 화면에서 내렸다.
        // 출석은 홈의 달력 카드 한 곳으로 모았다. (시안 `gyumsa-refined`)
        // 여기서 또 받을 수 있으면 같은 보상 진입점이 두 곳이 된다.

        // 같이 사고 벌기 (공동구매)
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GonguScreen(earn: widget.earn, isClaimed: widget.isClaimed))),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Text('🛍️', style: TextStyle(fontSize: 22))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('같이 사고 벌기 · 공동구매', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('공구를 안 만들어도 — 추천으로 같이 사면 보상', style: const TextStyle(fontSize: 11.5, color: AppColors.yellowDeep))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(9)),
                child: const Text('공구 보기', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ]),
          ),
        ),

        // 생활비 아끼기 허브 진입 (§15의 두 번째 1차 메뉴)
        InkWell(
          onTap: _openSaveHub,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)), child: const Text('🏷️', style: TextStyle(fontSize: 22))),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('생활비 아끼기 · 회원 전용가', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Padding(padding: EdgeInsets.only(top: 2), child: Text('지역업체 · 프랜차이즈 · 공동구매 · 생활서비스', style: TextStyle(fontSize: 11.5, color: AppColors.sub))),
                  ],
                ),
              ),
              const Text('›', style: TextStyle(fontSize: 20, color: AppColors.faint)),
            ]),
          ),
        ),

        // B2B2C 부업 허브 진입
        InkWell(
          onTap: _openEarnHub,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF2A2C30), borderRadius: BorderRadius.circular(12)), child: const Text('💼', style: TextStyle(fontSize: 22))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('부업 · 제휴 성과보상', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('가입·콘텐츠·의견·방문을 한곳에서', style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: .6)))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(9)),
                child: const Text('전체보기', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
            ]),
          ),
        ),

        // 가입하고 벌기
        _secTitle('🎁 가입하고 벌기', sub: '카드·통신·서비스 가입 등'),
        _missionRowScroll('signup'),

        // 콘텐츠로 벌기
        _secTitle('✍️ 콘텐츠로 벌기', sub: '블로그·SNS·리뷰 콘텐츠로 사례비'),
        _missionRowScroll('blog'),

        // 의견 주고 벌기
        _secTitle('🗣️ 의견 주고 벌기', sub: '설문·인터뷰·좌담회·UX 테스트'),
        _missionRowScroll('survey'),

        // 방문하고 벌기
        _secTitle('🏬 방문하고 벌기', sub: '가는 길에 들러서'),
        _missionRowScroll('visit'),

        // G. 여행하며 벌기
        _secTitle('✈️ 여행하며 벌기'),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OverseasScreen(items: widget.items, actions: widget.actions))),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // '도쿄에서 14개'는 어디에도 없는 숫자였다. 실제 목록에서 센다.
                Text('여행 가는 김에, ${won(seaMin)}부터', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
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
