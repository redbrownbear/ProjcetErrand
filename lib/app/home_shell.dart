import 'package:flutter/material.dart';

import '../core/navigation/screen_route.dart';
import '../core/theme/colors.dart';
import '../core/widgets/screen_frame.dart';
import '../features/activity/screens/activity_view.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/benefits/models/partner_mission.dart';
import '../features/benefits/models/reward_product.dart';
import '../features/benefits/screens/attendance_screen.dart';
import '../features/benefits/screens/side_job_view.dart';
import '../features/chat/screens/chat_view.dart';
import '../features/dayjob/screens/job_post_screen.dart';
import '../features/errand/models/new_request_data.dart';
import '../features/errand/models/task_item.dart';
import '../features/errand/navigation/errand_actions.dart';
import '../features/errand/screens/create_choice_screen.dart';
import '../features/errand/screens/home/home_content.dart';
import '../features/errand/screens/list_screen.dart';
import '../features/errand/screens/overseas_tab.dart';
import '../features/errand/screens/post/post_request.dart';
import '../features/errand/screens/search_screen.dart';
import '../features/errand/widgets/region_sheet.dart';
import '../features/pay/screens/pay_screen.dart';
import '../features/profile/screens/me_view.dart';
import '../features/profile/screens/saved_screen.dart';
import 'app_session.dart';
import 'widgets/shell_bottom_nav.dart';
import 'widgets/shell_header.dart';
import 'widgets/shell_overlays.dart';

/// 앱의 껍데기. 헤더 · 탭 화면 · 하단 메뉴를 그리고 화면 사이를 오간다.
///
/// 자료와 그 변경은 [AppSession]이 맡는다. 여기서는 세 가지만 한다.
/// - 지금 어느 탭인지 기억하고 탭 화면을 그린다
/// - 다른 화면으로 넘긴다 (부탁 쓰기, 진행 중, 겸사페이 …)
/// - 참여 행동(지원·제안·적립·교환·등록) 앞에서 로그인을 확인한다. 둘러보기는 로그인 없이 된다
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final AppSession session = AppSession();

  ShellTab tab = ShellTab.home;

  /// 미션·공구 탭의 안쪽 탭 — 0 미션 · 1 공동구매
  int sideSub = 0;

  /// 앱을 열면 잠깐 보이는 시작 화면
  bool splash = true;

  @override
  void initState() {
    super.initState();
    session.addListener(_onSessionChanged);
    session.start();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && splash) setState(() => splash = false);
    });
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    session.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  // ── 로그인 확인 ─────────────────────────────────────────────────────────

  /// 로그인돼 있으면 바로, 아니면 로그인 화면을 거친 뒤 [action]을 실행한다.
  /// 로그인하지 않고 돌아오면 아무 일도 하지 않는다.
  Future<void> requireLogin(VoidCallback action) async {
    if (session.isLoggedIn) {
      action();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (!mounted || !session.isLoggedIn) return;
    action();
  }

  Future<void> earn(int amount, String label, {required String key, bool daily = true}) =>
      requireLogin(() => session.earn(amount, label, key: key, daily: daily));

  void redeem(RewardProduct p) => requireLogin(() => session.redeem(p));
  void useCoupon(int id) => requireLogin(() => session.useCoupon(id));
  void completeMission(PartnerMission m) => requireLogin(() => session.completeMission(m));
  void checkIn() => requireLogin(session.checkIn);
  void sendOffer(TaskItem it, int price, String msg) => requireLogin(() => session.sendOffer(it, price, msg));

  /// 지원하기. 지원되면 홈으로 돌아와 진행 중 화면을 연다.
  void grab(TaskItem it) => requireLogin(() {
    if (!session.apply(it)) return;
    _switchTab(ShellTab.home);
    goActivity();
  });

  void addRequest(NewRequestData data) {
    session.addRequest(data);
    setState(() => tab = ShellTab.home);
  }

  ErrandActions get actions => ErrandActions(
    grabbed: session.grabbed,
    onGrab: grab,
    onOffer: sendOffer,
    offers: session.offers,
    isSaved: session.bookmarks.contains,
    toggleSave: session.toggleSave,
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
  void goOverseasTab() => _switchTab(ShellTab.overseas);
  void goProfile() => _switchTab(ShellTab.me);

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  /// [AppSession]이 바뀌면 다시 그려지는 화면을 띄운다.
  /// 탭이 아닌 화면에서도 포인트·관심 목록이 바로 반영되게 하기 위함이다.
  void _pushLive(Widget Function() build) => _push(ListenableBuilder(listenable: session, builder: (_, _) => build()));

  void goSearch() => _push(SearchScreen(items: session.items, actions: actions));

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
        openDetail: (it) => actions.open(context, it),
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

  /// 부탁 쓰기 폼. [kind]는 ask(동네 부탁) | sea(해외 사다주기).
  void _openRequestForm(String kind, {String? cat}) =>
      _push(PostRequest(scope: session.scope, onSubmit: addRequest, initialKind: kind, initialCat: cat));

  /// 갈래(동네 부탁 · 해외 사다주기 · 단기알바 모집)부터 고르는 부탁하기
  void openPost() => requireLogin(
    () => _push(
      CreateChoiceScreen(onLocal: () => _openRequestForm('ask'), onOverseas: () => _openRequestForm('sea'), onJob: openJobPost),
    ),
  );

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

  Widget _body() {
    final s = session;
    return switch (tab) {
      ShellTab.home => HomeContent(
        items: s.items,
        scope: s.scope,
        actions: actions,
        points: s.points,
        steps: s.steps,
        monthEarn: s.monthEarnedCash,
        goPay: goPay,
        goProfile: goProfile,
        coupons: s.coupons,
        doneMissions: s.doneMissions,
        earn: earn,
        isClaimed: s.isClaimed,
        redeem: redeem,
        useCoupon: useCoupon,
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
        points: s.points,
        coupons: s.coupons,
        items: s.items,
        scope: s.scope,
        actions: actions,
        monthEarn: s.monthEarnedCash,
        freeLeft: s.freeLeft,
        doneMissions: s.doneMissions,
        earn: earn,
        isClaimed: s.isClaimed,
        redeem: redeem,
        useCoupon: useCoupon,
        completeMission: completeMission,
        goPointsHub: goPointsHub,
        flash: s.flash,
      ),
      ShellTab.overseas => OverseasTab(items: s.items, actions: actions, onPostSea: openPostSea),
      ShellTab.chat => ChatView(onGoActivity: goActivity),
      ShellTab.me => MeView(
        profile: s.profile,
        stats: s.stats,
        trust: s.trust,
        points: s.points,
        payBalance: s.payBalance,
        coupons: s.coupons,
        useCoupon: useCoupon,
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
                    onSearch: goSearch,
                    onPost: openPost,
                    onBell: () => session.flash('새 알림이 없어요'),
                    hasNews: session.activeCount > 0,
                  ),
                  Expanded(child: _body()),
                  ShellBottomNav(current: tab, onSelect: (next) => next == ShellTab.side ? goSideTab(sideSub) : _switchTab(next)),
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
