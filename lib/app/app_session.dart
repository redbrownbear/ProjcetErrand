import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/backend/backend.dart';
import '../core/backend/server_api.dart';
import '../core/backend/user_repository.dart';
import '../core/utils/formatters.dart';
import '../features/auth/services/auth_service.dart';
import '../features/benefits/data/point_rules.dart';
import '../features/benefits/models/attendance.dart';
import '../features/benefits/models/coupon.dart';
import '../features/benefits/models/partner_mission.dart';
import '../features/benefits/models/reward_ledger.dart';
import '../features/benefits/models/reward_product.dart';
import '../features/benefits/services/mission_tracker.dart';
import '../features/errand/models/application.dart';
import '../features/errand/models/new_request_data.dart';
import '../features/errand/models/offer.dart';
import '../features/errand/models/task_item.dart';
import '../features/errand/models/trade.dart';
import '../features/lucky/models/tickets.dart';
import '../features/market/models/used_item.dart';
import '../features/errand/repositories/errand_repository.dart';
import '../features/errand/repositories/request_repository.dart';
import '../features/errand/repositories/trade_repository.dart';
import '../features/pay/models/pay_entry.dart';
import '../features/pay/pay_config.dart';
import '../features/pay/repositories/pay_repository.dart';
import '../features/profile/models/trust_level.dart';
import '../features/profile/models/user_profile.dart';
import 'session_store.dart';

/// 앱이 들고 있는 내 자료와, 그 자료를 바꾸는 행동.
///
/// 저장 위치는 두 군데다.
/// - **서버**(`Backend.ready` && 로그인): `users/{uid}` 아래의 내 자료와 공개 `requests`
/// - **이 기기**([SessionStore]): 위가 안 될 때의 보관소이자, 서버가 있을 때의 오프라인 사본
///
/// 모든 변경은 메모리 → 이 기기 → 서버 순으로 흐른다. 서버 쓰기는 실패해도 화면을 막지 않는다
/// ([Backend.push]). 서버가 살아 있으면 다음 로그인 때 다시 맞춰진다.
///
/// 화면 전환과 로그인 확인은 여기서 하지 않는다 — 그건 [HomeShell]의 일이다.
/// 값이 바뀌면 [notifyListeners]로 알리고, 사용자에게 알릴 말은 [toast]에 싣는다.
class AppSession extends ChangeNotifier {
  final ErrandRepository _errands = LocalErrandRepository();
  final RequestRepository _requests = const RequestRepository();
  final SessionStore _store = const SessionStore();

  /// 로그인한 사용자의 서버 저장소. 로그아웃 상태면 null.
  UserRepository? _user;
  PayRepository? _pay;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<TaskItem>>? _requestSub;
  bool _disposed = false;

  /// 서버 자료를 다 붙인 계정의 uid. [accountReady]가 이 값을 기다린다.
  String? _boundUid;
  final List<Completer<void>> _boundWaiters = [];

  UserProfile? profile;
  bool syncing = false;
  String scope = '서울 서초구';

  /// 화면 아래에 잠깐 띄우는 안내 문구
  String? toast;

  /// 응모권을 줄 일이 생겼을 때 (v77 럭키드로우). 셸이 응모권 지갑에 잇는다.
  /// 응모권은 포인트·겸사페이와 섞지 않으므로 여기서는 '무슨 일이 있었는지'만 알린다.
  void Function(TicketRule rule, {int? n})? onTicket;

  /// 리워드 포인트(P). 겸사페이(원)와는 다른 값이라 섞지 않는다.
  int points = 0;

  /// 겸사페이 원장. 잔액은 따로 저장하지 않고 이 기록을 더해서 만든다.
  List<PayEntry> payEntries = [];

  /// 걸음 수. 아직 센서를 붙이지 않은 체험값이다.
  final int steps = 6430;
  List<Coupon> coupons = [];
  List<String> doneMissions = [];
  final RewardLedger _rewards = RewardLedger();

  /// 내가 올린 부탁 (최신순)
  List<TaskItem> created = [];
  List<int> bookmarks = [];

  /// 지원 내역과 거래 단계 (부탁 id → 단계). 로그인 + 서버 연결 상태면 서버의 지원·거래 문서에서 만든다.
  /// 내가 요청자인 부탁도 거래가 시작되면 여기 들어온다.
  Map<int, Trade> trades = {};

  /// 내 부탁에 들어와 답을 기다리는 지원 (요청자 쪽 '받은 지원')
  List<Application> received = [];

  /// 부탁 id → 서버 거래 문서 id. 단계를 진행할 때 쓴다.
  final Map<int, String> _tradeIds = {};
  final List<StreamSubscription<Object?>> _tradeSubs = [];
  List<Application> _myApps = [];
  List<Application> _received = [];
  List<ServerTrade> _helperTrades = [];
  List<ServerTrade> _requesterTrades = [];

  /// 모집이 끝나 공개 목록(open)에서 빠졌지만 내 지원·거래와 이어진 부탁
  final Map<int, TaskItem> _related = {};
  final Set<int> _relatedLoading = {};

  /// 보낸 가격 제안
  Map<int, List<Offer>> offers = {};

  List<TaskItem> _seed = const [];

  /// 서버에서 내려온 공개 부탁글
  List<TaskItem> _server = [];

  /// 적립 원장에서 '완료한 미션'을 되살릴 때 쓰는 키 접두사
  static const _missionKey = 'mission:';

  // ── 시작·종료 ───────────────────────────────────────────────────────────

  void start() {
    _seed = _errands.fetchSeedItems();
    created = _store.loadRequests();
    bookmarks = _store.loadBookmarks();
    trades = _store.loadTrades();
    offers = _store.loadOffers();
    // 적립 원장이 메모리에만 있으면 앱을 껐다 켤 때마다 출석 보상을 다시 받을 수 있다.
    _rewards.restore(_store.loadLedger());
    doneMissions = _store.loadMissions();
    payEntries = _store.loadPay();
    points = _store.loadPoints();
    coupons = _store.loadCoupons();

    _requestSub = _requests.watchOpen().listen((list) => _update(() => _server = list));
    _authSub = AuthService().authStateChanges.listen(_bindUser);
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    _requestSub?.cancel();
    _stopTradeWatch();
    super.dispose();
  }

  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  void flash(String message) {
    _update(() => toast = message);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (toast == message) _update(() => toast = null);
    });
  }

  // ── 읽기 전용 값 ────────────────────────────────────────────────────────

  /// 화면에 보여 줄 부탁 전체. 같은 id면 서버 쪽이 최신이라 서버를 먼저 둔다.
  ///
  /// 서버에서 내려온 글에는 '내가 올렸다'는 표시가 없다(로그아웃 상태면 uid로도 못 가린다).
  /// 이 기기에 같은 id의 사본이 있으면 내 글이 확실하므로 그 표시만 옮겨 붙인다.
  List<TaskItem> get items {
    final mineIds = {for (final it in created) it.id};
    final seen = <int>{};
    final out = <TaskItem>[];
    // 내 글은 이 기기 사본이 먼저다. 공개 문서에는 정확한 장소가 없어서(보안 규칙 v2) 서버 쪽을 쓰면 장소가 비어 보인다.
    for (final it in [...created, ..._server, ..._related.values, ..._seed]) {
      if (!seen.add(it.id)) continue;
      out.add(!it.mine && mineIds.contains(it.id) ? it.copyWith(mine: true) : it);
    }
    return out;
  }

  bool get isLoggedIn => AuthService().currentUser != null;

  /// 지원·거래를 서버로 처리할 수 있는 상태인가 (서버 연결 + 로그인)
  bool get _serverMode => Backend.ready && _user != null;

  /// 서버에 못 붙은 사유. null이면 정상.
  String? get serverIssue => Backend.ready ? null : (Backend.error ?? '이 플랫폼에서는 Firebase 연결이 아직 지원되지 않아요.');

  /// 취소하지 않은 지원 내역의 부탁 id
  List<int> get grabbed => [
    for (final e in trades.entries)
      if (e.value.status != 'cancelled') e.key,
  ];
  int get activeCount => trades.values.where((t) => t.isActive).length;
  int get completedCount => trades.values.where((t) => t.status == 'completed').length;

  /// 신규 첫 3거래 수수료 0%
  int get freeLeft => (freeTrades - completedCount).clamp(0, freeTrades);

  /// 겸사페이 잔액(원)
  int get payBalance => PayEntry.balanceOf(payEntries);

  TrustLevel get trust => TrustLevel.from(
    completed: stats.completed,
    helped: stats.helped,
    cancelled: stats.cancelled,
    verified: profile?.verified ?? false,
  );

  Iterable<TaskItem> get _completedPaid =>
      items.where((i) => trades[i.id]?.status == 'completed' && (i.mode == 'ask' || i.mode == 'sea'));

  /// 완료한 거래의 사례비 합계(원)
  int get earnedCash => _completedPaid.fold(0, (sum, i) => sum + i.price);

  /// 이번 달 완료분만. 완료 시각은 거래 단계가 바뀐 시각으로 본다.
  int get monthEarnedCash {
    final now = DateTime.now();
    return _completedPaid
        .where((i) {
          final at = trades[i.id]!.updatedAt;
          return at.year == now.year && at.month == now.month;
        })
        .fold(0, (sum, i) => sum + i.price);
  }

  /// 마이 화면의 숫자. 전부 위의 기록에서 센 값이다.
  ProfileStats get stats {
    var helped = 0, completed = 0;
    for (final i in items) {
      if (trades[i.id]?.status != 'completed') continue;
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

  bool isClaimed(String key, {bool daily = true}) => _rewards.isClaimed(key, daily: daily);

  /// 출석 이력. 원장에 하루 한 칸씩 쌓인 기록에서 만든다.
  Attendance get attendance => Attendance.fromLedger(_rewards.entries);

  // ── 계정 연결 ───────────────────────────────────────────────────────────

  /// 로그인한 계정의 서버 자료를 다 붙일 때까지 기다린다. 로그아웃 상태면 바로 끝난다.
  ///
  /// 로그인 직후 바로 적립·교환을 하면, 뒤이어 도착한 서버 값이 방금 바꾼 포인트를 덮어쓴다.
  /// 그래서 참여 행동은 이걸 기다린 뒤에 한다 ([HomeShell.requireLogin]).
  /// 서버가 끝내 응답하지 않으면 제한 시간 뒤에 그냥 넘어간다.
  Future<void> accountReady() {
    final uid = AuthService().currentUser?.uid;
    if (uid == null || uid == _boundUid) return Future.value();
    final waiter = Completer<void>();
    _boundWaiters.add(waiter);
    return waiter.future.timeout(Backend.timeout * 2, onTimeout: () {});
  }

  void _markBound(String? uid) {
    _boundUid = uid;
    for (final w in _boundWaiters) {
      if (!w.isCompleted) w.complete();
    }
    _boundWaiters.clear();
  }

  /// 기다리는 사이에 로그아웃하거나 다른 계정으로 바뀌지 않았는지
  bool _stillBound(User user) => !_disposed && AuthService().currentUser?.uid == user.uid;

  /// 로그인 상태가 바뀔 때마다 서버 자료를 붙이거나 뗀다.
  Future<void> _bindUser(User? user) async {
    if (_disposed) return;
    TaskItem.currentUid = user?.uid;
    final owner = _store.loadOwner();

    if (user == null) {
      // 서버에 붙은 채로 로그아웃 상태라면, 남아 있는 계정 사본은 앞사람 것이다.
      // 서버에 못 붙어서 로그인 여부를 모르는 경우(오프라인 실행)는 그 사본이 유일한 자료라 남긴다.
      if (Backend.ready && owner != null) _resetAccount();
      _stopTradeWatch();
      _update(() {
        _user = null;
        _pay = null;
        profile = null;
        syncing = false;
      });
      _markBound(null);
      return;
    }

    // 다른 계정의 사본이 남아 있으면 지운다. 안 지우면 그 자료가 새 계정 화면에 섞인다.
    if (owner != null && owner != user.uid) _resetAccount();

    final repo = UserRepository(user.uid);
    _update(() {
      _user = repo;
      _pay = PayRepository(user.uid);
      syncing = true;
    });

    // 계정으로 올리는 건 로그아웃 상태에서 쌓인 사본뿐이다.
    if (owner == null && !await repo.isMigrated()) await _migrateLocal(repo);
    if (!_stillBound(user)) return;
    _store.saveOwner(user.uid);

    await _pullServer(repo, user);
    if (!_stillBound(user)) return;
    _watchTrades(user.uid);
    _update(() => syncing = false);
    _markBound(user.uid);
  }

  /// 계정 자료를 메모리와 이 기기 사본에서 비운다. 원본은 서버에 있다.
  void _resetAccount() {
    _store.clearAccount();
    _store.saveOwner(null);
    _update(() {
      created = [];
      bookmarks = [];
      trades = {};
      received = [];
      offers = {};
      _rewards.restore(const {});
      doneMissions = [];
      payEntries = [];
      points = 0;
      coupons = [];
    });
  }

  /// 첫 로그인 이관. 이 기기에 있던 부탁·관심을 계정으로 한 번 올린다.
  /// 문서 id가 곧 부탁 id라 두 번 올려도 덮어쓰기지만, 쓸데없는 호출을 막으려고 표시를 남긴다.
  ///
  /// 지원 내역·제안·겸사페이 기록은 올리지 않는다. 지원·거래는 서버 함수만 만들 수 있고(보안 규칙 v2),
  /// 로그아웃 상태에서 쌓인 기록은 상대방이 없는 체험 기록이라 옮길 대상이 아니다(1차_백엔드_설계.md 결정 4).
  Future<void> _migrateLocal(UserRepository repo) async {
    for (final it in created) {
      await _requests.add(it.withOwner(repo.uid));
    }
    for (final id in bookmarks) {
      await repo.setBookmark(id, true);
    }
    await repo.markMigrated();
  }

  /// 서버 자료를 읽어 채운다. 못 읽으면 이 기기의 값이 그대로 남는다.
  Future<void> _pullServer(UserRepository repo, User user) async {
    final loaded = await repo.ensureProfile(email: user.email ?? '', nickname: user.displayName);
    final serverBookmarks = await repo.loadBookmarks();
    final serverCoupons = await repo.loadCoupons();
    final serverLedger = await repo.loadLedger();
    final serverPay = await PayRepository(repo.uid).load();
    if (!_stillBound(user)) return;

    _update(() {
      profile = loaded;
      if (loaded != null) points = loaded.points;
      // 계정에 저장해 둔 활동 지역이 있으면 그 동네로 연다
      final region = loaded?.region;
      if (region != null && region.isNotEmpty) scope = region;
      if (serverBookmarks.isNotEmpty) bookmarks = serverBookmarks;
      if (serverCoupons.isNotEmpty) coupons = serverCoupons;
      if (serverPay.isNotEmpty) payEntries = serverPay;
      if (serverLedger.isNotEmpty) {
        _rewards.restore(serverLedger);
        // 완료한 미션은 따로 저장하지 않고 원장에서 되살린다. 적립 기록이 곧 완료 기록이다.
        doneMissions = [
          for (final k in serverLedger.keys)
            if (k.startsWith(_missionKey)) k.substring(_missionKey.length),
        ];
      }
    });

    // 다음 실행이 오프라인일 수 있으므로 서버 값을 이 기기에도 남긴다.
    _store.saveBookmarks(bookmarks);
    _store.saveLedger(_rewards.entries);
    _store.saveMissions(doneMissions);
    _store.savePay(payEntries);
    _store.savePoints(points);
    _store.saveCoupons(coupons);
  }

  // ── 포인트·쿠폰 ─────────────────────────────────────────────────────────

  /// [key]가 같은 보상은 한 번만 지급된다. [daily]면 한국 시간 기준 하루에 한 번, 아니면 계정당 한 번.
  void earn(int amount, String label, {required String key, bool daily = true}) {
    final mark = _rewards.claimValue(key, daily: daily);
    if (mark == null) {
      flash(daily ? '오늘은 이미 받았어요' : '이미 받은 적립이에요');
      return;
    }
    _update(() => points += amount);
    _store.saveLedger(_rewards.entries);
    _store.savePoints(points);
    _user?.saveLedgerEntry(key, mark, amount, label);
    _user?.savePoints(points);
    flash('+${amount}P 적립됐어요 · $label');
  }

  /// 오늘 출석 도장. 연속·월 누적 보너스까지 한 번에 받는다.
  void checkIn() {
    final today = attendance;
    if (today.attendedToday) {
      flash('오늘은 이미 받았어요');
      return;
    }
    earn(today.todayReward, '출석 적립', key: Attendance.keyFor(today.today), daily: false);
    if (attendance.attendedToday) onTicket?.call(TicketRules.attend);
  }

  /// 상품 교환. 교환됐으면 true.
  bool redeem(RewardProduct p) {
    if (points < p.points) {
      flash('보유 포인트가 부족해요');
      return false;
    }
    final now = DateTime.now();
    final coupon = Coupon(
      id: now.millisecondsSinceEpoch,
      brandK: p.brand,
      name: p.name,
      points: p.points,
      // 예전엔 '2026.12.31'로 박혀 있어서 해가 바뀌면 이미 지난 쿠폰이 발급됐다
      exp: Coupon.expiryFrom(now),
      code: genCode(),
    );
    _update(() {
      points -= p.points;
      coupons = [coupon, ...coupons];
    });
    _store.savePoints(points);
    _store.saveCoupons(coupons);
    _user?.saveCoupon(coupon, isNew: true);
    _user?.savePoints(points);
    return true;
  }

  void useCoupon(int id) {
    final index = coupons.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final used = coupons[index].copyWith(used: true);
    _update(() => coupons = [...coupons]..[index] = used);
    _store.saveCoupons(coupons);
    _user?.saveCoupon(used);
  }

  void completeMission(PartnerMission m) {
    if (doneMissions.contains(m.id)) return;
    _update(() => doneMissions = [...doneMissions, m.id]);
    _store.saveMissions(doneMissions);
    earn(m.points, m.title, key: '$_missionKey${m.id}', daily: false);
    onTicket?.call(missionTicketRule(m.cat), n: missionTickets(m.cat));
  }

  // ── 부탁 ────────────────────────────────────────────────────────────────

  void toggleSave(int id) {
    final saved = bookmarks.contains(id);
    _update(() => bookmarks = saved ? bookmarks.where((x) => x != id).toList() : [...bookmarks, id]);
    _store.saveBookmarks(bookmarks);
    _user?.setBookmark(id, !saved);
    // '관심 부탁 저장하기' 미션. 같은 부탁을 껐다 켜며 채우지 못하게 id당 하루 한 번만 센다.
    if (!saved) MissionTracker.bump(MissionTracker.saveTask, unique: id);
    flash(saved ? '관심 저장을 해제했어요' : '관심 저장했어요 · 마이에서 볼 수 있어요');
  }

  // ── 지원·거래 (서버 함수) ──────────────────────────────────────────────

  /// 지원하기. 서버 함수가 지원서를 만들고, 결과는 구독으로 들어온다. 지원됐으면 true.
  /// 가격 제안을 저장해 뒀으면 마지막 제안을 함께 보낸다.
  Future<bool> apply(TaskItem it) async {
    if (it.isMine || it.isExpired) {
      flash(it.isMine ? '내가 올린 부탁에는 지원할 수 없어요' : '마감된 부탁이에요');
      return false;
    }
    if (it.sample) {
      flash('예시로 보여 주는 부탁이라 지원할 수 없어요');
      return false;
    }
    if (!_serverMode) {
      flash(serverIssue ?? '로그인 후 지원할 수 있어요');
      return false;
    }
    if (trades[it.id]?.isActive ?? false) {
      flash('이미 지원한 부탁이에요');
      return false;
    }
    final offer = offers[it.id]?.lastOrNull;
    try {
      await TradeRepository.apply(it.id, offerPrice: offer?.price, msg: (offer?.msg.isEmpty ?? true) ? null : offer!.msg);
    } on ServerException catch (e) {
      flash(e.message);
      return false;
    }
    // 구독이 곧 같은 값으로 덮어쓴다. 그 사이 화면이 비지 않게 먼저 표시해 둔다.
    _update(() => trades = {...trades, it.id: Trade.pending()});
    flash(it.mode == 'together' ? '신청했어요 · 진행 중에서 확인하세요' : '지원했어요 · 요청자가 수락하면 진행 중에서 확인할 수 있어요');
    return true;
  }

  /// 거래 단계 진행. 누가 어떤 단계를 누를 수 있는지는 서버가 확인한다
  /// (수행자: start·finish / 요청자: confirm·revise / 시작 전 취소: 양쪽).
  /// 대기 중인 지원의 cancel은 지원 철회다.
  Future<void> updateTrade(int id, String action) async {
    final current = trades[id];
    if (current == null) return;
    if (!_serverMode) {
      flash(serverIssue ?? '로그인 후 진행할 수 있어요');
      return;
    }
    try {
      if (current.status == 'pending') {
        if (action != 'cancel') return;
        await TradeRepository.withdraw(id);
      } else {
        final tradeId = _tradeIds[id];
        if (tradeId == null) {
          flash('거래 정보를 불러오는 중이에요. 잠시 후 다시 시도해 주세요.');
          return;
        }
        await TradeRepository.advance(tradeId, action);
      }
    } on ServerException catch (e) {
      flash(e.message);
      return;
    }
    flash(switch (action) {
      'start' => '부탁을 시작했어요',
      'finish' => '완료 확인을 요청했어요',
      'confirm' => '완료를 확인했어요',
      'revise' => '보완을 요청했어요',
      'cancel' => current.status == 'pending' ? '지원을 취소했어요' : '거래를 취소했어요',
      _ => '처리했어요',
    });
  }

  /// 요청자: 받은 지원 수락 → 거래가 시작된다(같은 부탁의 다른 지원은 서버가 거절 처리)
  Future<void> acceptApplication(Application a) async {
    try {
      await TradeRepository.accept(a.requestId, a.helperUid);
      flash('${a.helperName}님의 지원을 수락했어요');
    } on ServerException catch (e) {
      flash(e.message);
    }
  }

  Future<void> rejectApplication(Application a) async {
    try {
      await TradeRepository.reject(a.requestId, a.helperUid);
      flash('지원을 거절했어요');
    } on ServerException catch (e) {
      flash(e.message);
    }
  }

  /// 가격 제안. 이 기기에 저장해 두었다가 지원할 때 함께 보낸다.
  void sendOffer(TaskItem it, int price, String msg) {
    final min = it.mode == 'sea' ? seaMin : 1000;
    if (price < min) {
      flash('제안 금액은 ${won(min)} 이상이어야 해요');
      return;
    }
    if (trades[it.id]?.isActive ?? false) {
      flash('이미 지원한 부탁이에요 · 제안 금액은 지원할 때 함께 보내요');
      return;
    }
    final list = [...?offers[it.id], Offer(price, msg)];
    _update(() => offers = {...offers, it.id: list});
    _store.saveOffers(offers);
    flash('가격 제안을 저장했어요 · 지원할 때 요청자에게 함께 보내요');
  }

  void _watchTrades(String uid) {
    _stopTradeWatch();
    if (!Backend.ready) return;
    final repo = TradeRepository(uid);
    _tradeSubs.addAll([
      repo.watchMyApplications().listen((v) {
        _myApps = v;
        _rebuildTrades();
      }),
      repo.watchReceived().listen((v) {
        _received = v;
        _rebuildTrades();
      }),
      repo.watchTrades(asRequester: false).listen((v) {
        _helperTrades = v;
        _rebuildTrades();
      }),
      repo.watchTrades(asRequester: true).listen((v) {
        _requesterTrades = v;
        _rebuildTrades();
      }),
    ]);
  }

  void _stopTradeWatch() {
    for (final sub in _tradeSubs) {
      sub.cancel();
    }
    _tradeSubs.clear();
    _myApps = [];
    _received = [];
    _helperTrades = [];
    _requesterTrades = [];
    _tradeIds.clear();
  }

  /// 서버의 지원서·거래 문서를 화면용 [trades] 하나로 합친다.
  void _rebuildTrades() {
    final next = <int, Trade>{};
    final ids = <int, String>{};
    final byId = {for (final t in [..._helperTrades, ..._requesterTrades]) t.id: t};

    // 내가 수행자: 지원서 상태 + 수락 뒤에는 거래 문서의 단계
    for (final a in _myApps) {
      final rid = a.requestIdInt;
      if (rid == null) continue;
      final t = a.tradeId == null ? null : byId[a.tradeId];
      final status = switch (a.status) {
        'pending' => 'pending',
        'accepted' => t?.status ?? 'matched',
        _ => 'cancelled', // 거절·철회·시작 전 취소
      };
      next[rid] = Trade(status, t?.updatedAt ?? a.updatedAt);
      if (a.status == 'accepted' && a.tradeId != null) ids[rid] = a.tradeId!;
    }

    // 내가 요청자: 같은 부탁에 거래가 여러 번(취소 뒤 다시 수락) 생길 수 있어 가장 최근 것을 쓴다
    final mine = [..._requesterTrades]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    for (final t in mine) {
      final rid = int.tryParse(t.requestId);
      if (rid == null) continue;
      next[rid] = Trade(t.status, t.updatedAt);
      ids[rid] = t.id;
    }

    _update(() {
      trades = next;
      _tradeIds
        ..clear()
        ..addAll(ids);
      received = [
        for (final a in _received)
          if (a.isPending) a,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
    _store.saveTrades(trades);
    _loadRelated(next.keys);
  }

  /// 내 지원·거래와 이어진 부탁 중 목록에 없는 것(모집이 끝나 공개 목록에서 빠진 것)을 한 번씩 불러온다.
  Future<void> _loadRelated(Iterable<int> ids) async {
    final known = {for (final it in items) it.id};
    final missing = [
      for (final id in ids)
        if (!known.contains(id) && !_relatedLoading.contains(id)) id,
    ];
    if (missing.isEmpty) return;
    _relatedLoading.addAll(missing);
    for (final id in missing) {
      final it = await _requests.get(id);
      if (it != null) _update(() => _related[id] = it);
    }
  }

  void addRequest(NewRequestData data) {
    final uid = AuthService().currentUser?.uid;
    final sea = data.mode == 'sea';
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
      region: sea ? null : (scope == '전국' ? '우리 동네' : scope),
      // 새 부탁은 실제 거리를 알 수 없어 임의의 거리를 붙이지 않는다.
      distM: sea ? 9e9 : null,
      mins: sea ? 0 : data.mins,
      price: data.price,
      who: profile?.nickname ?? '나',
      // 방금 올린 글에 별점·본인인증을 자동으로 붙이지 않는다.
      rating: 0,
      reviews: 0,
      deals: 0,
      resp: 0,
      verified: false,
      hot: data.hot,
      deadline: data.deadline,
      deliveryPlace: data.deliveryPlace,
      budget: data.budget,
      payment: data.payment,
      completion: data.completion,
      sample: false,
      ownerUid: uid,
      // 로그인이 풀리거나 서버가 없어도 내 글임을 알 수 있게 표시를 남긴다.
      mine: true,
    );
    _update(() => created = [it, ...created]);
    _store.saveRequests(created);
    MissionTracker.bump(MissionTracker.postTask, unique: it.id);
    onTicket?.call(TicketRules.firstPost);
    if (uid != null) _requests.add(it);
    flash(uid == null ? '부탁을 올렸어요 · 로그인하면 계정에 저장돼요' : (it.hot ? '급해요로 목록 맨 위에 올렸어요' : '부탁을 올렸어요'));
  }

  /// 중고 물건 전달 부탁 (v77). 전달비만 정해 올리면 돈벌기 목록에 '중고'로 보인다.
  void addDelivery(UsedItem u, int fee) {
    final uid = AuthService().currentUser?.uid;
    final it = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch,
      mode: 'ask',
      cat: 'move',
      extra: 'used',
      title: '${u.title} 전달해주기',
      desc: '중고로 거래한 물건이에요. ${u.area}에서 받아 저에게 전달해 주세요.',
      place: '${u.area} → ${shortRegion(scope)}',
      region: scope == '전국' ? '우리 동네' : scope,
      distM: null,
      mins: 30,
      price: fee,
      who: profile?.nickname ?? '나',
      rating: 0,
      reviews: 0,
      deals: 0,
      resp: 0,
      verified: false,
      sample: false,
      ownerUid: uid,
      mine: true,
    );
    _update(() => created = [it, ...created]);
    _store.saveRequests(created);
    if (uid != null) _requests.add(it);
    flash('전달 부탁을 올렸어요 · 돈벌기 목록에 "중고"로 보여요');
  }

  // ── 겸사페이 ────────────────────────────────────────────────────────────

  void _addPay(PayKind kind, int amount, String label, {int? requestId}) {
    final entry = PayEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      kind: kind,
      amount: amount,
      label: label,
      at: DateTime.now(),
      requestId: requestId,
    );
    _update(() => payEntries = [entry, ...payEntries]);
    _store.savePay(payEntries);
    _pay?.add(entry);
  }

  /// 개발용 충전. 실제 이체가 아니라 원장에 줄만 쌓는다.
  /// 릴리스 빌드에서는 [PayConfig.debugTopUp]이 false라 화면에서 여기까지 오지 않지만 한 번 더 막는다.
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

  // ── 프로필 ──────────────────────────────────────────────────────────────

  /// 닉네임 변경. 계정(표시 이름)과 프로필 문서를 같이 맞춘다.
  Future<void> renameNickname(String name) async {
    final trimmed = name.trim();
    final current = profile;
    if (trimmed.isEmpty || current == null) return;
    _update(() => profile = current.copyWith(nickname: trimmed));
    _user?.saveProfileFields(nickname: trimmed);
    try {
      await AuthService().updateDisplayName(trimmed);
    } catch (e) {
      debugPrint('표시 이름 변경 실패: $e');
    }
    flash('닉네임을 바꿨어요');
  }

  void setScope(String picked) {
    _update(() => scope = picked);
    _user?.saveProfileFields(region: picked);
  }
}
