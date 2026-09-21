import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/backend/backend.dart';
import '../core/backend/user_repository.dart';
import '../core/navigation/screen_route.dart';
import '../core/storage/local_store.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/colors.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_icon.dart';
import '../core/widgets/screen_frame.dart';
import '../features/activity/screens/activity_view.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/services/auth_service.dart';
import '../features/benefits/data/point_rules.dart';
import '../features/benefits/models/coupon.dart';
import '../features/benefits/models/partner_mission.dart';
import '../features/benefits/models/attendance.dart';
import '../features/benefits/models/reward_ledger.dart';
import '../features/benefits/models/reward_product.dart';
import '../features/benefits/screens/side_job_view.dart';
import '../features/chat/screens/chat_view.dart';
import '../features/dayjob/screens/job_post_screen.dart';
import '../features/errand/models/offer.dart';
import '../features/errand/models/task_item.dart';
import '../features/errand/models/trade.dart';
import '../features/errand/navigation/errand_actions.dart';
import '../features/errand/repositories/errand_repository.dart';
import '../features/errand/repositories/request_repository.dart';
import '../features/errand/screens/create_choice_screen.dart';
import '../features/errand/screens/home_content.dart';
import '../features/errand/screens/list_screen.dart';
import '../features/errand/screens/post_request.dart';
import '../features/errand/widgets/region_sheet.dart';
import '../features/pay/models/pay_entry.dart';
import '../features/pay/pay_config.dart';
import '../features/pay/repositories/pay_repository.dart';
import '../features/pay/screens/pay_screen.dart';
import '../features/profile/models/trust_level.dart';
import '../features/profile/models/user_profile.dart';
import '../features/profile/screens/me_view.dart';
import '../features/profile/screens/saved_screen.dart';

/// 앱의 상태를 한곳에 모아 두는 껍데기.
///
/// 저장 위치는 두 군데다.
/// - **서버**(`Backend.ready` && 로그인): `users/{uid}` 아래의 내 자료와 공개 `requests`
/// - **이 기기**(`LocalStore`): 위가 안 될 때의 보관소이자, 서버가 있을 때의 오프라인 사본
///
/// 모든 변경은 화면 상태 → 이 기기 → 서버 순으로 흐른다. 서버 쓰기는 실패해도
/// 화면을 막지 않는다([Backend.push]). 서버가 살아 있으면 다음 로그인 때 다시 맞춰진다.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final ErrandRepository _errandRepository = LocalErrandRepository();
  final RequestRepository _requests = const RequestRepository();

  /// 로그인한 사용자의 서버 자료 저장소. 로그아웃 상태면 null.
  UserRepository? _user;
  PayRepository? _pay;
  UserProfile? profile;
  bool syncing = false;

  /// 하단 1차 메뉴. 기획 시안 v9의 `tabs`와 같다 — 홈 · 부업 · (부탁하기) · 채팅 · 내 정보.
  /// '진행 중'은 탭에서 빠지고 홈 배너·채팅 빈 화면에서 전체화면으로 열린다.
  String tab = 'home'; // home | benefits | chat | me
  String? toast;
  late final List<TaskItem> _seed;
  String scope = '서울 서초구';

  /// 부업·미션으로 받는 리워드 포인트(P). 로그인하면 서버 프로필 값으로 덮인다.
  /// 겸사페이(원)와는 완전히 다른 값이다 — 섞지 않는다.
  int points = 0;

  /// 겸사페이 원장. 잔액은 따로 저장하지 않고 이 기록을 더해서 만든다.
  List<PayEntry> payEntries = [];
  final int steps = 6430; // 걸음 수는 아직 센서를 붙이지 않은 체험값
  List<Coupon> coupons = [];
  List<String> doneMissions = [];
  final RewardLedger _rewards = RewardLedger();

  // 이 기기에 보관되는 사본 (LocalStore 참고)
  List<TaskItem> created = []; // 내가 올린 부탁, 최신순
  List<int> bookmarks = []; // 관심 저장
  Map<int, Trade> trades = {}; // 지원 내역과 거래 단계
  Map<int, List<Offer>> offers = {}; // 보낸 가격 제안

  /// 적립 원장에서 '완료한 미션'을 되살릴 때 쓰는 키 접두사.
  /// (earn의 key가 'mission:{id}' 형태다 — completeMission 참고)
  static const _missionKey = 'mission:';

  /// 서버에서 내려온 공개 부탁글
  List<TaskItem> _server = [];
  StreamSubscription<List<TaskItem>>? _requestSub;

  /// 셸 상태가 바뀔 때마다 올라가는 번호. 푸시된 화면(진행 중·관심 저장 등)이
  /// 이것을 듣고 다시 그려져서, 탭이 아니어도 포인트·관심 목록이 바로 반영된다.
  final ValueNotifier<int> _rev = ValueNotifier(0);

  /// 화면에 보여줄 부탁 전체. 같은 id면 서버 쪽이 최신이므로 서버를 먼저 둔다.
  ///
  /// 다만 서버에서 내려온 글에는 '내가 올렸다'는 표시가 없다(작성자 이름은 닉네임으로
  /// 바뀌어 있고, 로그아웃 상태면 uid로도 못 가린다). 이 기기에 같은 id의 사본이
  /// 있으면 내가 올린 글이 확실하므로, 그 표시만 서버 사본에 옮겨 붙인다.
  List<TaskItem> get items {
    final mineIds = {for (final it in created) it.id};
    final seen = <int>{};
    final out = <TaskItem>[];
    for (final it in [..._server, ...created, ..._seed]) {
      if (!seen.add(it.id)) continue;
      out.add(!it.mine && mineIds.contains(it.id) ? it.copyWith(mine: true) : it);
    }
    return out;
  }

  /// 취소하지 않은 지원 내역의 부탁 id
  List<int> get grabbed => [for (final e in trades.entries) if (e.value.status != 'cancelled') e.key];
  int get activeCount => trades.values.where((t) => t.isActive).length;
  int get completedCount => trades.values.where((t) => t.status == 'completed').length;

  /// 신규 첫 3거래 수수료 0%
  int get freeLeft => (freeTrades - completedCount).clamp(0, freeTrades);

  /// 겸사페이 잔액(원)
  int get payBalance => PayEntry.balanceOf(payEntries);

  /// 신뢰 레벨. 홈 지갑 카드와 내 정보 화면이 같은 값을 쓴다.
  TrustLevel get trust => TrustLevel.from(
        completed: stats.completed,
        helped: stats.helped,
        cancelled: stats.cancelled,
        verified: profile?.verified ?? false,
      );

  /// 완료 처리한 거래의 사례비 합계(원). 홈의 누적 수익 표시에 쓴다.
  int get earnedCash => items
      .where((i) => trades[i.id]?.status == 'completed' && (i.mode == 'ask' || i.mode == 'sea'))
      .fold(0, (sum, i) => sum + i.price);

  /// 이번 달 완료분만. 완료 시각은 거래 단계가 바뀐 시각으로 본다.
  int get monthEarnedCash {
    final now = DateTime.now();
    var sum = 0;
    for (final i in items) {
      final t = trades[i.id];
      if (t == null || t.status != 'completed') continue;
      if (i.mode != 'ask' && i.mode != 'sea') continue;
      if (t.updatedAt.year == now.year && t.updatedAt.month == now.month) sum += i.price;
    }
    return sum;
  }

  /// 내 정보 화면의 숫자. 전부 위의 기록에서 센 값이다.
  ProfileStats get stats {
    var helped = 0, completed = 0;
    for (final i in items) {
      final t = trades[i.id];
      if (t == null || t.status != 'completed') continue;
      completed++;
      if (!i.isMine) helped++;
    }
    return ProfileStats(
      helped: helped,
      requested: items.where((i) => i.isMine).length,
      completed: completed,
      active: activeCount,
      cancelled: trades.values.where((t) => t.status == 'cancelled').length,
      earnedCash: earnedCash,
      monthEarnedCash: monthEarnedCash,
      saved: bookmarks.length,
      applied: grabbed.length,
      coupons: coupons.where((c) => !c.used).length,
    );
  }

  /// 서버에 못 붙은 사유. null이면 정상.
  String? get serverIssue =>
      Backend.ready ? null : (Backend.error ?? '이 플랫폼에서는 Firebase 연결이 아직 지원되지 않아요.');

  bool get isLoggedIn => AuthService().currentUser != null;
  StreamSubscription<User?>? _authSub;

  ErrandActions get actions => ErrandActions(
        grabbed: grabbed, onGrab: grab, onOffer: sendOffer, offers: offers,
        isSaved: bookmarks.contains, toggleSave: toggleSave,
      );

  /// 콘텐츠 열람은 항상 허용하되, 실제 참여 행동(지원/제안/등록/적립/교환 등)만
  /// 로그인 여부로 막아 로그인 화면으로 유도함.
  Future<void> requireLogin(VoidCallback action) async {
    if (isLoggedIn) {
      action();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (!mounted || !isLoggedIn) return; // 로그인 안 하고 뒤로 나온 경우
    action();
  }

  @override
  void initState() {
    super.initState();
    _seed = _errandRepository.fetchSeedItems();
    _loadLocal();
    _requestSub = _requests.watchOpen().listen((list) {
      if (mounted) setState(() => _server = list);
    });
    _authSub = AuthService().authStateChanges.listen(_bindUser);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _requestSub?.cancel();
    _rev.dispose();
    super.dispose();
  }

  // ── 계정 연결 ───────────────────────────────────────────────────────────

  /// 로그인 상태가 바뀔 때마다 서버 자료를 붙이거나 뗀다.
  Future<void> _bindUser(User? user) async {
    if (!mounted) return;
    TaskItem.currentUid = user?.uid;

    if (user == null) {
      setState(() {
        _user = null;
        _pay = null;
        profile = null;
        syncing = false;
      });
      return;
    }

    final repo = UserRepository(user.uid);
    setState(() {
      _user = repo;
      _pay = PayRepository(user.uid);
      syncing = true;
    });

    // 이 기기에만 있던 기록을 처음 한 번 내 계정으로 옮긴다.
    if (!await repo.isMigrated()) await _migrateLocal(repo);
    if (!mounted) return;

    await _pullServer(repo, user);
    if (mounted) setState(() => syncing = false);
  }

  /// 첫 로그인 이관. 이 기기에 있던 부탁·관심·지원 내역·제안을 계정으로 올린다.
  /// 문서 id가 곧 부탁 id라 두 번 올려도 덮어쓰기지 복제가 아니지만,
  /// 쓸데없는 호출을 막기 위해 `migratedFromDevice` 표시를 남긴다.
  Future<void> _migrateLocal(UserRepository repo) async {
    for (final it in created) {
      await _requests.add(it.withOwner(repo.uid));
    }
    for (final id in bookmarks) {
      await repo.setBookmark(id, true);
    }
    for (final e in trades.entries) {
      await repo.saveTrade(e.key, e.value);
    }
    for (final e in offers.entries) {
      await repo.saveOffers(e.key, e.value);
    }
    final pay = PayRepository(repo.uid);
    for (final e in payEntries) {
      await pay.add(e);
    }
    await repo.markMigrated();
  }

  /// 서버 자료를 읽어 화면 상태에 채운다. 못 읽으면 로컬 값이 그대로 남는다.
  Future<void> _pullServer(UserRepository repo, User user) async {
    final loaded = await repo.ensureProfile(email: user.email ?? '', nickname: user.displayName);
    final serverBookmarks = await repo.loadBookmarks();
    final serverTrades = await repo.loadTrades();
    final serverOffers = await repo.loadOffers();
    final serverCoupons = await repo.loadCoupons();
    final serverLedger = await repo.loadLedger();
    final serverPay = await PayRepository(repo.uid).load();
    if (!mounted) return;

    setState(() {
      profile = loaded;
      if (loaded != null) points = loaded.points;
      if (serverBookmarks.isNotEmpty) bookmarks = serverBookmarks;
      if (serverTrades.isNotEmpty) trades = serverTrades;
      if (serverOffers.isNotEmpty) offers = serverOffers;
      if (serverCoupons.isNotEmpty) coupons = serverCoupons;
      if (serverPay.isNotEmpty) payEntries = serverPay;
      if (serverLedger.isNotEmpty) {
        _rewards.restore(serverLedger);
        // 완료한 미션 목록은 따로 저장하지 않고 원장에서 되살린다.
        // 적립 기록이 곧 완료 기록이라, 두 곳에 두면 어긋날 일이 없다.
        doneMissions = [
          for (final k in serverLedger.keys)
            if (k.startsWith(_missionKey)) k.substring(_missionKey.length),
        ];
      }
    });
    // 서버 값을 이 기기 사본에도 반영해 둔다 (다음 실행이 오프라인일 수 있으므로)
    _saveBookmarks();
    _saveTrades();
    _saveOffers();
    _saveLedger();
    _saveMissions();
    _savePay();
  }

  // ── 이 기기 사본 ────────────────────────────────────────────────────────

  void _loadLocal() {
    created = [for (final j in LocalStore.read<List<dynamic>>('requests', const [])) ?TaskItem.fromJson(j)];
    bookmarks = LocalStore.read<List<dynamic>>('bookmarks', const []).whereType<int>().toList();
    trades = {
      for (final e in LocalStore.read<Map<String, dynamic>>('trades', const {}).entries)
        if (int.tryParse(e.key) != null && Trade.fromJson(e.value) != null) int.parse(e.key): Trade.fromJson(e.value)!,
    };
    offers = {
      for (final e in LocalStore.read<Map<String, dynamic>>('offers', const {}).entries)
        if (int.tryParse(e.key) != null && e.value is List)
          int.parse(e.key): [
            for (final o in e.value as List)
              if (o is Map && o['price'] is int) Offer(o['price'] as int, o['msg'] is String ? o['msg'] as String : ''),
          ],
    };
    // 적립 원장이 메모리에만 있으면 앱을 껐다 켤 때마다 출석 보상을 다시 받을 수 있다.
    _rewards.restore({
      for (final e in LocalStore.read<Map<String, dynamic>>('ledger', const {}).entries)
        if (e.value is String) e.key: e.value as String,
    });
    doneMissions = LocalStore.read<List<dynamic>>('missions', const []).whereType<String>().toList();
    payEntries = [for (final j in LocalStore.read<List<dynamic>>('payEntries', const [])) ?PayEntry.fromJson(j)];
  }

  void _saveRequests() => LocalStore.write('requests', [for (final it in created) it.toJson()]);
  void _saveBookmarks() => LocalStore.write('bookmarks', bookmarks);
  void _saveTrades() => LocalStore.write('trades', {for (final e in trades.entries) '${e.key}': e.value.toJson()});
  void _saveOffers() => LocalStore.write('offers', {
        for (final e in offers.entries) '${e.key}': [for (final o in e.value) {'price': o.price, 'msg': o.msg}],
      });
  void _saveLedger() => LocalStore.write('ledger', _rewards.entries);
  void _saveMissions() => LocalStore.write('missions', doneMissions);
  void _savePay() => LocalStore.write('payEntries', [for (final e in payEntries) e.toJson()]);

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _rev.value++;
  }

  void flash(String m) {
    setState(() => toast = m);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && toast == m) setState(() => toast = null);
    });
  }

  // ── 포인트·쿠폰 ─────────────────────────────────────────────────────────

  bool isClaimed(String key, {bool daily = true}) => _rewards.isClaimed(key, daily: daily);

  /// 달력에 찍힌 출석 이력. 원장에 하루 한 칸씩 쌓인 기록에서 만든다.
  Attendance get attendance => Attendance.fromLedger(_rewards.entries);

  /// 오늘 출석 도장. 연속·월 누적 보너스까지 한 번에 받는다.
  Future<void> checkIn() {
    final today = attendance;
    if (today.attendedToday) {
      flash('오늘은 이미 받았어요');
      return Future.value();
    }
    return earn(today.todayReward, '출석 적립', key: Attendance.keyFor(today.today), daily: false);
  }

  /// [key]가 같은 보상은 한 번만 지급된다. [daily]가 true면 한국 시간 기준
  /// 하루에 한 번, false면 계정당 한 번.
  Future<void> earn(int amt, String label, {required String key, bool daily = true}) => requireLogin(() {
        final mark = _rewards.claimValue(key, daily: daily);
        if (mark == null) {
          flash(daily ? '오늘은 이미 받았어요' : '이미 받은 적립이에요');
          return;
        }
        setState(() => points += amt);
        _saveLedger();
        _user?.saveLedgerEntry(key, mark, amt, label);
        _user?.savePoints(points);
        flash('+${amt}P 적립됐어요 · $label');
      });

  void redeem(RewardProduct p) => requireLogin(() {
        if (points < p.points) {
          flash('보유 포인트가 부족해요');
          return;
        }
        final coupon = Coupon(
          id: DateTime.now().millisecondsSinceEpoch,
          brandK: p.brand, name: p.name, points: p.points, exp: '2026.12.31', code: genCode(),
        );
        setState(() {
          points -= p.points;
          coupons = [coupon, ...coupons];
        });
        _user?.saveCoupon(coupon);
        _user?.savePoints(points);
      });

  void useCoupon(int id) => requireLogin(() {
        Coupon? changed;
        final next = <Coupon>[];
        for (final c in coupons) {
          if (c.id == id) {
            changed = c.copyWith(used: true);
            next.add(changed);
          } else {
            next.add(c);
          }
        }
        setState(() => coupons = next);
        final saved = changed;
        if (saved != null) _user?.saveCoupon(saved);
      });

  void completeMission(PartnerMission m) => requireLogin(() {
        if (doneMissions.contains(m.id)) return;
        setState(() => doneMissions = [...doneMissions, m.id]);
        _saveMissions();
        earn(m.points, m.title, key: '$_missionKey${m.id}', daily: false);
      });

  // ── 이동 ────────────────────────────────────────────────────────────────

  /// 혜택·미션은 하단 '부업' 탭이 1차 메뉴다.
  void goPointsHub() => _switchTab('benefits');

  /// 진행 중인 부탁. v9처럼 탭이 아니라 홈 배너·채팅에서 여는 전체화면이다.
  void goActivity() => _pushLive(() => ScreenFrame(
        title: '진행 중인 부탁',
        subtitle: '현재 상태와 다음 할 일을 확인하세요',
        onBack: () => Navigator.of(context).pop(),
        child: ActivityView(
          items: items,
          trades: trades,
          updateTrade: updateTrade,
          openDetail: (it) => actions.open(context, it),
          showHeader: false,
        ),
      ));

  /// 셸 상태가 바뀌면 다시 그려지는 전체화면을 띄운다.
  void _pushLive(Widget Function() build) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ListenableBuilder(listenable: _rev, builder: (_, _) => build())));
  }

  void _openFilteredList(String title, bool Function(TaskItem) filter) => _pushLive(() => ListScreen(
        config: ScreenRoute(name: 'list', title: title, sortable: true, filter: filter),
        items: items, scope: scope, actions: actions,
      ));

  // ── 참여 행동 ───────────────────────────────────────────────────────────

  void toggleSave(int id) {
    final saved = bookmarks.contains(id);
    setState(() => bookmarks = saved ? bookmarks.where((x) => x != id).toList() : [...bookmarks, id]);
    _saveBookmarks();
    _user?.setBookmark(id, !saved);
    flash(saved ? '관심 저장을 해제했어요' : '관심 저장했어요 · 내 정보에서 볼 수 있어요');
  }

  /// 지원하기 → "요청자 확인 대기"로 저장하고 진행 중 화면으로 이동.
  /// 요청자에게 실제 알림이 가지는 않는다 (알림·수락 연동 전).
  void grab(TaskItem it) => requireLogin(() {
        if (it.isMine || it.isExpired) {
          flash(it.isMine ? '내가 올린 부탁에는 지원할 수 없어요' : '마감된 부탁이에요');
          return;
        }
        final cur = trades[it.id];
        if (cur != null && cur.status != 'cancelled') return;
        final trade = Trade.pending();
        Navigator.of(context).popUntil((r) => r.isFirst);
        setState(() {
          trades = {...trades, it.id: trade};
          tab = 'home';
        });
        _saveTrades();
        _user?.saveTrade(it.id, trade, title: it.title, price: it.price, mode: it.mode);
        flash(it.mode == 'together' ? '신청했어요 · 진행 중에서 확인하세요' : '지원했어요 · 요청자 응답 연동은 준비 중이에요');
        goActivity();
      });

  void updateTrade(int id, String action) {
    final cur = trades[id];
    if (cur == null) return;
    final next = cur.advance(action);
    if (identical(next, cur)) return; // 허용되지 않는 단계 이동
    setState(() => trades = {...trades, id: next});
    _saveTrades();
    _user?.saveTrade(id, next);

    // 완료된 순간에만 사례비를 겸사페이 원장에 한 줄 남긴다.
    // (내가 올린 부탁은 내가 받는 돈이 아니다)
    if (cur.status != 'completed' && next.status == 'completed') {
      for (final it in items) {
        if (it.id != id) continue;
        if (!it.isMine && it.price > 0) _addPay(PayKind.earn, it.price, it.title, requestId: it.id);
        break;
      }
    }
  }

  /// 겸사페이 원장에 한 줄 추가한다. 잔액은 따로 저장하지 않고 이 기록의 합이다.
  void _addPay(PayKind kind, int amount, String label, {int? requestId}) {
    final entry = PayEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      kind: kind,
      amount: amount,
      label: label,
      at: DateTime.now(),
      requestId: requestId,
    );
    setState(() => payEntries = [entry, ...payEntries]);
    _savePay();
    _pay?.add(entry);
  }

  void goPay() => _pushLive(() => PayScreen(
        entries: payEntries,
        flash: flash,
        onCharge: payCharge,
        onWithdraw: payWithdraw,
      ));

  /// 개발용 충전. 실제 이체가 아니라 원장에 줄만 쌓는다.
  /// 릴리스 빌드에서는 [PayConfig.debugTopUp]이 false라 화면에서 여기까지 오지 않지만,
  /// 저장소를 건드리는 쪽에서도 한 번 더 막는다.
  void payCharge(int amount) {
    if (!PayConfig.debugTopUp || amount <= 0) return;
    _addPay(PayKind.charge, amount, PayConfig.chargeLabel);
    flash('${nf(amount)}원을 넣었어요 · 실제 이체가 아니에요');
  }

  /// 개발용 출금. 잔액보다 많이 뺄 수 없다.
  void payWithdraw(int amount) {
    if (!PayConfig.debugTopUp || amount <= 0) return;
    if (amount > payBalance) {
      flash('잔액보다 많이 출금할 수 없어요');
      return;
    }
    _addPay(PayKind.withdraw, -amount, PayConfig.withdrawLabel);
    flash('${nf(amount)}원을 뺐어요 · 실제 이체가 아니에요');
  }
  void goProfile() => _switchTab('me');

  void sendOffer(TaskItem it, int price, String msg) => requireLogin(() {
        final min = it.mode == 'sea' ? seaMin : 1000;
        if (price < min) {
          flash('제안 금액은 ${won(min)} 이상이어야 해요');
          return;
        }
        final list = [...?offers[it.id], Offer(price, msg)];
        setState(() => offers = {...offers, it.id: list});
        _saveOffers();
        _user?.saveOffers(it.id, list);
        flash('가격 제안을 보냈어요. 요청자에게만 보여요');
      });

  void addRequest(NewRequestData data) {
    final uid = AuthService().currentUser?.uid;
    final it = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch,
      mode: data.mode,
      cat: data.cat,
      title: data.title,
      desc: data.desc,
      place: data.place.isEmpty ? null : data.place,
      cc: data.cc,
      city: data.city,
      country: data.country,
      region: data.mode == 'sea' ? null : (scope == '전국' ? '우리 동네' : scope),
      // 새 부탁은 실제 거리를 알 수 없어 임의의 거리를 붙이지 않는다
      distM: data.mode == 'sea' ? 9e9 : null,
      mins: data.mode == 'sea' ? 0 : data.mins,
      price: data.price,
      who: profile?.nickname ?? '나',
      // 내가 방금 올린 글에 별점 5.0 / 본인인증 완료를 자동으로 붙이면 안 된다.
      rating: 0, reviews: 0, deals: 0, resp: 0, verified: false,
      hot: data.hot,
      deadline: data.deadline, deliveryPlace: data.deliveryPlace, budget: data.budget,
      payment: data.payment, completion: data.completion,
      // '부탁하기'로 올린 진짜 부탁. 예시 데이터와 구분해 목록 맨 위에 올린다.
      sample: false,
      ownerUid: uid,
      // 로그인이 풀리거나 서버가 없어도 내 글임을 알 수 있게 표시를 남긴다.
      mine: true,
    );
    setState(() {
      created = [it, ...created];
      tab = 'home';
    });
    _saveRequests();
    if (uid != null) _requests.add(it);
    flash(uid == null
        ? '부탁을 올렸어요 · 로그인하면 계정에 저장돼요'
        : (it.hot ? '급해요로 목록 맨 위에 올렸어요' : '부탁을 올렸어요'));
  }

  /// 부탁 등록 폼. [kind]는 ask(일상 부탁) | sea(해외 사다주기).
  void _openRequestForm(String kind) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostRequest(scope: scope, onSubmit: addRequest, initialKind: kind)),
      );

  /// 단기알바 모집 등록. 일상 부탁과 달리 근로 조건을 받는 별도 폼이다.
  void openJobPost() => requireLogin(() {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobPostScreen(
            scope: scope,
            onSubmit: (job) => flash('단기알바를 등록했어요 · 이 기기에 저장돼요'),
          )),
        );
      });

  /// '부탁하기' — 일상 부탁 · 해외 사다주기 · 단기알바 모집 갈래부터 고른다.
  void openPost() => requireLogin(() {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateChoiceScreen(
            onLocal: () => _openRequestForm('ask'),
            onOverseas: () => _openRequestForm('sea'),
            onJob: openJobPost,
          )),
        );
      });

  /// 닉네임 변경. 계정(표시 이름)과 프로필 문서를 같이 맞춘다.
  Future<void> renameNickname(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || profile == null) return;
    setState(() => profile = profile!.copyWith(nickname: trimmed));
    _user?.saveProfileFields(nickname: trimmed);
    try {
      await AuthService().updateDisplayName(trimmed);
    } catch (e) {
      debugPrint('표시 이름 변경 실패: $e');
    }
    flash('닉네임을 바꿨어요');
  }

  Future<void> openRegion() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegionSheet(scope: scope),
    );
    if (picked != null) {
      setState(() => scope = picked);
      _user?.saveProfileFields(region: picked);
    }
  }

  // ── 화면 ────────────────────────────────────────────────────────────────

  Widget _body() {
    switch (tab) {
      case 'benefits':
        return SideJobView(
          points: points, steps: steps, coupons: coupons, items: items, scope: scope, actions: actions,
          monthEarn: monthEarnedCash, monthPoints: 0, freeLeft: freeLeft, doneMissions: doneMissions,
          earn: earn, isClaimed: isClaimed, redeem: redeem, useCoupon: useCoupon,
          completeMission: completeMission, goPointsHub: goPointsHub, flash: flash,
        );
      case 'chat':
        return ChatView(onGoActivity: goActivity);
      case 'me':
        return MeView(
          profile: profile,
          stats: stats,
          coupons: coupons,
          useCoupon: useCoupon,
          goPointsHub: goPointsHub,
          freeLeft: freeLeft,
          isLoggedIn: isLoggedIn,
          onLogin: () => requireLogin(() {}),
          onOpenSaved: () => _pushLive(() => SavedScreen(items: items, bookmarks: bookmarks, actions: actions)),
          onOpenApplied: () => _openFilteredList('지원한 부탁', (i) => grabbed.contains(i.id)),
          onOpenMine: () => _openFilteredList('내가 올린 부탁', (i) => i.isMine),
          onOpenActivity: goActivity,
          onRename: renameNickname,
          serverIssue: serverIssue,
          syncing: syncing,
        );
      default:
        return HomeContent(
          items: items, scope: scope, actions: actions, points: points, steps: steps,
          payBalance: payBalance, trust: trust, goPay: goPay, goProfile: goProfile,
          coupons: coupons, doneMissions: doneMissions,
          openRegion: openRegion,
          earn: earn, isClaimed: isClaimed, redeem: redeem, useCoupon: useCoupon, completeMission: completeMission,
          flash: flash, goPointsHub: goPointsHub,
          activeCount: activeCount, goActivity: goActivity,
          attendance: attendance, checkIn: checkIn, openJobPost: openJobPost,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 탭은 Navigator 라우트가 아니라 상태값이라, 그대로 두면 홈이 아닌 탭에서
    // 시스템 뒤로가기를 눌렀을 때 앱이 그냥 종료된다. 홈이 아닌 탭에서는
    // 뒤로가기를 홈 탭 복귀로 소비하고, 홈에서만 종료되게 한다.
    return PopScope(
      canPop: tab == 'home',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => tab = 'home');
      },
      child: Scaffold(
        backgroundColor: AppColors.card,
        body: SafeArea(
          child: Stack(
            children: [
              Column(children: [Expanded(child: _body()), _bottomNav()]),
              if (toast != null)
                Positioned(
                  left: 18, right: 18, bottom: 98,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: const Color(0xF5252629),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: const [BoxShadow(color: Color(0x1A202A42), blurRadius: 25, offset: Offset(0, 7))],
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_rounded, size: 18, color: Color(0xFFE7D58E)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(toast!, style: AppType.meta.copyWith(color: Colors.white, height: 1.5))),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchTab(String k) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => tab = k);
  }

  /// 하단 1차 메뉴 (.main-nav). 가운데 '부탁하기'만 노란 사각 버튼이다.
  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: Color(0xFFF0F1F3))),
      ),
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
      child: Row(children: [
        _navBtn('home', '홈', 'home'),
        _navBtn('benefits', '부업', 'gift'),
        Expanded(
          child: InkWell(
            onTap: openPost,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  height: 26,
                  child: Container(
                    width: 27,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.createYellow, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded, size: 21, color: AppColors.ink),
                  ),
                ),
                const SizedBox(height: 5),
                Text('부탁하기', style: AppType.caption.copyWith(fontSize: 12, fontWeight: AppType.w500, color: AppColors.navActive)),
              ]),
            ),
          ),
        ),
        _navBtn('chat', '채팅', 'chat'),
        _navBtn('me', '내 정보', 'user'),
      ]),
    );
  }

  Widget _navBtn(String k, String label, String icon) {
    final active = tab == k;
    final color = active ? AppColors.navActive : AppColors.navIdle;
    return Expanded(
      child: InkWell(
        onTap: () => _switchTab(k),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 26,
                child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                  Icon(AppIcon.data(icon), size: 23, color: color),
                  if (active)
                    const Positioned(
                      bottom: -3,
                      child: SizedBox(
                        width: 3, height: 3,
                        child: DecoratedBox(decoration: BoxDecoration(color: AppColors.navActive, shape: BoxShape.circle)),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: AppType.caption.copyWith(
                  fontSize: 12,
                  fontWeight: active ? AppType.w700 : AppType.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
