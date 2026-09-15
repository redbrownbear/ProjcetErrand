import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../../benefits/data/attend_streak.dart';
import '../../benefits/data/partner_missions.dart';
import '../../benefits/models/coupon.dart';
import '../../benefits/models/partner_mission.dart';
import '../../benefits/models/reward_ledger.dart';
import '../../benefits/models/reward_product.dart';
import '../../benefits/screens/earn_hub_screen.dart';
import '../../benefits/screens/partner_mission_detail_screen.dart';
import '../../benefits/screens/point_shop_screen.dart';
import '../../benefits/screens/walk_screen.dart';
import '../../community/screens/community_screen.dart';
import '../../dayjob/data/day_jobs.dart';
import '../../dayjob/models/day_job.dart';
import '../../dayjob/screens/day_job_screen.dart';
import '../../dayjob/widgets/day_job_card.dart';
import '../../deals/screens/save_hub_screen.dart';
import '../../earn/widgets/income_summary.dart';
import '../data/categories.dart';
import '../data/home_ads.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import '../widgets/ad_banner.dart';
import '../widgets/task_card.dart';
import 'country_screen.dart';
import 'list_screen.dart';
import 'map_screen.dart';
import 'overseas_screen.dart';
import 'search_screen.dart';

/// 홈. 기획 시안 v9(`gyumsa-home-v9`)의 Explore 구조를 그대로 따른다.
///
/// v9의 핵심은 "짧은 홈"이다. 예전 홈은 섹션이 22개였고 걷기·미션·공동구매 진입이
/// 각각 서너 군데씩 흩어져 있었다. 여기서는 진입점을 하나씩만 두고, 목록을 좁히는
/// 일(30분 이내·사례비 높은 순·급한 순 등)은 전부 아래 탐색 영역의 조건으로 옮겼다.
class HomeContent extends StatefulWidget {
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;
  final int points;
  final int steps;

  /// 완료한 거래의 사례비 합계(원). 누적 수익 표시에 쓴다.
  final int earnedCash;
  final List<Coupon> coupons;
  final List<String> doneMissions;
  final VoidCallback openRegion;
  final EarnFn earn;
  final IsClaimedFn isClaimed;
  final void Function(RewardProduct) redeem;
  final void Function(int id) useCoupon;
  final void Function(PartnerMission) completeMission;
  final void Function(String) flash;
  final VoidCallback goPointsHub;
  final int activeCount; // 진행 중인 지원 건수
  final VoidCallback goActivity;

  const HomeContent({
    super.key,
    required this.items,
    required this.scope,
    required this.actions,
    required this.points,
    required this.steps,
    required this.earnedCash,
    required this.coupons,
    required this.doneMissions,
    required this.isClaimed,
    required this.openRegion,
    required this.earn,
    required this.redeem,
    required this.useCoupon,
    required this.completeMission,
    required this.flash,
    required this.goPointsHub,
    required this.activeCount,
    required this.goActivity,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  /// 탐색 대상: ask(동네 부탁) | job(단기알바)
  String kind = 'ask';
  String cat = 'all';
  double radius = 3; // km
  String sort = 'dist';
  bool shortOnly = false;
  bool expanded = false; // 서비스 숏컷 '전체' 펼침

  static const _attendKey = 'benefit:attend';

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  // ── 이동 ────────────────────────────────────────────────────────────────
  void goList(ScreenRoute config) => Navigator.push(context, MaterialPageRoute(builder: (_) => ListScreen(config: config, items: widget.items, scope: widget.scope, actions: widget.actions)));
  void goSearch() => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(items: widget.items, actions: widget.actions)));
  void goOverseas() => Navigator.push(context, MaterialPageRoute(builder: (_) => OverseasScreen(items: widget.items, actions: widget.actions)));
  void goCommunity() => Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityScreen(items: widget.items, scope: widget.scope, actions: widget.actions)));
  void goWalk() => Navigator.push(context, MaterialPageRoute(builder: (_) => WalkScreen(
        items: widget.items, scope: widget.scope, steps: widget.steps, points: widget.points, coupons: widget.coupons,
        actions: widget.actions, earn: widget.earn, isClaimed: widget.isClaimed, redeem: widget.redeem, useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
      )));
  void goShop() => Navigator.push(context, MaterialPageRoute(builder: (_) => PointShopScreen(
        points: widget.points, redeem: widget.redeem, coupons: widget.coupons, useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
      )));
  void goCountry(String cc) => Navigator.push(context, MaterialPageRoute(builder: (_) => CountryScreen(cc: cc, items: widget.items, actions: widget.actions)));
  void openDetail(TaskItem it) => widget.actions.open(context, it);

  /// 지도는 목록과 같은 조건의 결과만 보여준다 (v9: 같은 결과로 지도/목록 전환)
  void goMap(List<TaskItem> list) => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(items: list, scope: widget.scope, actions: widget.actions)));

  /// 미션 숏컷 — 제휴 미션은 '오늘 벌기' 허브 한 곳으로만 들어간다
  void goEarnHub() => Navigator.push(context, MaterialPageRoute(builder: (_) => EarnHubScreen(
        doneMissions: widget.doneMissions,
        completeMission: widget.completeMission,
        onOpenErrand: () => goList(const ScreenRoute(name: 'list', title: '심부름으로 벌기', subtitle: '지역 픽업 · 개인/기업 심부름', base: 'earn', sortable: true, catChips: true, mapBtn: true)),
        onApplyDayJob: _applyDayJob,
      )));

  /// 공동구매 숏컷 — 특가·공동구매는 '생활비 아끼기' 허브 한 곳으로만 들어간다
  void goSaveHub() => Navigator.push(context, MaterialPageRoute(builder: (_) => SaveHubScreen(
        earn: widget.earn,
        isClaimed: widget.isClaimed,
        onUse: (d) => widget.flash('${d.brand} 회원 전용가를 준비 중이에요 · 제휴 확정 후 열려요'),
      )));

  void goDayJobs() => Navigator.push(context, MaterialPageRoute(builder: (_) => DayJobScreen(onApply: _applyDayJob)));
  void _applyDayJob(DayJob j) => widget.flash('${j.org}에 지원 의사를 전달했어요 · 근로계약은 구인업체와 진행돼요');

  void openAd(ScreenRoute route) {
    switch (route.name) {
      case 'shop':
        goShop();
      case 'overseas':
        goOverseas();
      case 'walk':
        goWalk();
      default:
        goList(route);
    }
  }

  // ── 탐색 조건 ───────────────────────────────────────────────────────────
  /// 홈 탐색 목록. 거리 미확인 부탁은 반경 조건에서 제외한다.
  List<TaskItem> get _tasks {
    final list = widget.items.where((i) =>
        i.mode == 'ask' &&
        _inScope(i) &&
        !i.isExpired &&
        (cat == 'all' || i.cat == cat) &&
        (i.distM != null && i.distM! <= radius * 1000) &&
        (!shortOnly || (i.mins > 0 && i.mins <= 30))).toList();
    switch (sort) {
      case 'price':
        list.sort((a, b) => b.price - a.price);
      case 'time':
        list.sort((a, b) => a.mins.compareTo(b.mins));
      case 'deadline':
        list.sort((a, b) {
          final x = a.deadline, y = b.deadline;
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return x.compareTo(y);
        });
      case 'new':
        list.sort((a, b) => b.id.compareTo(a.id));
      default:
        list.sort((a, b) => a.distSort.compareTo(b.distSort));
    }
    return list;
  }

  String get _radiusLabel => radius < 1 ? '${(radius * 1000).round()}m' : '${radius % 1 == 0 ? radius.toInt() : radius}km';

  @override
  Widget build(BuildContext context) {
    final list = _tasks;
    final jobs = List.of(dayJobs)..sort((a, b) => b.pay - a.pay);
    final attended = widget.isClaimed(_attendKey);

    return ListView(
      padding: const EdgeInsets.only(bottom: 26),
      children: [
        // ① 지역 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
          child: Row(children: [
            Expanded(
              child: InkWell(
                onTap: widget.openRegion,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('📍 ${shortRegion(widget.scope)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const Padding(padding: EdgeInsets.only(left: 4), child: Text('▾', style: TextStyle(color: AppColors.faint, fontSize: 13))),
                  ]),
                ),
              ),
            ),
            InkWell(onTap: goSearch, child: const Padding(padding: EdgeInsets.all(6), child: Text('🔍', style: TextStyle(fontSize: 18)))),
            InkWell(onTap: () => goMap(list), child: const Padding(padding: EdgeInsets.all(6), child: Text('🗺️', style: TextStyle(fontSize: 18)))),
            InkWell(onTap: () => widget.flash('새 알림이 없어요'), child: const Padding(padding: EdgeInsets.all(6), child: Text('🔔', style: TextStyle(fontSize: 18)))),
          ]),
        ),

        // ② 진행 중 배너
        if (widget.activeCount > 0)
          InkWell(
            onTap: widget.goActivity,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Text('📋', style: TextStyle(fontSize: 19)),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('진행 중인 부탁 ${widget.activeCount}건', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const Text('현재 상태와 다음 할 일을 확인하세요', style: TextStyle(fontSize: 12.5, color: AppColors.yellowDeep)),
                    ],
                  ),
                ),
                const Text('›', style: TextStyle(fontSize: 20, color: AppColors.yellowDeep)),
              ]),
            ),
          ),

        // ③ 누적 수익 + 목표
        IncomeSummary(cash: widget.earnedCash, points: widget.points),

        // ④ 출석 한 줄
        InkWell(
          onTap: attended ? null : () => widget.earn(attendStreak[0].points, '출석 적립', key: _attendKey),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: attended ? AppColors.greenSoft : AppColors.card,
              border: Border.all(color: attended ? AppColors.greenSoft : AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Text(attended ? '✅' : '📅', style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(attended ? '오늘 출석 완료' : '오늘 출석하고 +${attendStreak[0].points}P',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: attended ? AppColors.green : AppColors.ink)),
              ),
              if (!attended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(8)),
                  child: const Text('출석', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ),
            ]),
          ),
        ),

        // ⑤ 주요 서비스 3개
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            _ServiceRow(icon: '🤝', title: '동네 부탁', sub: '가까운 곳에서 하나 더', onTap: () => setState(() => kind = 'ask')),
            _ServiceRow(icon: '🌏', title: '해외 부탁', sub: '여행길에도 수익을', onTap: goOverseas),
            _ServiceRow(icon: '📋', title: '단기알바', sub: '하루도 알차게', onTap: () => setState(() => kind = 'job')),
          ]),
        ),

        // ⑥ 서비스 숏컷 (+ 전체 펼침)
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 4),
          child: Row(children: [
            _Shortcut(icon: '🙋', label: '부탁 전체', onTap: () => goList(const ScreenRoute(name: 'list', title: '부탁 전체', subtitle: '조건을 바꿔가며 찾아보세요', base: 'ask', sortable: true, catChips: true, mapBtn: true))),
            _Shortcut(icon: '🎁', label: '미션', onTap: goEarnHub),
            _Shortcut(icon: '👋', label: '같이해요', onTap: goCommunity),
            _Shortcut(icon: '🛍️', label: '공동구매', onTap: goSaveHub),
            _Shortcut(icon: expanded ? '▴' : '➕', label: expanded ? '접기' : '전체', onTap: () => setState(() => expanded = !expanded)),
          ]),
        ),
        if (expanded) ...[
          const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 2), child: Text('동네 부탁 종류', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink))),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 76, mainAxisSpacing: 10, mainAxisExtent: 62),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: cats
                  .map((c) => InkWell(
                        onTap: () => setState(() {
                          kind = 'ask';
                          cat = c.k;
                        }),
                        child: Column(children: [
                          Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)), child: Text(c.icon, style: const TextStyle(fontSize: 23))),
                          const SizedBox(height: 5),
                          Text(c.label, style: const TextStyle(fontSize: 11, color: AppColors.ink)),
                        ]),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: InkWell(
              onTap: goWalk,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(11)),
                child: Row(children: [
                  const Text('🚶', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 9),
                  Expanded(child: Text('걷기 혜택 · ${nf(widget.steps)}걸음', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.blue))),
                  const Text('›', style: TextStyle(fontSize: 18, color: AppColors.blue)),
                ]),
              ),
            ),
          ),
        ],

        // ⑦ 가볍게 모으기 — 짧은 미션 2개만
        _LightMissions(
          doneMissions: widget.doneMissions,
          onOpenAll: goEarnHub,
          onOpen: (m) => Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerMissionDetailScreen(
                m: m, done: widget.doneMissions.contains(m.id), onComplete: widget.completeMission,
              ))),
        ),

        // ⑧ 광고 (v9 시안에는 없지만 수익 지면이라 한 곳만 남겼다)
        AdBanner(ads: homeAds, onTap: openAd),

        // ⑨ 지금, 내 주변
        SectionHeader(
          title: '지금, 내 주변',
          sub: kind == 'ask' ? '${list.length}개의 부탁 · 시작 장소까지의 예시 거리' : '${jobs.length}개의 단기알바',
          onAction: () => kind == 'ask'
              ? goList(const ScreenRoute(name: 'list', title: '부탁 전체', base: 'ask', sortable: true, catChips: true, mapBtn: true))
              : goDayJobs(),
        ),

        // 탐색 대상 탭
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            for (final t in [['ask', '동네 부탁'], ['job', '단기알바']])
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ChipWidget(label: t[1], active: kind == t[0], onTap: () => setState(() => kind = t[0])),
              ),
          ]),
        ),

        if (kind == 'ask') ...[
          // 빠른 종류 칩
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(padding: const EdgeInsets.only(right: 7), child: ChipWidget(label: '전체', active: cat == 'all', onTap: () => setState(() => cat = 'all'))),
                for (final c in cats)
                  Padding(padding: const EdgeInsets.only(right: 7), child: ChipWidget(label: c.label, active: cat == c.k, onTap: () => setState(() => cat = c.k))),
              ],
            ),
          ),

          // 반경 · 정렬 · 지도
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Expanded(
                child: _Picker<double>(
                  label: '반경',
                  value: radius,
                  display: _radiusLabel,
                  items: const [
                    [0.5, '500m 이내'], [1.0, '1km 이내'], [3.0, '3km 이내'],
                    [5.0, '5km 이내'], [10.0, '10km 이내'], [20.0, '20km 이내'], [30.0, '30km 이내'],
                  ],
                  onChanged: (v) => setState(() => radius = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Picker<String>(
                  label: '정렬',
                  value: sort,
                  display: const {'dist': '가까운순', 'price': '사례비순', 'time': '짧은순', 'deadline': '마감임박', 'new': '최신순'}[sort]!,
                  items: const [
                    ['dist', '가까운순'], ['price', '사례비 높은순'], ['time', '소요시간 짧은순'],
                    ['deadline', '마감 임박순'], ['new', '최신순'],
                  ],
                  onChanged: (v) => setState(() => sort = v),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => goMap(list),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
                  child: const Text('🗺️ 지도', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
              ),
            ]),
          ),

          // 세부 조건
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Row(children: [
              InkWell(
                onTap: () => setState(() => shortOnly = !shortOnly),
                borderRadius: BorderRadius.circular(99),
                child: ChipWidget(label: '⚡ 30분 안에 끝나요', active: shortOnly),
              ),
              const Spacer(),
              if (cat != 'all' || shortOnly || radius != 3 || sort != 'dist')
                TextButton(
                  onPressed: () => setState(() {
                    cat = 'all';
                    shortOnly = false;
                    radius = 3;
                    sort = 'dist';
                  }),
                  child: const Text('조건 초기화', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
            ]),
          ),

          if (list.isEmpty)
            const EmptyState(msg: '조건에 맞는 부탁이 없어요.\n거리 미확인 부탁은 반경 검색에서 제외됩니다.')
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                for (final it in list.take(12)) TaskCard(it: it, onOpen: () => openDetail(it), done: widget.actions.grabbed.contains(it.id)),
              ]),
            ),
        ] else ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('근무일 · 근무시간 · 일급 · 지급일을 부탁과 구분해 안내해요', style: TextStyle(fontSize: 12, color: AppColors.sub)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              for (final j in jobs.take(4)) DayJobCard(j: j, onOpen: () => openDayJob(context, j, _applyDayJob), compact: true),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: goDayJobs,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('단기알바 전체 보기 ›', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ],

        // ⑩ 더 둘러보기
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(children: [
            _MoreRow(label: '🌏 해외 부탁', onTap: goOverseas),
            _MoreRow(label: '👋 우리 동네 같이해요', onTap: goCommunity),
          ]),
        ),

        // ⑪ 안전 안내
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
          child: const Text(
            '🛡 공개된 장소에서 만나고, 앱 안에서 대화·정산 내역을 남겨 주세요. 선입금 요구는 신고해 주세요.',
            style: TextStyle(fontSize: 11.5, color: AppColors.sub, height: 1.6),
          ),
        ),
      ],
    );
  }
}

/// 주요 서비스 한 줄 (동네 부탁 / 해외 부탁 / 단기알바)
class _ServiceRow extends StatelessWidget {
  final String icon, title, sub;
  final VoidCallback onTap;
  const _ServiceRow({required this.icon, required this.title, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(13)), child: Text(icon, style: const TextStyle(fontSize: 22))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                Padding(padding: const EdgeInsets.only(top: 2), child: Text(sub, style: const TextStyle(fontSize: 11.5, color: AppColors.sub))),
              ],
            ),
          ),
          const Text('›', style: TextStyle(fontSize: 19, color: AppColors.faint)),
        ]),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _Shortcut({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [
            Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(14)), child: Text(icon, style: const TextStyle(fontSize: 20))),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ]),
        ),
      ),
    );
  }
}

/// 짧은 시간 순으로 설문·체험 미션 두 개만. 전체는 '오늘 벌기' 허브에서 본다.
class _LightMissions extends StatelessWidget {
  final List<String> doneMissions;
  final VoidCallback onOpenAll;
  final void Function(PartnerMission) onOpen;
  const _LightMissions({required this.doneMissions, required this.onOpenAll, required this.onOpen});

  /// 소요 시간 문구를 분으로 읽는다. '1~2시간'을 1분으로 보면 좌담회가
  /// '가볍게 모으기'에 올라오므로 시간 단위를 반드시 구분한다.
  /// 숫자가 없는 '방문', '체험+후기' 같은 값은 짧은 일로 취급하지 않는다.
  static int _minutes(String time) {
    final n = int.tryParse(RegExp(r'\d+').stringMatch(time) ?? '');
    if (n == null) return 999;
    return time.contains('시간') ? n * 60 : n;
  }

  @override
  Widget build(BuildContext context) {
    final rows = partnerMissions
        .where((m) => !doneMissions.contains(m.id) && (m.cat == 'survey' || m.cat == 'experience'))
        .toList()
      ..sort((a, b) => _minutes(a.time).compareTo(_minutes(b.time)));
    final top = rows.where((m) => _minutes(m.time) <= 30).take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '가볍게 모으기', sub: '짧게 참여하고 포인트 받기', onAction: onOpenAll),
        if (top.isEmpty)
          const EmptyState(msg: '참여 가능한 미션을 모두 완료했어요.')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              for (final m in top)
                InkWell(
                  onTap: () => onOpen(m),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
                    child: Row(children: [
                      Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(11)), child: Text(m.icon, style: const TextStyle(fontSize: 20))),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${m.time} · ${m.cat == 'survey' ? '설문' : '체험'}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.purple)),
                            Padding(padding: const EdgeInsets.only(top: 1), child: Text(m.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                            Padding(padding: const EdgeInsets.only(top: 2), child: Text(m.cond, style: const TextStyle(fontSize: 11, color: AppColors.sub))),
                          ],
                        ),
                      ),
                      Text('+${nf(m.points)}P', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ]),
                  ),
                ),
            ]),
          ),
      ],
    );
  }
}

class _MoreRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MoreRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
          const Text('›', style: TextStyle(fontSize: 18, color: AppColors.faint)),
        ]),
      ),
    );
  }
}

/// 반경·정렬처럼 값을 하나 고르는 작은 드롭다운. 바텀시트로 열어 터치 영역을 넓게 둔다.
class _Picker<T> extends StatelessWidget {
  final String label;
  final T value;
  final String display;
  final List<List<Object>> items;
  final void Function(T) onChanged;
  const _Picker({required this.label, required this.value, required this.display, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Text('$label ', style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
          Expanded(child: Text(display, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
          const Text('▾', style: TextStyle(fontSize: 11, color: AppColors.faint)),
        ]),
      ),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 6), child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink))),
            for (final it in items)
              ListTile(
                title: Text(it[1] as String, style: TextStyle(fontSize: 14, fontWeight: it[0] == value ? FontWeight.w800 : FontWeight.w500, color: AppColors.ink)),
                trailing: it[0] == value ? const Text('✓', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)) : null,
                onTap: () {
                  Navigator.of(sheet).pop();
                  onChanged(it[0] as T);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
