import 'package:flutter/material.dart';

import '../core/navigation/screen_route.dart';
import '../core/theme/colors.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/kit.dart';
import '../core/widgets/screen_frame.dart';
import '../features/activity/screens/activity_view.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/benefits/models/partner_mission.dart';
import '../features/benefits/models/point_wallet.dart';
import '../features/benefits/models/reward_product.dart';
import '../features/benefits/screens/attendance_screen.dart';
import '../features/benefits/screens/side_job_view.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/chat/screens/chat_view.dart';
import '../features/trip/screens/trip_screens.dart';
import '../features/trip/screens/trip_tab.dart';
import '../features/errand/models/application.dart';
import '../features/community/screens/community_view.dart';
import '../features/dayjob/screens/job_post_screen.dart';
import '../features/errand/models/new_request_data.dart';
import '../features/errand/models/task_item.dart';
import '../features/errand/navigation/errand_actions.dart';
import '../features/errand/screens/home/home_content.dart';
import '../features/errand/screens/list_screen.dart';
import '../features/errand/screens/overseas_tab.dart';
import '../features/errand/screens/post/post_request.dart';
import '../features/errand/widgets/region_sheet.dart';
import '../features/lucky/models/tickets.dart';
import '../features/lucky/widgets/lucky_card.dart';
import '../features/market/models/used_item.dart';
import '../features/pay/screens/pay_screen.dart';
import '../features/profile/screens/me_view.dart';
import '../features/profile/screens/saved_screen.dart';
import 'app_nav.dart';
import 'app_session.dart';
import 'neighbor_store.dart';
import 'widgets/shell_bottom_nav.dart';
import 'widgets/shell_header.dart';
import 'widgets/shell_overlays.dart';

/// 앱의 껍데기. 헤더 · 탭 화면 · 하단 메뉴를 그리고 화면 사이를 오간다.
///
/// 자료와 그 변경은 [AppSession]이 맡는다. 여기서는 세 가지만 한다.
/// - 지금 어느 탭인지 기억하고 탭 화면을 그린다
/// - 다른 화면으로 넘긴다 (부탁 쓰기, 진행 중, 겸사페이 …)
///   v77 이웃 활동(제안 · 커뮤니티 이야기 · 가는 김에 · 중고 · 응모권)은 [NeighborStore]와 [AppNav]가 맡는다
/// - 참여 행동(지원·제안·적립·교환·등록) 앞에서 로그인을 확인한다. 둘러보기는 로그인 없이 된다
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final AppSession session = AppSession();

  ShellTab tab = ShellTab.home;

  /// v77 이웃 활동(제안 · 이야기 · 가는 김에 · 중고 · 응모권). 이 기기에 보관된다.
  final NeighborStore store = NeighborStore();

  /// 탭 어디서나 v77 화면을 여는 길목
  late final AppNav social = AppNav(
    store: store,
    nickname: () => session.profile?.nickname ?? '나',
    area: () => shortRegion(session.scope),
    items: () => session.items,
    actions: () => actions,
    flash: session.flash,
    openAskForm: () => requireLogin(() => _openRequestForm('ask')),
    openSeaForm: openPostSea,
    openTripPost: openTripPost,
    session: session,
    openChat: (tradeId) {
      final t = session.tradeById(tradeId);
      if (t != null) openChat(t);
    },
    requireLogin: requireLogin,
    goTripTab: () => _switchTab(ShellTab.trip),
    goCommunity: goCommunity,
    requestDelivery: _requestDelivery,
  );

  /// 마켓 탭의 안쪽 탭 — 0 미션 · 1 공동구매 · 2 중고장터 · 3 나눔
  int sideSub = 0;

  /// 홈 맨 위 국내 / 해외 전환 (v77 — 예전 하단 '해외' 탭)
  bool homeAbroad = false;

  final _communityKey = GlobalKey<CommunityViewState>();

  /// 앱을 열면 잠깐 보이는 시작 화면
  bool splash = true;

  @override
  void initState() {
    super.initState();
    session.addListener(_onSessionChanged);
    session.onTicket = _gainTicket;
    session.start();
    store.toast = session.flash;
    store.gate = requireLogin;
    store.addListener(_onSessionChanged);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && splash) setState(() => splash = false);
    });
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    session.dispose();
    store.removeListener(_onSessionChanged);
    store.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  /// 출석·미션은 자체 적립 안내가 뜨므로 응모권 안내는 조용히 쌓는다.
  void _gainTicket(TicketRule rule, {int? n}) {
    final quiet = rule == TicketRules.attend || rule == TicketRules.visit || rule == TicketRules.survey;
    store.gainTicket(rule, n: n, quiet: quiet);
  }

  // ── 로그인 확인 ─────────────────────────────────────────────────────────

  /// 로그인돼 있으면 바로, 아니면 로그인 화면을 거친 뒤 [action]을 실행한다.
  /// 로그인하지 않고 돌아오면 아무 일도 하지 않는다.
  ///
  /// 실행 전에 계정의 서버 자료가 다 붙기를 기다린다. 안 그러면 방금 받은 포인트를
  /// 뒤늦게 도착한 서버 값이 덮어쓴다 ([AppSession.accountReady]).
  Future<void> requireLogin(VoidCallback action) async {
    if (!session.isLoggedIn) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (!mounted || !session.isLoggedIn) return;
    }
    await session.accountReady();
    if (!mounted || !session.isLoggedIn) return;
    action();
  }

  Future<void> earn(int amount, String label, {required String key, bool daily = true}) =>
      requireLogin(() => session.earn(amount, label, key: key, daily: daily));

  /// 교환됐으면 true. 로그인을 취소했거나 포인트가 모자라면 false.
  Future<bool> redeem(RewardProduct p) async {
    var ok = false;
    await requireLogin(() => ok = session.redeem(p));
    return ok;
  }

  void useCoupon(int id) => requireLogin(() => session.useCoupon(id));

  /// 포인트·쿠폰을 보여 주고 바꾸는 화면들이 같이 쓰는 지갑. 열린 화면도 바뀐 값을 바로 그린다.
  late final PointWallet wallet = PointWallet(
    changes: session,
    readPoints: () => session.points,
    readCoupons: () => session.coupons,
    redeem: redeem,
    useCoupon: useCoupon,
  );
  void completeMission(PartnerMission m) => requireLogin(() => session.completeMission(m));
  void checkIn() => requireLogin(session.checkIn);
  void sendOffer(TaskItem it, int price, String msg) => requireLogin(() => session.sendOffer(it, price, msg));

  /// 지원하기. 지원되면 홈으로 돌아와 진행 중 화면을 연다.
  void grab(TaskItem it) => requireLogin(() async {
    if (!await session.apply(it)) return;
    if (!mounted) return;
    _switchTab(ShellTab.home);
    goActivity();
  });

  void addRequest(NewRequestData data) {
    session.addRequest(data);
    setState(() => tab = ShellTab.home);
  }

  ErrandActions get actions => _buildActions();

  ErrandActions _buildActions() => ErrandActions(
    grabbed: session.grabbed,
    onGrab: grab,
    onOffer: sendOffer,
    offers: session.offers,
    // `session.bookmarks.contains`로 넘기면 그 순간의 목록에 묶여서, 저장할 때마다
    // 목록이 새로 바뀌어도 상세 화면의 관심 표시가 옛 값을 본다.
    isSaved: (id) => session.bookmarks.contains(id),
    toggleSave: session.toggleSave,
    onReport: session.report,
    onBlock: session.block,
    onAskGoing: session.askGoing,
    goingAsk: session.myGoingAsk,
    myUid: session.myUid,
    changes: session,
    latest: _buildActions,
  );

  // ── 이동 ────────────────────────────────────────────────────────────────

  /// 푸시된 화면을 모두 닫고 탭을 바꾼다.
  void _switchTab(ShellTab next) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => tab = next);
  }

  /// 미션·공구 탭으로 — [sub] 0 미션 · 1 공동구매
  void goSideTab(int sub) {
    sideSub = sub;
    _switchTab(ShellTab.side);
  }

  void goPointsHub() => goSideTab(0);

  /// 홈의 '해외' 쪽으로
  void goOverseasTab() {
    homeAbroad = true;
    _switchTab(ShellTab.home);
  }

  /// 커뮤니티 탭으로 — [scope] local · travel · abroad, [place] 지역 또는 나라 코드
  void goCommunity(String scope, {String? place}) {
    _switchTab(ShellTab.community);
    WidgetsBinding.instance.addPostFrameCallback((_) => _communityKey.currentState?.focus(scope, place: place));
  }

  /// 중고 물건 전달 부탁 — 전달비만 정하면 돈벌기 목록에 '중고'로 올라간다
  void _requestDelivery(UsedItem u) {
    var fee = 5000;
    showSheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SheetFrame(
          title: '전달 부탁하기',
          sub: '${u.title} — 가는 길인 이웃에게 맡겨요',
          bottom: BigButton(
            label: '${won(fee)}로 전달 부탁 올리기',
            onTap: () {
              Navigator.pop(ctx);
              requireLogin(() => session.addDelivery(u, fee));
            },
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('전달비'),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in const [3000, 5000, 8000, 12000])
                    ChoiceChip(
                      label: Text(won(f)),
                      selected: fee == f,
                      onSelected: (_) => setSheet(() => fee = f),
                      selectedColor: AppColors.ink,
                      labelStyle: TextStyle(color: fee == f ? Colors.white : AppColors.ink2, fontWeight: FontWeight.w700),
                      showCheckmark: false,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '물건값은 판매자와 따로 정산하세요. 전달비도 앱 결제가 준비 중이라 전달한 이웃에게 직접 주고받아요.',
                style: TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotifications() {
    final notices = session.notices;
    session.markNoticesRead();
    showSheet(
      context,
      (ctx) => SheetFrame(
        title: '알림',
        child: Column(
          children: [
            // 서버가 보낸 거래 알림(지원·수락·단계 변경). 누르면 진행 중인 부탁으로 간다
            for (final n in notices.take(10))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.circle, size: 8, color: n.read ? Colors.transparent : AppColors.red),
                minLeadingWidth: 8,
                title: Text(n.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                subtitle: Text(
                  '${n.body}\n${dateTimeLabel(n.createdAt)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.5),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  // 댓글 알림은 그 글로, 나머지(지원·거래)는 진행 중인 부탁으로
                  final rid = int.tryParse(n.requestId ?? '');
                  final it = rid == null ? null : session.items.where((i) => i.id == rid).firstOrNull;
                  if (n.kind == 'request.comment' && it != null) {
                    actions.open(context, it);
                  } else {
                    goActivity();
                  }
                },
              ),
            if (notices.isNotEmpty) const Divider(height: 20),
            for (final (title, sub, go) in [
              ('부탁 진행 상황', '지원·진행 중·완료 내역을 확인하세요', goActivity),
              ('미션 참여 상황', '참여 중·검수 대기·적립 완료', goPointsHub),
              ('제안 · 구매 요청', '내가 올린 제안과 구매 요청한 제안', () => social.openProposalList(context, abroad: false)),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                subtitle: Text(sub, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                onTap: () {
                  Navigator.pop(ctx);
                  go();
                },
              ),
          ],
        ),
      ),
    );
  }

  void goProfile() => _switchTab(ShellTab.me);

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  /// [AppSession]이 바뀌면 다시 그려지는 화면을 띄운다.
  /// 탭이 아닌 화면에서도 포인트·관심 목록이 바로 반영되게 하기 위함이다.
  void _pushLive(Widget Function() build) => _push(ListenableBuilder(listenable: session, builder: (_, _) => build()));

  /// 거래 한 건의 채팅방
  void openChat(ServerTrade t) {
    final uid = session.myUid;
    if (uid == null) return;
    _push(
      ChatScreen(
        tradeId: t.id,
        title: t.title,
        myUid: uid,
        peerLabel: t.requesterUid == uid ? '수행자와 대화' : '요청자와 대화',
        closed: !t.isOpenForChat,
      ),
    );
  }

  /// 진행 중인 부탁. 탭이 아니라 홈 배너·채팅에서 여는 전체화면이다.
  void goActivity() => _pushLive(
    () => ScreenFrame(
      title: '진행 중인 부탁',
      subtitle: '현재 상태와 다음 할 일을 확인하세요',
      onBack: () => Navigator.of(context).pop(),
      child: ActivityView(
        items: session.items,
        trades: session.trades,
        updateTrade: session.updateTrade,
        received: session.received,
        onAccept: session.acceptApplication,
        onReject: session.rejectApplication,
        openChat: (requestId) {
          final t = session.tradeFor(requestId);
          if (t != null) openChat(t);
        },
        canChat: (requestId) => session.tradeFor(requestId)?.isOpenForChat ?? false,
        openDetail: (it) => actions.open(context, it),
        goingDeals: session.goingDeals,
        onDeal: session.advanceDeal,
        openDealChat: (tradeId) {
          final t = session.tradeById(tradeId);
          if (t != null) openChat(t);
        },
        openRequest: (id) {
          final it = session.items.where((i) => i.id == id).firstOrNull;
          if (it != null) actions.open(context, it);
        },
        showHeader: false,
      ),
    ),
  );

  void goPay() => _pushLive(
    () => PayScreen(
      entries: session.payEntries,
      flash: session.flash,
      onCharge: session.payCharge,
      onWithdraw: session.payWithdraw,
    ),
  );

  void goAttendance() => _pushLive(() => AttendanceScreen(attendance: session.attendance, onCheckIn: checkIn, onOpenPay: goPay));

  void _openFilteredList(String title, bool Function(TaskItem) filter) => _pushLive(
    () => ListScreen(
      config: ScreenRoute(name: 'list', title: title, sortable: true, filter: filter),
      items: session.items,
      scope: session.scope,
      actions: actions,
    ),
  );

  /// 부탁 쓰기 폼. [kind]는 ask(동네 부탁) | sea(해외 사다주기) | going(가는 김에 · 제가 가요).
  /// [extra]가 trip이면 '가는 김에 · 가는 분 찾아요'(일반 부탁).
  void _openRequestForm(String kind, {String? cat, String? extra}) => _push(
    PostRequest(scope: session.scope, onSubmit: addRequest, initialKind: kind, initialCat: cat, initialExtra: extra),
  );

  /// 가는 김에 글쓰기 — [going]이면 제가 가요(도움 주기), 아니면 가는 분 찾아요(도움 요청)
  /// 제가 가요는 시안 v78의 '나 여기 가요'(장소·시각·받을 부탁) 화면으로 연다
  void openTripPost({bool going = true}) =>
      going ? openTripRegister(context, social) : requireLogin(() => _openRequestForm('ask', extra: 'trip'));

  /// 오른쪽 위 '글쓰기' — 가는 김에 · 제안 · 부탁 · 해외 부탁 · 중고 · 커뮤니티 중에서 고른다 (v77).
  /// 단기알바 모집은 홈 바로가기 '전체'에 있다.
  void openPost() => social.openWrite(context);

  void openPostCat(String cat) => requireLogin(() => _openRequestForm('ask', cat: cat));
  void openPostSea() => requireLogin(() => _openRequestForm('sea'));

  /// 단기알바 모집 등록. 일상 부탁과 달리 근로 조건을 받는 별도 폼이다.
  void openJobPost() =>
      requireLogin(() => _push(JobPostScreen(scope: session.scope, onSubmit: (_) => session.flash('단기알바를 등록했어요 · 이 기기에 저장돼요'))));

  Future<void> openRegion() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegionSheet(scope: session.scope),
    );
    if (picked != null) session.setScope(picked);
  }

  // ── 화면 ────────────────────────────────────────────────────────────────

  /// 홈 맨 위 국내 / 해외 전환
  Widget _homeSwitch() => BigTabs(
    labels: const ['국내', '해외'],
    index: homeAbroad ? 1 : 0,
    accent: homeAbroad ? AppColors.blue : AppColors.yellow,
    onChanged: (i) => setState(() => homeAbroad = i == 1),
  );

  Widget _body() {
    final s = session;
    return switch (tab) {
      ShellTab.home when homeAbroad => OverseasTab(
        items: s.items,
        actions: actions,
        onPostSea: openPostSea,
        social: social,
        header: _homeSwitch(),
      ),
      ShellTab.home => HomeContent(
        header: _homeSwitch(),
        social: social,
        items: s.items,
        scope: s.scope,
        actions: actions,
        wallet: wallet,
        steps: s.steps,
        monthEarn: s.monthEarnedCash,
        goPay: goPay,
        goProfile: goProfile,
        doneMissions: s.doneMissions,
        earn: earn,
        isClaimed: s.isClaimed,
        completeMission: completeMission,
        flash: s.flash,
        goPointsHub: goPointsHub,
        goPost: openPost,
        goPostCat: openPostCat,
        goPostSea: openPostSea,
        goOverseasTab: goOverseasTab,
        goSideTab: goSideTab,
        activeCount: s.activeCount,
        goActivity: goActivity,
        openJobPost: openJobPost,
      ),
      ShellTab.side => SideJobView(
        key: ValueKey('side-$sideSub'),
        initialSub: sideSub,
        wallet: wallet,
        items: s.items,
        scope: s.scope,
        actions: actions,
        monthEarn: s.monthEarnedCash,
        freeLeft: s.freeLeft,
        doneMissions: s.doneMissions,
        earn: earn,
        isClaimed: s.isClaimed,
        completeMission: completeMission,
        goPointsHub: goPointsHub,
        flash: s.flash,
        social: social,
      ),
      ShellTab.community => CommunityView(key: _communityKey, nav: social, goOverseasAsk: goOverseasTab),
      ShellTab.trip => TripTab(nav: social),
      ShellTab.chat => ChatView(
        onGoActivity: goActivity,
        onBrowse: () => _openFilteredList('지금 내 주변 부탁', (i) => i.mode == 'ask'),
        threads: s.chatThreads,
        myUid: s.myUid,
        onOpen: openChat,
      ),
      ShellTab.me => MeView(
        profile: s.profile,
        stats: s.stats,
        trust: s.trust,
        wallet: wallet,
        payBalance: s.payBalance,
        goPointsHub: goPointsHub,
        goPay: goPay,
        goAttendance: goAttendance,
        freeLeft: s.freeLeft,
        isLoggedIn: s.isLoggedIn,
        onLogin: () => requireLogin(() {}),
        onOpenSaved: () => _pushLive(() => SavedScreen(items: s.items, bookmarks: s.bookmarks, actions: actions)),
        onOpenApplied: () => _openFilteredList('지원한 부탁', (i) => s.grabbed.contains(i.id)),
        onOpenMine: () => _openFilteredList('내가 올린 부탁', (i) => i.isMine),
        onOpenActivity: goActivity,
        onRename: s.renameNickname,
        serverIssue: s.serverIssue,
        syncing: s.syncing,
        lucky: LuckyCard(nav: social),
        onOpenProposals: () => social.openProposalList(context, abroad: false),
        proposalCount: store.myProposals.length + store.joined.length,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final toast = session.toast;
    // 탭은 Navigator 라우트가 아니라 상태값이라, 그대로 두면 홈이 아닌 탭에서 시스템 뒤로가기를
    // 눌렀을 때 앱이 종료된다. 홈이 아닌 탭에서는 뒤로가기를 홈 탭 복귀로 쓴다.
    return PopScope(
      canPop: tab == ShellTab.home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => tab = ShellTab.home);
      },
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  ShellHeader(
                    title: tab.title,
                    scope: session.scope,
                    onRegion: openRegion,
                    onPost: openPost,
                    onBell: _openNotifications,
                    tickets: store.wallet.have,
                    onTickets: () => social.openLucky(context),
                    hasNews: session.unreadNotices > 0 || session.activeCount > 0,
                  ),
                  Expanded(child: _body()),
                  ShellBottomNav(
                    current: tab,
                    onSelect: (next) => next == ShellTab.side ? goSideTab(sideSub) : _switchTab(next),
                    badges: {ShellTab.trip: session.tripBadge},
                  ),
                ],
              ),
            ),
            if (toast != null)
              Positioned(
                left: 18,
                right: 18,
                bottom: 98 + MediaQuery.paddingOf(context).bottom,
                child: ToastBar(message: toast),
              ),
            SplashOverlay(visible: splash, onDismiss: () => setState(() => splash = false)),
          ],
        ),
      ),
    );
  }
}
