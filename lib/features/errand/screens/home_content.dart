import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/surface.dart';
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
import '../../community/screens/community_screen.dart';
import '../../dayjob/data/day_jobs.dart';
import '../../dayjob/models/day_job.dart';
import '../../dayjob/screens/day_job_screen.dart';
import '../../dayjob/widgets/day_job_card.dart';
import '../../deals/data/member_deals.dart';
import '../../deals/models/member_deal.dart';
import '../../deals/screens/save_hub_screen.dart';
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

/// 홈. 기획 시안 v33(`겸사겸사_v33.html`)의 `#homeRoot`를 옮긴 것이다.
///
/// 맨 위 '부탁하기 | 돈벌기' 전환으로 두 갈래를 나눈다.
/// - **부탁하기**: 겸이 카드 → 이런 것도 부탁해도 돼요 → 광고 → 자주 하는 부탁 →
///   주요 서비스 3개 → 바로가기 4개 → 우리 동네 제휴 가게 → 가는 김에
/// - **돈벌기**: 겸이 카드 → 이번 달 번 금액 → 이거 하나 하고 갈래요? →
///   지금 내 주변 부탁(목록·지도) → 광고 → 가는 김에 → 우리 동네 혜택 → 해외 부탁 → 미션·공구
///
/// '지금 내 주변 부탁'의 지도 전환은 목록과 **같은 조건의 결과**를 네이버 지도 위에 올린다.
/// 목록을 더 좁히거나 조건별로 모아 보는 일은 '부탁 전체보기'의
/// [LocalErrandHubScreen]에서 이어서 한다.
class HomeContent extends StatefulWidget {
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;

  /// 부업·미션으로 받는 리워드 포인트(P)
  final int points;
  final int steps;

  /// 이번 달 완료한 부탁의 사례비(원). 돈벌기의 '이번 달 내가 번 금액'.
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

  final int activeCount; // 진행 중인 지원 건수
  final VoidCallback goActivity;

  /// 단기알바 모집 등록 (셸이 로그인 확인 후 띄운다)
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
  /// 맨 위 전환 — ask(부탁하기) | earn(돈벌기)
  String mode = 'ask';

  /// 탐색 대상: ask(동네 부탁) | job(단기알바)
  String kind = 'ask';
  String cat = 'all';
  double radius = 3; // km
  String sort = 'dist';
  bool shortOnly = false;
  bool showMap = false; // 지도/목록 전환
  int? pinned; // 지도에서 선택한 부탁

  /// '이거 하나 하고 갈래요?' 넘김
  final _pickCtrl = PageController();
  int pickIdx = 0;

  /// 목록 영역으로 스크롤을 옮길 때 쓴다. (시안의 `.sec.near` 앵커)
  final _nearbyKey = GlobalKey();

  @override
  void dispose() {
    _pickCtrl.dispose();
    super.dispose();
  }

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  // ── 이동 ────────────────────────────────────────────────────────────────
  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void goList(ScreenRoute config) => _push(ListScreen(config: config, items: widget.items, scope: widget.scope, actions: widget.actions));
  void goOverseasSearch() => _push(OverseasScreen(items: widget.items, actions: widget.actions));
  void goCommunity() => _push(CommunityScreen(items: widget.items, scope: widget.scope, actions: widget.actions));
  void goDayJobs() => _push(DayJobScreen(onApply: _applyDayJob, onPost: widget.openJobPost));

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

  /// 제휴 미션 '오늘 벌기' 허브
  void goEarnHub() => _push(EarnHubScreen(
        doneMissions: widget.doneMissions,
        completeMission: widget.completeMission,
        onOpenErrand: () => goList(const ScreenRoute(
          name: 'list', title: '심부름으로 벌기', subtitle: '지역 픽업 · 개인/기업 심부름',
          base: 'earn', sortable: true, catChips: true, mapBtn: true,
        )),
        onApplyDayJob: _applyDayJob,
      ));

  /// 제휴 가게·회원 전용가 — '생활비 아끼기' 허브
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
        widget.goOverseasTab();
      case 'walk':
        goWalk();
      default:
        goList(route);
    }
  }

  /// 돈벌기로 넘어가 목록 영역으로 스크롤한다.
  void _focusNearby({String? which}) {
    setState(() {
      mode = 'earn';
      if (which != null) kind = which;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _nearbyKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    });
  }

  // ── 미션 ────────────────────────────────────────────────────────────────
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

  static const _sortLabels = {'dist': '가까운순', 'price': '금액 높은순', 'time': '짧은순', 'deadline': '마감임박', 'new': '최신순'};

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SegToggle(
          labels: const ['부탁하기', '돈벌기'],
          index: mode == 'ask' ? 0 : 1,
          onChanged: (i) => setState(() => mode = i == 0 ? 'ask' : 'earn'),
        ),
        if (widget.activeCount > 0) _activeBanner(),
        ...(mode == 'ask' ? _askSections() : _earnSections()),
      ],
    );
  }

  // ── 부탁하기 ────────────────────────────────────────────────────────────

  List<Widget> _askSections() {
    // 맨 위 한 줄은 지어낸 거래 소식이 아니라 실제로 올라온 부탁에서 뽑는다.
    final latest = (widget.items.where((i) => i.mode == 'ask' && !i.isExpired && _inScope(i)).toList()
          ..sort((a, b) => (a.sample ? 1 : 0) - (b.sample ? 1 : 0)))
        .firstOrNull;

    return [
      HeroCard(
        sub: '가는 길에, 하나 더',
        title: '무엇이든 부탁해요\n**가까운 이웃**이 도와드려요',
        liveBold: latest?.title,
        liveRest: latest == null
            ? null
            : [shortRegion(latest.region ?? widget.scope), latest.sample ? '예시' : '새 부탁'].join(' · '),
        floats: const ['box', 'bag', 'heart', 'pet'],
        cta: '부탁하기',
        ctaIcon: 'plus',
        onCta: widget.goPost,
        note: '누구나 가는 김에 도와주고 수익을 얻을 수 있어요',
      ),
      ExampleRotator(
        question: '이런 것도 부탁해도 돼요',
        items: _examples,
        onTap: (i) {
          final target = _exampleTargets[i];
          if (target == 'sea') {
            widget.goPostSea();
          } else {
            widget.goPostCat(target);
          }
        },
        footLabel: '목록에 없어도 괜찮아요. 어떤 부탁이든 올려보세요',
        onFoot: widget.goPost,
      ),
      AdBanner(ads: homeAds, onTap: openAd),
      _frequentCats(),
      _services(),
      _quickRow(),
      _partnerShops(),
      _goingBoard(),
      const FootNote('이웃에게 직접 부탁하려면 마이 › 지원한 부탁에서 이어서 진행해요'),
    ];
  }

  /// '이런 것도 부탁해도 돼요' 예시 (시안 `CAN`). 실제 부탁이 아니라 안내 문구다.
  static const _examples = [
    (icon: 'box', title: '먼 곳 맛집 음식 배달해주기', color: AppColors.blue),
    (icon: 'wrench', title: '막힌 변기 뚫어주기', color: AppColors.green),
    (icon: 'bug', title: '바퀴벌레 잡아주기', color: Color(0xFFE57A16)),
    (icon: 'globe', title: '일본에서 굿즈 사다주기', color: AppColors.red),
    (icon: 'pet', title: '강아지 잠깐 봐주기', color: Color(0xFFD99A00)),
    (icon: 'cart', title: '코스트코 가는 사람에게 장보기 부탁', color: AppColors.purple),
  ];

  /// 예시를 눌렀을 때 미리 골라 둘 부탁 종류. sea는 해외 부탁 쓰기.
  static const _exampleTargets = ['pickup', 'etc', 'etc', 'sea', 'pet', 'buy'];

  /// 진행 중 배너 — 지원한 부탁이 있을 때만
  Widget _activeBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: widget.goActivity,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              const IconTile(icon: 'clipboard', bg: AppColors.yellowSoft, fg: AppColors.yellowInk, size: 36, iconSize: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: '진행 중 '),
                    TextSpan(text: '${widget.activeCount}건', style: const TextStyle(color: AppColors.heroAccent)),
                    const TextSpan(text: ' · 다음 할 일 확인', style: TextStyle(fontWeight: AppType.w500, color: AppColors.sub)),
                  ]),
                  style: AppType.body.copyWith(fontWeight: AppType.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faint),
            ]),
          ),
        ),
      ),
    );
  }

  /// 자주 하는 부탁 (.cats — 5열, 주황 타일)
  Widget _frequentCats() {
    return SecCard(
      child: Column(children: [
        const SecHead(title: '자주 하는 부탁'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, mainAxisSpacing: 12, crossAxisSpacing: 8, mainAxisExtent: 73,
            ),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final c in cats)
                InkWell(
                  onTap: () => widget.goPostCat(c.k),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(15)),
                      child: Icon(AppIcon.cat(c.k), size: 24, color: AppColors.orange),
                    ),
                    const SizedBox(height: 7),
                    Text(c.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption.copyWith(fontSize: 12, fontWeight: AppType.w700, color: AppColors.ink2)),
                  ]),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  /// 주요 서비스 3개 (.hs)
  Widget _services() {
    final seaCount = widget.items.where((i) => i.mode == 'sea').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Row(children: [
        Expanded(
          child: _ServiceTile(
            icon: 'hand', title: '동네 부탁', sub: '가까운 곳에서 하나 더',
            bg: const Color(0xFFFFF4D6), fg: const Color(0xFFD99A00),
            onTap: () => _focusNearby(which: 'ask'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ServiceTile(
            icon: 'globe', title: '해외 부탁', sub: seaCount > 0 ? '${nf(seaCount)}건 모집 중' : '여행길에 사다줘요',
            bg: const Color(0xFFE8F0FE), fg: AppColors.blue,
            onTap: widget.goOverseasTab,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ServiceTile(
            icon: 'brief', title: '단기알바', sub: '하루만 도와줘요',
            bg: AppColors.purpleSoft, fg: AppColors.purple,
            onTap: () => _focusNearby(which: 'job'),
          ),
        ),
      ]),
    );
  }

  /// 바로가기 4개 (.hq)
  Widget _quickRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Row(children: [
        _Quick(icon: 'gift', label: '미션', onTap: () => widget.goSideTab(0)),
        _Quick(icon: 'cart', label: '공동구매', onTap: () => widget.goSideTab(1)),
        _Quick(icon: 'pencil', label: '가는 김에', onTap: goCommunity),
        _Quick(icon: 'sparkles', label: '전체', onTap: _openAllSheet),
      ]),
    );
  }

  /// '전체' — 홈에 다 올리지 못한 진입점을 한 장에 모은다.
  void _openAllSheet() {
    final entries = <(String, String, VoidCallback)>[
      ('handshake', '동네 부탁 전체', goLocalHub),
      ('globe', '해외 부탁', widget.goOverseasTab),
      ('brief', '단기알바', goDayJobs),
      ('users', '같이해요', goCommunity),
      ('gift', '제휴 미션', goEarnHub),
      ('check', '매일 미션', goDailyMissions),
      ('cart', '공동구매', () => widget.goSideTab(1)),
      ('store', '회원 전용가', goSaveHub),
      ('ticket', '포인트샵', goShop),
      ('map', '지도로 보기', () => goFullMap(_tasks)),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.surface))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.soft2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
              child: Text('전체 서비스', style: AppType.pageTitle),
            ),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [
                for (final (icon, label, go) in entries)
                  InkWell(
                    onTap: () {
                      Navigator.of(sheet).pop();
                      go();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconTile(icon: icon, bg: AppColors.page, fg: AppColors.ink2, size: 44, radius: 14),
                      const SizedBox(height: 6),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(fontSize: 11.5, fontWeight: AppType.w600, color: AppColors.ink2)),
                    ]),
                  ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  /// 우리 동네 제휴 가게 (.sr — 가로로 넘기는 작은 카드)
  Widget _partnerShops() {
    final deals = memberDeals.where((d) => d.menu != 'finance').toList();
    if (deals.isEmpty) return const SizedBox.shrink();
    return SecCard(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SecHead(title: '우리 동네 제휴 가게', action: '전체', onAction: goSaveHub),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: deals.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = deals[i];
              return Material(
                color: AppColors.page,
                borderRadius: BorderRadius.circular(AppRadius.tile),
                child: InkWell(
                  onTap: goSaveHub,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                  child: Container(
                    width: 93,
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      IconTile(icon: _dealIcon(d), bg: AppColors.card, size: 34, iconSize: 19, radius: 10),
                      const SizedBox(height: 8),
                      Text(d.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(fontSize: 12.5, fontWeight: AppType.w700, color: AppColors.ink)),
                      Text(d.isPriced ? '${d.percent}% 할인' : d.cond,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(fontWeight: AppType.w600)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  static String _dealIcon(MemberDeal d) {
    final t = '${d.brand} ${d.title}';
    if (t.contains('케이크') || t.contains('베이커리')) return 'cake';
    if (t.contains('꽃')) return 'flower';
    if (t.contains('반찬') || t.contains('식')) return 'food';
    if (t.contains('카페') || t.contains('커피') || t.contains('아메리카노')) return 'coffee';
    if (t.contains('세탁')) return 'laundry';
    if (t.contains('인쇄')) return 'print';
    return 'store';
  }

  /// 가는 김에 (.gkm) — 이웃들이 함께할 사람을 찾는 글. '같이해요' 글을 보여 준다.
  Widget _goingBoard() {
    final posts = widget.items.where((i) => i.mode == 'together' && _inScope(i)).take(2).toList();
    if (posts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 4, 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('가는 김에', style: AppType.sectionSmall),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('이웃들은 지금 무엇을 함께하고 싶을까요?', style: AppType.meta.copyWith(fontSize: 12.5)),
                ),
              ]),
            ),
            _OutlineSmall(icon: 'pencil', label: '글쓰기', onTap: goCommunity),
            const SizedBox(width: 6),
            TextLink(label: '전체보기', onTap: goCommunity),
          ]),
        ),
        for (final p in posts) ...[
          _GoingCard(it: p, onOpen: () => widget.actions.open(context, p)),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }

  // ── 돈벌기 ──────────────────────────────────────────────────────────────

  List<Widget> _earnSections() {
    final list = _tasks;
    final jobs = List.of(dayJobs)..sort((a, b) => b.pay - a.pay);

    return [
      HeroCard(
        sub: '누구나 할 수 있는 부업',
        title: '가는 김에 도와주고\n**수익**을 만들어요',
        liveBold: '내 주변 부탁 ${list.length}건',
        liveRest: '· $_radiusLabel 이내 · 지금 지원할 수 있어요',
        floats: const ['wallet', 'trend', 'sparkles', 'hand'],
        cta: '지금 할 수 있는 일 보기',
        ctaIcon: 'pin',
        onCta: () => _focusNearby(),
        note: '학생도, 선생님도, 어르신도 시간 날 때 함께해요',
        compact: true,
      ),
      _monthEarned(),
      if (list.isNotEmpty) _pickCarousel(list.take(5).toList()),
      _nearby(list, jobs),
      AdBanner(ads: homeAds, onTap: openAd),
      _goingBoard(),
      _localBenefit(),
      _overseasStrip(),
      _bridge(),
      const FootNote('공개된 장소에서 만나고, 대화·정산은 앱 안에서 남겨 주세요'),
    ];
  }

  /// 이번 달 내가 번 금액 (.ehd)
  Widget _monthEarned() {
    return SecCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('이번 달 내가 번 금액', style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w500)),
            const SizedBox(height: 3),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: nf(widget.monthEarn)),
                const TextSpan(text: '원', style: TextStyle(fontSize: 17)),
              ]),
              style: const TextStyle(fontSize: 26, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -1.04),
            ),
          ]),
        ),
        _SoftPillButton(label: '지갑', onTap: widget.goPay),
      ]),
    );
  }

  /// 이거 하나 하고 갈래요? (.pick)
  Widget _pickCarousel(List<TaskItem> picks) {
    final idx = pickIdx.clamp(0, picks.length - 1);
    return SecCard(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 14, 6),
          child: Row(children: [
            Expanded(child: Text('이거 하나 하고 갈래요?', style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600))),
            Text('${idx + 1} / ${picks.length}', style: AppType.meta.copyWith(color: AppColors.faint)),
            const SizedBox(width: 6),
            _RoundArrow(icon: Icons.chevron_left_rounded, enabled: idx > 0, onTap: () => _pickGo(idx - 1)),
            const SizedBox(width: 4),
            _RoundArrow(icon: Icons.chevron_right_rounded, enabled: idx < picks.length - 1, onTap: () => _pickGo(idx + 1)),
          ]),
        ),
        SizedBox(
          height: 97,
          child: PageView.builder(
            controller: _pickCtrl,
            itemCount: picks.length,
            onPageChanged: (i) => setState(() => pickIdx = i),
            itemBuilder: (_, i) => _PickCard(it: picks[i], onOpen: () => widget.actions.open(context, picks[i])),
          ),
        ),
      ]),
    );
  }

  void _pickGo(int i) => _pickCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);

  /// 지금 내 주변 부탁 (.sec.near)
  Widget _nearby(List<TaskItem> list, List<DayJob> jobs) {
    return SecCard(
      key: _nearbyKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SecHead(title: '지금 내 주변 부탁', action: '부탁 전체보기', onAction: goLocalHub),
        UnderlineTabs(
          tabs: [('동네 부탁', null), ('단기알바', '${jobs.length}')],
          index: kind == 'ask' ? 0 : 1,
          onChanged: (i) => setState(() {
            kind = i == 0 ? 'ask' : 'job';
            showMap = false;
          }),
        ),
        if (kind == 'ask') ...[
          _filterRow(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '${list.length}', style: const TextStyle(fontWeight: AppType.w700, color: AppColors.ink)),
                TextSpan(text: '개의 부탁 · $_radiusLabel 이내${cat == 'all' ? '' : ' · ${catOf(cat).label}'}'),
              ]),
              style: AppType.meta,
            ),
          ),
          if (showMap) _inlineMap(list) else _taskList(list),
          SoftButton(label: '부탁 전체 보기', onTap: goLocalHub),
        ] else
          _dayJobs(jobs),
      ]),
    );
  }

  /// 반경 · 정렬 · 종류 · 30분 · 지도 (.nf)
  Widget _filterRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _SelectBox<double>(
            label: '반경',
            icon: Icons.place_outlined,
            value: radius,
            display: '$_radiusLabel 이내',
            items: const [
              (0.5, '500m 이내'), (1.0, '1km 이내'), (3.0, '3km 이내'),
              (5.0, '5km 이내'), (10.0, '10km 이내'), (20.0, '20km 이내'), (30.0, '30km 이내'),
            ],
            onChanged: (v) => setState(() => radius = v),
          ),
          const SizedBox(width: 6),
          _SelectBox<String>(
            label: '정렬',
            value: sort,
            display: _sortLabels[sort]!,
            items: const [
              ('dist', '가까운순'), ('price', '금액 높은순'), ('time', '소요시간 짧은순'),
              ('deadline', '마감 임박순'), ('new', '최신순'),
            ],
            onChanged: (v) => setState(() => sort = v),
          ),
          const SizedBox(width: 6),
          _SelectBox<String>(
            label: '종류',
            value: cat,
            display: cat == 'all' ? '전체 종류' : catOf(cat).label,
            items: [('all', '전체 종류'), for (final c in cats) (c.k, c.label)],
            onChanged: (v) => setState(() => cat = v),
          ),
          const SizedBox(width: 6),
          _ToggleBox(label: '30분 이내', active: shortOnly, onTap: () => setState(() => shortOnly = !shortOnly)),
          const SizedBox(width: 6),
          _ToggleBox(
            label: showMap ? '목록' : '지도',
            icon: showMap ? Icons.format_list_bulleted_rounded : Icons.map_outlined,
            active: showMap,
            onTap: () => setState(() {
              showMap = !showMap;
              pinned = null;
            }),
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
    final shown = list.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(children: [
        for (int i = 0; i < shown.length; i++)
          TaskCard(
            it: shown[i],
            onOpen: () => widget.actions.open(context, shown[i]),
            done: widget.actions.grabbed.contains(shown[i].id),
            last: i == shown.length - 1,
          ),
      ]),
    );
  }

  /// 목록과 **같은 조건**의 결과를 네이버 지도 위에 올린다.
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Text(
          located.length == list.length ? '목록과 같은 조건의 결과예요' : '좌표가 있는 ${located.length}건만 지도에 표시돼요',
          textAlign: TextAlign.center,
          style: AppType.caption,
        ),
      ),
      Container(
        height: 300,
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(AppRadius.tile)),
        child: MapCanvas(
          pins: [
            for (final it in located)
              MapPin(
                item: it,
                lat: it.lat!,
                lng: it.lng!,
                label: (it.hot ? '급 ' : '') + kwon(it.price),
                color: it.id == selected?.id
                    ? AppColors.heroAccent
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TaskCard(
            it: selected,
            onOpen: () => widget.actions.open(context, selected),
            done: widget.actions.grabbed.contains(selected.id),
            last: true,
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text('이 조건에는 지도에 찍을 부탁이 없어요', textAlign: TextAlign.center, style: AppType.meta),
        ),
    ]);
  }

  Widget _dayJobs(List<DayJob> jobs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('근무일 · 근무시간 · 일급 · 지급일을 부탁과 구분해 안내해요', style: AppType.meta),
        const SizedBox(height: 10),
        for (final j in jobs.take(4)) DayJobCard(j: j, onOpen: () => openDayJob(context, j, _applyDayJob), compact: true),
        SoftButton(label: '단기알바 전체 보기', onTap: goDayJobs, margin: const EdgeInsets.only(top: 6)),
      ]),
    );
  }

  /// 우리 동네 혜택 (.adcard — 회원 전용가 한 장)
  Widget _localBenefit() {
    final d = memberDeals.where((d) => d.menu != 'finance').firstOrNull;
    if (d == null) return const SizedBox.shrink();
    return SecCard(
      child: Column(children: [
        SecHead(title: '우리 동네 혜택', action: '혜택 전체보기', onAction: goSaveHub),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: AppColors.page,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: goSaveHub,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  IconTile(icon: _dealIcon(d), bg: const Color(0xFFF0EDEA), fg: const Color(0xFF6B4A2E), size: 64, iconSize: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.brand, style: AppType.body.copyWith(fontWeight: AppType.w600, color: AppColors.ink2)),
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(d.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.body.copyWith(fontSize: 16, fontWeight: AppType.w700)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          [if (d.isPriced) '회원가 ${nf(d.memberPrice)}원', d.area].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.meta.copyWith(fontWeight: AppType.w500),
                        ),
                      ),
                    ]),
                  ),
                  if (d.isPriced) StatusBadge.red('${d.percent}%'),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  /// 여행 가는 길에, 해외 부탁 (.oscard 가로 넘김)
  Widget _overseasStrip() {
    final sea = widget.items.where((i) => i.mode == 'sea' && !i.isExpired).take(6).toList();
    if (sea.isEmpty) return const SizedBox.shrink();
    return SecCard(
      child: Column(children: [
        SecHead(
          title: '여행 가는 길에, 해외 부탁',
          count: '${widget.items.where((i) => i.mode == 'sea').length}',
          action: '전체',
          onAction: widget.goOverseasTab,
          sub: '사다주고 부탁 비용 받기 · 상품가는 요청자가 선결제해요',
        ),
        SizedBox(
          height: 151,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sea.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _OverseasCard(it: sea[i], onOpen: () => widget.actions.open(context, sea[i])),
          ),
        ),
      ]),
    );
  }

  /// 미션·공구로 더 벌기 (.bridge)
  Widget _bridge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.surface),
        child: InkWell(
          onTap: () => widget.goSideTab(0),
          borderRadius: BorderRadius.circular(AppRadius.surface),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              const IconTile(icon: 'gift', bg: Color(0xFFFBF5E6), fg: Color(0xFFD99A00)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('미션·공구로 더 벌기', style: AppType.body.copyWith(fontWeight: AppType.w700)),
                  Text('설문·체험 미션, 공동구매', style: AppType.meta.copyWith(fontWeight: AppType.w600)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 주요 서비스 타일 (.hs-c)
class _ServiceTile extends StatelessWidget {
  final String icon, title, sub;
  final Color bg, fg;
  final VoidCallback onTap;
  const _ServiceTile({required this.icon, required this.title, required this.sub, required this.bg, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 9),
          child: Column(children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
              child: Icon(AppIcon.data(icon), size: 16, color: fg),
            ),
            const SizedBox(height: 5),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w700, letterSpacing: -0.39)),
            const SizedBox(height: 1),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption.copyWith(fontSize: 10.5, fontWeight: AppType.w600)),
          ]),
        ),
      ),
    );
  }
}

/// 바로가기 한 칸 (.hq-c)
class _Quick extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _Quick({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(children: [
            Icon(AppIcon.data(icon), size: 20, color: AppColors.ink2),
            const SizedBox(height: 3),
            Text(label, style: AppType.caption.copyWith(fontWeight: AppType.w500, color: AppColors.ink2)),
          ]),
        ),
      ),
    );
  }
}

/// 가는 김에 글 한 장 (.gk)
class _GoingCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  const _GoingCard({required this.it, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final who = it.who.isEmpty ? '이웃' : it.who;
    final tone = it.id.isEven ? AppColors.blue : AppColors.green;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tone.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Text(who.characters.first, style: TextStyle(fontSize: 11, fontWeight: AppType.w700, color: tone)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '$who  ', style: const TextStyle(fontWeight: AppType.w600, color: AppColors.ink2)),
                    TextSpan(
                      text: [shortRegion(it.region ?? ''), it.ago ?? '', if (it.sample) '예시'].where((s) => s.isNotEmpty).join(' · '),
                    ),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.meta,
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(it.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(fontSize: 14.5, fontWeight: AppType.w700, letterSpacing: -0.43)),
            ),
            if (it.desc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('“${it.desc}”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body.copyWith(fontSize: 13, color: AppColors.ink2)),
              ),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.mode_comment_outlined, size: 14, color: AppColors.sub),
              const SizedBox(width: 4),
              Text('댓글 ${it.comments.length}', style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w500)),
              const Spacer(),
              _OutlineSmall(label: it.joinMax > 0 ? '같이하기' : '보러가기', onTap: onOpen),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// 흰 바탕 + 1px 안쪽 테두리 작은 버튼 (.gkm-write · .gk-cta)
class _OutlineSmall extends StatelessWidget {
  final String? icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineSmall({this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9), side: const BorderSide(color: AppColors.soft2)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(AppIcon.data(icon!), size: 13, color: AppColors.ink),
              const SizedBox(width: 4),
            ],
            Text(label, style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w600, color: AppColors.ink)),
          ]),
        ),
      ),
    );
  }
}

/// 회색 작은 버튼 (.ehd-top button — 지갑 ›)
class _SoftPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SoftPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.page,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 34,
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: AppColors.ink2)),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.ink2),
          ]),
        ),
      ),
    );
  }
}

/// 동그란 화살표 버튼 (.pk-a)
class _RoundArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _RoundArrow({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.soft2)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: enabled ? AppColors.ink2 : AppColors.soft2),
        ),
      ),
    );
  }
}

/// 이거 하나 하고 갈래요? 한 장 (.pk-card)
class _PickCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  const _PickCard({required this.it, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CatEmblem(cat: it.cat, size: 22, radius: 7, iconSize: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                [catOf(it.cat).label, it.place ?? it.region ?? '', if (it.sample) '예시'].where((s) => s.isNotEmpty).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.meta.copyWith(fontWeight: AppType.w500),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(it.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body.copyWith(fontSize: 16, fontWeight: AppType.w700, letterSpacing: -0.56)),
          ),
          const Spacer(),
          Row(children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '+${nf(it.price)}'),
                const TextSpan(text: '원', style: TextStyle(fontSize: 14)),
              ]),
              style: const TextStyle(fontSize: 18, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -0.54),
            ),
            const Spacer(),
            _MetaChip(icon: Icons.schedule_rounded, label: '약 ${it.mins > 0 ? it.mins : 10}분'),
            const SizedBox(width: 6),
            _MetaChip(icon: Icons.place_outlined, label: distLabel(it)),
          ]),
        ]),
      ),
    );
  }
}

/// 회색 작은 정보 칩 (.pick-meta span)
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(7)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.ink2),
        const SizedBox(width: 4),
        Text(label, style: AppType.caption.copyWith(fontSize: 11.5, fontWeight: AppType.w600, color: AppColors.ink2)),
      ]),
    );
  }
}

/// 해외 부탁 가로 카드 (.oscard)
class _OverseasCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  const _OverseasCard({required this.it, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.page,
      borderRadius: BorderRadius.circular(AppRadius.surface),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.surface),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CountryFlag(cc: it.cc, size: 30, radius: 9),
              const SizedBox(width: 8),
              Expanded(
                child: Text(seaPlace(it),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.meta.copyWith(fontWeight: AppType.w700)),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(it.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(fontSize: 15, fontWeight: AppType.w700, height: 1.35)),
            ),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Text('부탁 비용\n영수증으로 정산',
                    style: AppType.caption.copyWith(fontSize: 11.5, fontWeight: AppType.w600, height: 1.45)),
              ),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: nf(it.price)),
                  const TextSpan(text: '원', style: TextStyle(fontSize: 14)),
                ]),
                style: const TextStyle(fontSize: 18, fontWeight: AppType.w700, color: AppColors.ink, letterSpacing: -0.54),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// 시안의 `<select>` 자리 (.nf-sel). 누르면 바텀시트가 열린다.
class _SelectBox<T> extends StatelessWidget {
  final String label;
  final IconData? icon;
  final T value;
  final String display;
  final List<(T, String)> items;
  final void Function(T) onChanged;
  const _SelectBox({required this.label, this.icon, required this.value, required this.display, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.soft2)),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: AppColors.sub),
              const SizedBox(width: 4),
            ],
            Text(display, style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: AppColors.ink)),
            const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.sub),
          ]),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.surface))),
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.7),
          child: SingleChildScrollView(
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
        ),
      ),
    );
  }
}

/// 켜고 끄는 작은 상자 (30분 이내 · 지도)
class _ToggleBox extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBox({required this.label, this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.ink : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: active ? AppColors.ink : AppColors.soft2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: active ? Colors.white : AppColors.ink2),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: active ? Colors.white : AppColors.ink)),
          ]),
        ),
      ),
    );
  }
}
