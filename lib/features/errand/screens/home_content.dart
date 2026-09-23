import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/section_header.dart';
import '../../benefits/data/attend_streak.dart';
import '../../benefits/models/coupon.dart';
import '../../benefits/models/partner_mission.dart';
import '../../benefits/models/reward_ledger.dart';
import '../../benefits/models/reward_product.dart';
import '../../benefits/screens/daily_mission_screen.dart';
import '../../benefits/screens/earn_hub_screen.dart';
import '../../benefits/screens/point_shop_screen.dart';
import '../../benefits/screens/walk_screen.dart';
import '../../benefits/services/mission_engine.dart';
import '../../benefits/services/mission_runner.dart';
import '../../benefits/widgets/daily_mission_row.dart';
import '../../community/screens/community_screen.dart';
import '../../dayjob/data/day_jobs.dart';
import '../../dayjob/models/day_job.dart';
import '../../dayjob/screens/day_job_screen.dart';
import '../../dayjob/widgets/day_job_card.dart';
import '../../deals/screens/save_hub_screen.dart';
import '../../pay/widgets/wallet_summary.dart';
import '../../profile/models/trust_level.dart';
import '../data/categories.dart';
import '../data/home_ads.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import '../widgets/ad_banner.dart';
import '../widgets/task_card.dart';
import 'list_screen.dart';
import 'local_errand_hub_screen.dart';
import 'map/map_canvas.dart';
import 'map/map_centers.dart';
import 'map_screen.dart';
import 'overseas_screen.dart';
import 'search_screen.dart';

/// 홈. 기획 시안 v9(`gyumsa-home-v9`)의 `Explore` 화면을 그대로 옮긴 것이다.
///
/// 위에서부터 지역 헤더 → 진행 중 배너 → 누적 수익 → 출석 → 주요 서비스 3개 →
/// 숏컷 → 가볍게 모으기 → '지금, 내 주변'(탐색) 순서이고, 탐색 영역의 지도 전환은
/// 목록과 **같은 조건의 결과**를 네이버 지도 위에 그대로 올린다.
///
/// 목록을 더 좁히거나 조건별로 모아 보는 일은 '부탁 전체보기'의
/// [LocalErrandHubScreen]에서 이어서 한다.
class HomeContent extends StatefulWidget {
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;
  /// 부업·미션으로 받는 리워드 포인트(P)
  final int points;
  final int steps;

  /// 겸사페이 잔액(원). 포인트와 성격이 다른 값이라 끝까지 따로 둔다.
  final int payBalance;

  /// 신뢰 레벨
  final TrustLevel trust;

  final VoidCallback goPay;
  final VoidCallback goProfile;

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

  /// 부탁 올리기 — '첫 부탁 올리기' 미션에서 쓴다
  final VoidCallback goPost;
  final int activeCount; // 진행 중인 지원 건수
  final VoidCallback goActivity;

  const HomeContent({
    super.key,
    required this.items,
    required this.scope,
    required this.actions,
    required this.points,
    required this.steps,
    required this.payBalance,
    required this.trust,
    required this.goPay,
    required this.goProfile,
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
    required this.goPost,
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
  bool expanded = false; // 숏컷 '전체' 펼침
  bool showMap = false; // 지도/목록 전환
  bool moreFilters = false; // 세부 조건 펼침
  int? pinned; // 지도에서 선택한 부탁

  static const _attendKey = 'benefit:attend';

  /// 목록 영역으로 스크롤을 옮길 때 쓴다. (v9의 `#nearby-v5` 앵커)
  final _nearbyKey = GlobalKey();

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  // ── 이동 ────────────────────────────────────────────────────────────────
  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void goList(ScreenRoute config) => _push(ListScreen(config: config, items: widget.items, scope: widget.scope, actions: widget.actions));
  void goSearch() => _push(SearchScreen(items: widget.items, actions: widget.actions));
  void goOverseas() => _push(OverseasScreen(items: widget.items, actions: widget.actions));
  void goCommunity() => _push(CommunityScreen(items: widget.items, scope: widget.scope, actions: widget.actions));
  void goDayJobs() => _push(DayJobScreen(onApply: _applyDayJob));

  /// 부탁 전체보기 — 카테고리·조건별 모아보기가 있는 동네 부탁 허브
  void goLocalHub({String initialCat = 'all'}) =>
      _push(LocalErrandHubScreen(items: widget.items, scope: widget.scope, actions: widget.actions, initialCat: initialCat));

  void goWalk() => _push(WalkScreen(
        items: widget.items, scope: widget.scope, steps: widget.steps, points: widget.points, coupons: widget.coupons,
        actions: widget.actions, earn: widget.earn, isClaimed: widget.isClaimed, redeem: widget.redeem,
        useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
      ));

  void goShop() => _push(PointShopScreen(
        points: widget.points, redeem: widget.redeem, coupons: widget.coupons,
        useCoupon: widget.useCoupon, goPointsHub: widget.goPointsHub,
      ));

  /// 미션 숏컷 — 제휴 미션은 '오늘 벌기' 허브 한 곳으로만 들어간다
  void goEarnHub() => _push(EarnHubScreen(
        doneMissions: widget.doneMissions,
        completeMission: widget.completeMission,
        onOpenErrand: () => goList(const ScreenRoute(
          name: 'list', title: '심부름으로 벌기', subtitle: '지역 픽업 · 개인/기업 심부름',
          base: 'earn', sortable: true, catChips: true, mapBtn: true,
        )),
        onApplyDayJob: _applyDayJob,
      ));

  /// 공동구매 숏컷 — 특가·공동구매는 '생활비 아끼기' 허브 한 곳으로만 들어간다
  void goSaveHub() => _push(SaveHubScreen(
        earn: widget.earn,
        isClaimed: widget.isClaimed,
        onUse: (d) => widget.flash('${d.brand} 회원 전용가를 준비 중이에요 · 제휴 확정 후 열려요'),
      ));

  /// 전체 지도 화면. 홈 안쪽 지도와 달리 화면 전체를 쓴다.
  void goFullMap(List<TaskItem> list) => _push(MapScreen(items: list, scope: widget.scope, actions: widget.actions));

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

  /// 종류를 고르고 목록 영역으로 스크롤한다. (v9의 숏컷 동작)
  void _focusNearby({String? category, String? which}) {
    setState(() {
      if (which != null) kind = which;
      if (category != null) cat = category;
      expanded = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _nearbyKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    });
  }

  // ── 탐색 조건 ───────────────────────────────────────────────────────────
  /// 거리를 뺀 공통 조건 (지역 · 마감 · 종류 · 30분)
  bool _matches(TaskItem i) =>
      i.mode == 'ask' &&
      _inScope(i) &&
      !i.isExpired &&
      (cat == 'all' || i.cat == cat) &&
      (!shortOnly || (i.mins > 0 && i.mins <= 30));

  /// '부탁하기'로 올린 **진짜 부탁**. 항상 목록 맨 위에 최신순으로 둔다.
  ///
  /// 새로 올린 부탁은 아직 좌표가 없어서(`distM == null`) 반경 조건에 걸리면
  /// 목록에서 통째로 사라진다. 방금 올린 내 부탁이 안 보이는 게 제일 이상하므로,
  /// 반경·정렬과 무관하게 따로 뽑아 앞에 붙인다.
  List<TaskItem> get _realTasks =>
      widget.items.where((i) => !i.sample && _matches(i)).toList()..sort((a, b) => b.id.compareTo(a.id));

  /// 미리 만들어 둔 예시 부탁. 반경·정렬 조건을 그대로 따른다.
  List<TaskItem> get _sampleTasks {
    final list = widget.items
        .where((i) => i.sample && _matches(i) && i.distM != null && i.distM! <= radius * 1000)
        .toList();
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

  /// 화면에 뿌리는 목록 = 내 진짜 부탁 + 예시
  List<TaskItem> get _tasks => [..._realTasks, ..._sampleTasks];

  String get _radiusLabel => radius < 1 ? '${(radius * 1000).round()}m' : '${radius % 1 == 0 ? radius.toInt() : radius}km';
  bool get _dirty => cat != 'all' || shortOnly || radius != 3 || sort != 'dist';

  @override
  Widget build(BuildContext context) {
    final list = _tasks;
    final jobs = List.of(dayJobs)..sort((a, b) => b.pay - a.pay);

    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        _header(),
        if (widget.activeCount > 0) _activeBanner(),
        WalletSummary(
          payBalance: widget.payBalance,
          points: widget.points,
          trust: widget.trust,
          onOpenPay: widget.goPay,
          onOpenPoints: widget.goPointsHub,
          onOpenLevel: widget.goProfile,
        ),
        _attendance(),
        _primaryServices(),
        _shortcuts(),
        const HDivider(thick: true),
        _lightMissions(),
        // v9 시안에는 없지만 수익 지면이라 홈 한 곳만 남겼다.
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: AdBanner(ads: homeAds, onTap: openAd)),
        const HDivider(thick: true),

        // ── 지금, 내 주변 ───────────────────────────────────────────────
        Padding(
          key: _nearbyKey,
          padding: const EdgeInsets.fromLTRB(22, 22, 14, 6),
          child: Row(children: [
            Expanded(child: Text('지금, 내 주변', style: AppType.section)),
            TextAction(label: '부탁 전체보기', onTap: goLocalHub),
          ]),
        ),
        _quickCats(),
        _workTabs(),
        if (kind == 'ask') ...[
          _filterControls(),
          _extraFilters(),
          _categoryStrip(),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 2),
            child: Row(children: [
              Expanded(child: Text('${list.length}개의 부탁', style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: AppColors.ink))),
              Text('시작 장소까지의 예시 거리', style: AppType.caption),
            ]),
          ),
          if (showMap) _inlineMap(list) else _taskList(list),
        ] else
          _dayJobs(jobs),

        _exploreMore(),
        _safetyNote(),
      ],
    );
  }

  // ── 조각들 ─────────────────────────────────────────────────────────────

  /// ① 지역 헤더 (.explore-header)
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 12, 2),
      child: Row(children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: widget.openRegion,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.place_outlined, size: 17, color: Color(0xFF75797E)),
                  const SizedBox(width: 5),
                  Text(shortRegion(widget.scope),
                      style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: const Color(0xFF74787D))),
                  const Icon(Icons.expand_more_rounded, size: 16, color: Color(0xFF9DA2A9)),
                ]),
              ),
            ),
          ),
        ),
        IconBtn(icon: 'search', label: '검색', onTap: goSearch, size: 23),
        IconBtn(icon: 'map', label: '지도에서 찾기', onTap: () => goFullMap(_tasks), size: 22),
        IconBtn(icon: 'bell', label: '알림', onTap: () => widget.flash('새 알림이 없어요'), size: 22),
      ]),
    );
  }

  /// ② 진행 중 배너 (.active-banner)
  Widget _activeBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: InkWell(
        onTap: widget.goActivity,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.yellowSoft,
            border: Border.all(color: AppColors.yellowLine),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(children: [
            const Icon(Icons.assignment_outlined, size: 21, color: AppColors.yellowDeep),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('진행 중 ${widget.activeCount}건',
                    style: AppType.body.copyWith(fontWeight: AppType.w600, color: AppColors.ink)),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text('현재 상태와 다음 할 일 확인', style: AppType.meta.copyWith(color: const Color(0xFF5C5B55))),
                ),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.yellowDeep),
          ]),
        ),
      ),
    );
  }

  /// ④ 출석 한 줄 (.attendance-v8)
  Widget _attendance() {
    final attended = widget.isClaimed(_attendKey);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.attendSoft, borderRadius: BorderRadius.circular(AppRadius.tile)),
        child: Row(children: [
          Icon(attended ? Icons.check_circle_outline_rounded : Icons.calendar_today_outlined, size: 20, color: AppColors.yellowDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(attended ? '오늘 출석 완료' : '오늘 출석하고 +${attendStreak[0].points}P',
                  style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: AppColors.yellowDeep)),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(attended ? '내일도 들러서 이어가 보세요' : '연속 출석일수록 보상이 커져요',
                    style: AppType.caption.copyWith(color: const Color(0xFF8D7A4A))),
              ),
            ]),
          ),
          TextButton(
            onPressed: attended ? null : () => widget.earn(attendStreak[0].points, '출석 적립', key: _attendKey),
            style: TextButton.styleFrom(
              backgroundColor: attended ? Colors.transparent : AppColors.yellow,
              foregroundColor: AppColors.ink,
              minimumSize: const Size(56, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: Text(attended ? '완료' : '받기',
                style: AppType.button.copyWith(fontSize: 12.5, color: attended ? AppColors.faint : AppColors.ink)),
          ),
        ]),
      ),
    );
  }

  /// ⑤ 주요 서비스 3개 (.primary-services)
  Widget _primaryServices() {
    final seaCount = widget.items.where((i) => i.mode == 'sea').length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(children: [
        Expanded(child: _ServiceTile(icon: 'handshake', title: '동네 부탁', sub: '가까운 곳에서 하나 더', onTap: () => _focusNearby(which: 'ask'))),
        const SizedBox(width: 8),
        Expanded(child: _ServiceTile(icon: 'globe', title: '해외 부탁', sub: seaCount > 0 ? '${nf(seaCount)}건 모집 중' : '여행길에도 수익을', tone: _ServiceTone.blue, onTap: goOverseas)),
        const SizedBox(width: 8),
        Expanded(child: _ServiceTile(icon: 'clipboard', title: '단기알바', sub: '하루도 알차게', tone: _ServiceTone.warm, onTap: () => _focusNearby(which: 'job'))),
      ]),
    );
  }

  /// ⑥ 숏컷 5개 + '전체' 펼침 (.compact-categories)
  Widget _shortcuts() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 17, 22, 17),
      child: Column(children: [
        Row(children: [
          _Shortcut(icon: 'handshake', label: '부탁 전체', onTap: goLocalHub),
          _Shortcut(icon: 'gift', label: '미션', onTap: goEarnHub),
          _Shortcut(icon: 'users', label: '같이해요', onTap: goCommunity),
          _Shortcut(icon: 'cart', label: '공동구매', onTap: goSaveHub),
          _Shortcut(
            icon: expanded ? 'chevronUp' : 'plus',
            label: expanded ? '접기' : '전체',
            onTap: () => setState(() => expanded = !expanded),
          ),
        ]),
        if (expanded) ...[
          Container(
            margin: const EdgeInsets.only(top: 15),
            padding: const EdgeInsets.only(top: 15),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEEEE8)))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('동네 부탁 종류', style: AppType.meta.copyWith(fontWeight: AppType.w500, color: const Color(0xFF7B806F))),
              const SizedBox(height: 13),
              GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, mainAxisSpacing: 15, crossAxisSpacing: 5, mainAxisExtent: 58,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final c in cats)
                    InkWell(
                      onTap: () => _focusNearby(which: 'ask', category: c.k),
                      borderRadius: BorderRadius.circular(10),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CatEmblem(cat: c.k, size: 36, radius: 12, iconSize: 19),
                        const SizedBox(height: 6),
                        Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: const Color(0xFF616754))),
                      ]),
                    ),
                ],
              ),
              // '걷기 혜택' 진입점이 있던 자리.
              //
              // 걷기 적립(5·10·15·30P)은 제휴사가 비용을 대지 않는 자체 지급이라,
              // 재원이 정해질 때까지 화면에서 내렸다. [WalkScreen]과 [walkClaimable],
              // 그리고 [parkedMissions]의 걷기 미션은 그대로 남아 있으므로,
              // 재원이 생기면 이 InkWell 하나만 되살리면 된다. ([goWalk] 참고)
            ]),
          ),
        ],
      ]),
    );
  }

  /// ⑦ 가볍게 모으기 — 지금 눌러서 바로 끝나는 미션 (.compact-missions)
  ///
  /// 예전에는 제휴 미션 중 '30분 이내'인 것을 골라 카드 두 장으로 보여 줬다.
  /// 그런데 그 미션들은 제휴가 붙기 전까지 눌러도 할 게 없었다.
  /// 지금은 [MissionEngine]이 **오늘 실제로 받을 수 있는 것만** 골라 주고,
  /// 제휴가 아직인 미션은 홈에 올리지 않는다.
  Widget _lightMissions() {
    final rows = _engine.forHome(take: 3);
    final remain = _engine.remainToday;

    // 목록이 빈 이유가 둘이다 — 오늘 다 받았거나, 제휴가 아직 안 붙었거나.
    // 같은 문구로 뭉개면 "다 했다"는 거짓말이 되므로 갈라서 말한다.
    final anyOpen = _engine.todayProgress.$2 > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 17, 22, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('가볍게 모으기', style: AppType.sectionSmall)),
          TextAction(label: '전체 보기', onTap: goDailyMissions),
        ]),
        if (remain > 0)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('오늘 아직 +${nf(remain)}P 남았어요', style: AppType.caption.copyWith(color: AppColors.yellowDeep)),
          ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          _MoreButton(
            label: anyOpen ? '오늘 할 수 있는 건 다 했어요 · 참여·리워드 보러 가기' : '참여·리워드 미션 보러 가기',
            onTap: goEarnHub,
          )
        else
          for (final s in rows) DailyMissionRow(s: s, onTap: () => _tapMission(s)),
      ]),
    );
  }

  /// 미션 상태 계산기. 적립 원장은 셸이 들고 있어서 콜백으로만 읽는다.
  MissionEngine get _engine => MissionEngine(widget.isClaimed);

  MissionRunner get _runner => MissionRunner(
        earn: widget.earn,
        flash: widget.flash,
        scope: widget.scope,
        goWalk: goWalk,
        goProfile: widget.goProfile,
        goPost: widget.goPost,
        goList: goLocalHub,
      );

  void goDailyMissions() => _push(DailyMissionScreen(runner: _runner, engine: _engine, goEarnHub: goEarnHub));

  /// 적립이 끝나면 셸의 원장이 바뀐다. 홈도 바로 다시 읽어서 방금 받은 미션이
  /// '완료'로 바뀌게 한다.
  Future<void> _tapMission(MissionState s) async {
    await _runner.run(context, s);
    if (mounted) setState(() {});
  }

  /// 빠른 종류 칩 (.quick-task-categories)
  Widget _quickCats() {
    const quick = ['buy', 'pickup', 'line', 'move'];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ChipWidget(label: '전체', pill: true, active: cat == 'all', onTap: () => setState(() => cat = 'all')),
          ),
          for (final c in cats.where((c) => quick.contains(c.k)))
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChipWidget(label: c.label, pill: true, active: cat == c.k, onTap: () => _focusNearby(which: 'ask', category: c.k)),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ChipWidget(
              label: moreFilters ? '접기' : '더보기',
              pill: true,
              onTap: () => setState(() => moreFilters = !moreFilters),
            ),
          ),
        ],
      ),
    );
  }

  /// 탐색 대상 탭 (.work-tabs) — 밑줄 형태
  Widget _workTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 2, 22, 0),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE6E6E2)))),
      child: Row(children: [
        for (final t in const [['ask', '동네 부탁'], ['job', '단기알바']])
          Padding(
            padding: const EdgeInsets.only(right: 26),
            child: InkWell(
              onTap: () => setState(() {
                kind = t[0];
                showMap = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: kind == t[0] ? const Color(0xFFFFBF00) : Colors.transparent, width: 3)),
                ),
                child: Text(
                  t[1],
                  style: AppType.body.copyWith(
                    fontSize: 15,
                    fontWeight: AppType.w600,
                    color: kind == t[0] ? AppColors.ink : const Color(0xFF787971),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  /// 지도 토글 · 반경 · 정렬 (.filter-controls)
  Widget _filterControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        InkWell(
          onTap: () => setState(() {
            showMap = !showMap;
            pinned = null;
          }),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: showMap ? AppColors.ink : AppColors.card,
              border: Border.all(color: showMap ? AppColors.ink : const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(showMap ? Icons.format_list_bulleted_rounded : Icons.map_outlined, size: 17, color: showMap ? Colors.white : AppColors.ink),
              const SizedBox(width: 4),
              Text(showMap ? '목록' : '지도',
                  style: AppType.meta.copyWith(fontWeight: AppType.w600, color: showMap ? Colors.white : AppColors.ink)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SelectField<double>(
            label: '반경',
            value: radius,
            display: _radiusLabel,
            items: const [
              (0.5, '500m 이내'), (1.0, '1km 이내'), (3.0, '3km 이내'),
              (5.0, '5km 이내'), (10.0, '10km 이내'), (20.0, '20km 이내'), (30.0, '30km 이내'),
            ],
            onChanged: (v) => setState(() => radius = v),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SelectField<String>(
            label: '정렬',
            value: sort,
            display: const {'dist': '가까운순', 'price': '사례비순', 'time': '짧은순', 'deadline': '마감임박', 'new': '최신순'}[sort]!,
            items: const [
              ('dist', '가까운순'), ('price', '사례비 높은순'), ('time', '소요시간 짧은순'),
              ('deadline', '마감 임박순'), ('new', '최신순'),
            ],
            onChanged: (v) => setState(() => sort = v),
          ),
        ),
      ]),
    );
  }

  /// 세부 조건 (.extra-filters) — '더보기'로 펼친다
  Widget _extraFilters() {
    if (!moreFilters) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => setState(() => shortOnly = !shortOnly),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(shortOnly ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 20, color: shortOnly ? AppColors.ink : AppColors.faint),
              const SizedBox(width: 8),
              Text('30분 안에 끝나는 부탁', style: AppType.meta.copyWith(fontSize: 12.5, color: const Color(0xFF777F6A))),
            ]),
          ),
        ),
        Row(children: [
          SizedBox(width: 72, child: Text('반경 $_radiusLabel', style: AppType.caption.copyWith(color: const Color(0xFF68685E)))),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFFC69B00),
                inactiveTrackColor: AppColors.line,
                thumbColor: const Color(0xFFC69B00),
                overlayShape: SliderComponentShape.noOverlay,
                trackHeight: 3,
              ),
              child: Slider(
                min: 0.5, max: 30, divisions: 59, value: radius,
                onChanged: (v) => setState(() => radius = double.parse(v.toStringAsFixed(1))),
              ),
            ),
          ),
        ]),
        if (_dirty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                cat = 'all';
                shortOnly = false;
                radius = 3;
                sort = 'dist';
              }),
              child: Text('조건 초기화', style: AppType.meta.copyWith(fontWeight: AppType.w600, color: AppColors.ink)),
            ),
          ),
      ]),
    );
  }

  /// 전체 종류 칩 줄 (.category-strip)
  Widget _categoryStrip() {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ChipWidget(label: '전체', active: cat == 'all', onTap: () => setState(() => cat = 'all')),
          ),
          for (final c in cats)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChipWidget(label: c.label, active: cat == c.k, onTap: () => setState(() => cat = c.k)),
            ),
        ],
      ),
    );
  }

  Widget _taskList(List<TaskItem> list) {
    if (list.isEmpty) {
      return EmptyState(
        compact: true,
        title: '조건에 맞는 부탁이 없어요',
        msg: '거리 미확인 부탁은 반경 검색에서 제외됩니다.',
        action: '30km · 전체 종류로 보기',
        onAction: () => setState(() {
          radius = 30;
          cat = 'all';
          shortOnly = false;
          sort = 'dist';
        }),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(children: [
        for (final it in list.take(12))
          TaskCard(it: it, onOpen: () => widget.actions.open(context, it), done: widget.actions.grabbed.contains(it.id)),
        if (list.length > 12)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: goLocalHub, child: const Text('주변 부탁 모두 보기')),
            ),
          ),
      ]),
    );
  }

  /// 목록과 **같은 조건**의 결과를 네이버 지도 위에 올린다 (v9의 지도/목록 전환).
  ///
  /// 좌표가 없는 부탁(내가 방금 올린 부탁 등)은 지도에 찍을 수 없으므로 개수를 따로 알려준다.
  Widget _inlineMap(List<TaskItem> list) {
    final located = list.where((i) => i.lat != null && i.lng != null).toList();
    // 클로저(onOpen) 안에서도 null 승격이 되도록 final로 확정해 둔다.
    TaskItem? found;
    for (final i in located) {
      if (i.id == pinned) {
        found = i;
        break;
      }
    }
    final selected = found ?? (located.isEmpty ? null : located.first);
    final center = centerOf(widget.scope);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
        child: Text(
          located.length == list.length
              ? '목록과 같은 조건의 결과예요'
              : '좌표가 있는 ${located.length}건만 지도에 표시돼요',
          textAlign: TextAlign.center,
          style: AppType.caption.copyWith(color: const Color(0xFF78786E)),
        ),
      ),
      Container(
        height: 330,
        margin: const EdgeInsets.fromLTRB(22, 12, 22, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.page,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: MapCanvas(
          pins: [
            for (final it in located)
              MapPin(
                item: it,
                lat: it.lat!,
                lng: it.lng!,
                label: (it.hot ? '급 ' : '') + kwon(it.price),
                color: it.id == selected?.id
                    ? AppColors.yellowDeep
                    : widget.actions.grabbed.contains(it.id)
                        ? AppColors.faint
                        : AppColors.ink,
              ),
          ],
          selectedId: selected?.id,
          centerLat: center.$1,
          centerLng: center.$2,
          zoom: zoomOf(widget.scope),
          onPinTap: (it) => setState(() => pinned = it.id),
        ),
      ),
      if (selected != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: TaskCard(
            it: selected,
            onOpen: () => widget.actions.open(context, selected),
            done: widget.actions.grabbed.contains(selected.id),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
          child: Text('이 조건에는 지도에 찍을 부탁이 없어요', textAlign: TextAlign.center, style: AppType.meta),
        ),
    ]);
  }

  Widget _dayJobs(List<DayJob> jobs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('근무일 · 근무시간 · 일급 · 지급일을 부탁과 구분해 안내해요', style: AppType.meta),
        const SizedBox(height: 10),
        for (final j in jobs.take(4)) DayJobCard(j: j, onOpen: () => openDayJob(context, j, _applyDayJob), compact: true),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: goDayJobs, child: const Text('단기알바 전체 보기')),
        ),
      ]),
    );
  }

  /// ⑩ 더 둘러보기 (.explore-more)
  Widget _exploreMore() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Row(children: [
        Expanded(child: _MoreButton(label: '해외 부탁', onTap: goOverseas)),
        const SizedBox(width: 8),
        Expanded(child: _MoreButton(label: '우리 동네 같이해요', onTap: goCommunity)),
      ]),
    );
  }

  Widget _safetyNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.shield_outlined, size: 16, color: AppColors.faint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '공개된 장소에서 만나고, 앱 안에서 대화·정산 내역을 남겨 주세요. 선입금 요구는 신고해 주세요.',
            style: AppType.caption.copyWith(height: 1.7),
          ),
        ),
      ]),
    );
  }
}

enum _ServiceTone { cream, blue, warm }

/// 주요 서비스 타일 (.primary-services>button) — 세로 정렬, 3열
class _ServiceTile extends StatelessWidget {
  final String icon, title, sub;
  final _ServiceTone tone;
  final VoidCallback onTap;
  const _ServiceTile({required this.icon, required this.title, required this.sub, this.tone = _ServiceTone.cream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (tone) {
      _ServiceTone.blue => (AppColors.blueSoft, const Color(0xFFDCE5F2), AppColors.blue),
      _ServiceTone.warm => (const Color(0xFFF4F1E9), const Color(0xFFEAE5D6), const Color(0xFF8A7A4E)),
      _ServiceTone.cream => (const Color(0xFFFFFDF5), const Color(0xFFEDE9DC), const Color(0xFF96722C)),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 14),
        decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(17)),
        child: Column(children: [
          SizedBox(height: 28, child: Icon(AppIcon.data(icon), size: 26, color: fg)),
          const SizedBox(height: 8),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body.copyWith(fontSize: 14, fontWeight: AppType.w700, color: const Color(0xFF29271F))),
          const SizedBox(height: 5),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(fontSize: 10, color: const Color(0xFF7C7C73))),
        ]),
      ),
    );
  }
}

/// 숏컷 한 칸 (.category-shortcuts button)
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            Icon(AppIcon.data(icon), size: 20, color: const Color(0xFF737967)),
            const SizedBox(height: 7),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: const Color(0xFF5D6352))),
          ]),
        ),
      ),
    );
  }
}

/// 더 둘러보기 버튼 (.explore-more button)
class _MoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MoreButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: const Color(0xFFE8E8E4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.meta.copyWith(color: AppColors.ink))),
          const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.faint),
        ]),
      ),
    );
  }
}

/// 시안의 `<select>` 자리. 라벨이 위에 붙은 테두리 상자를 누르면 바텀시트가 열린다.
class _SelectField<T> extends StatelessWidget {
  final String label;
  final T value;
  final String display;
  final List<(T, String)> items;
  final void Function(T) onChanged;
  const _SelectField({required this.label, required this.value, required this.display, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppType.caption.copyWith(fontSize: 10, color: const Color(0xFF777777))),
      const SizedBox(height: 5),
      InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: const Color(0xFFE6E6E2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Expanded(
              child: Text(display, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppType.meta.copyWith(fontWeight: AppType.w600, color: const Color(0xFF24241F))),
            ),
            const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.faint),
          ]),
        ),
      ),
    ]);
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
              child: Text(label, style: AppType.pageTitle.copyWith(fontSize: 16)),
            ),
            for (final (v, text) in items)
              ListTile(
                title: Text(text, style: AppType.body.copyWith(fontWeight: v == value ? AppType.w700 : AppType.w400)),
                trailing: v == value ? const Icon(Icons.check_rounded, size: 19, color: AppColors.ink) : null,
                onTap: () {
                  Navigator.of(sheet).pop();
                  onChanged(v);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
