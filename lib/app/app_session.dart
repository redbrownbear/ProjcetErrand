import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/backend/backend.dart';
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
import '../features/errand/models/new_request_data.dart';
import '../features/errand/models/offer.dart';
import '../features/errand/models/task_item.dart';
import '../features/errand/models/trade.dart';
import '../features/errand/repositories/errand_repository.dart';
import '../features/errand/repositories/request_repository.dart';
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

  UserProfile? profile;
  bool syncing = false;
  String scope = '서울 서초구';

  /// 화면 아래에 잠깐 띄우는 안내 문구
  String? toast;

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

  /// 지원 내역과 거래 단계
  Map<int, Trade> trades = {};

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

    _requestSub = _requests.watchOpen().listen((list) => _update(() => _server = list));
    _authSub = AuthService().authStateChanges.listen(_bindUser);
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    _requestSub?.cancel();
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
    for (final it in [..._server, ...created, ..._seed]) {
      if (!seen.add(it.id)) continue;
      out.add(!it.mine && mineIds.contains(it.id) ? it.copyWith(mine: true) : it);
    }
    return out;
  }

  bool get isLoggedIn => AuthService().currentUser != null;

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

  /// 로그인 상태가 바뀔 때마다 서버 자료를 붙이거나 뗀다.
  Future<void> _bindUser(User? user) async {
    if (_disposed) return;
    TaskItem.currentUid = user?.uid;

    if (user == null) {
      _update(() {
        _user = null;
        _pay = null;
        profile = null;
        syncing = false;
      });
      return;
    }

    final repo = UserRepository(user.uid);
    _update(() {
      _user = repo;
      _pay = PayRepository(user.uid);
      syncing = true;
    });

    if (!await repo.isMigrated()) await _migrateLocal(repo);
    if (_disposed) return;

    await _pullServer(repo, user);
    _update(() => syncing = false);
  }

  /// 첫 로그인 이관. 이 기기에 있던 부탁·관심·지원 내역·제안을 계정으로 한 번 올린다.
  /// 문서 id가 곧 부탁 id라 두 번 올려도 덮어쓰기지만, 쓸데없는 호출을 막으려고 표시를 남긴다.
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

  /// 서버 자료를 읽어 채운다. 못 읽으면 이 기기의 값이 그대로 남는다.
  Future<void> _pullServer(UserRepository repo, User user) async {
    final loaded = await repo.ensureProfile(email: user.email ?? '', nickname: user.displayName);
    final serverBookmarks = await repo.loadBookmarks();
    final serverTrades = await repo.loadTrades();
    final serverOffers = await repo.loadOffers();
    final serverCoupons = await repo.loadCoupons();
    final serverLedger = await repo.loadLedger();
    final serverPay = await PayRepository(repo.uid).load();
    if (_disposed) return;

    _update(() {
      profile = loaded;
      if (loaded != null) points = loaded.points;
      if (serverBookmarks.isNotEmpty) bookmarks = serverBookmarks;
      if (serverTrades.isNotEmpty) trades = serverTrades;
      if (serverOffers.isNotEmpty) offers = serverOffers;
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
    _store.saveTrades(trades);
    _store.saveOffers(offers);
    _store.saveLedger(_rewards.entries);
    _store.saveMissions(doneMissions);
    _store.savePay(payEntries);
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
  }

  void redeem(RewardProduct p) {
    if (points < p.points) {
      flash('보유 포인트가 부족해요');
      return;
    }
    final coupon = Coupon(
      id: DateTime.now().millisecondsSinceEpoch,
      brandK: p.brand,
      name: p.name,
      points: p.points,
      exp: '2026.12.31',
      code: genCode(),
    );
    _update(() {
      points -= p.points;
      coupons = [coupon, ...coupons];
    });
    _user?.saveCoupon(coupon);
    _user?.savePoints(points);
  }

  void useCoupon(int id) {
    final index = coupons.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final used = coupons[index].copyWith(used: true);
    _update(() => coupons = [...coupons]..[index] = used);
    _user?.saveCoupon(used);
  }

  void completeMission(PartnerMission m) {
    if (doneMissions.contains(m.id)) return;
    _update(() => doneMissions = [...doneMissions, m.id]);
    _store.saveMissions(doneMissions);
    earn(m.points, m.title, key: '$_missionKey${m.id}', daily: false);
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

  /// 지원하기 → '요청자 확인 대기'로 저장한다. 새로 지원됐으면 true.
  /// 요청자에게 실제 알림이 가지는 않는다 (알림·수락 연동 전).
  bool apply(TaskItem it) {
    if (it.isMine || it.isExpired) {
      flash(it.isMine ? '내가 올린 부탁에는 지원할 수 없어요' : '마감된 부탁이에요');
      return false;
    }
    final current = trades[it.id];
    if (current != null && current.status != 'cancelled') return false;

    final trade = Trade.pending();
    _update(() => trades = {...trades, it.id: trade});
    _store.saveTrades(trades);
    _user?.saveTrade(it.id, trade, title: it.title, price: it.price, mode: it.mode);
    flash(it.mode == 'together' ? '신청했어요 · 진행 중에서 확인하세요' : '지원했어요 · 요청자 응답 연동은 준비 중이에요');
    return true;
  }

  void updateTrade(int id, String action) {
    final current = trades[id];
    if (current == null) return;
    final next = current.advance(action);
    if (identical(next, current)) return; // 허용되지 않는 단계 이동

    _update(() => trades = {...trades, id: next});
    _store.saveTrades(trades);
    _user?.saveTrade(id, next);

    // 완료된 순간에만 사례비를 겸사페이 원장에 남긴다. 내가 올린 부탁은 내가 받는 돈이 아니다.
    final justCompleted = current.status != 'completed' && next.status == 'completed';
    if (!justCompleted) return;
    final it = items.where((i) => i.id == id).firstOrNull;
    if (it != null && !it.isMine && it.price > 0) _addPay(PayKind.earn, it.price, it.title, requestId: it.id);
  }

  void sendOffer(TaskItem it, int price, String msg) {
    final min = it.mode == 'sea' ? seaMin : 1000;
    if (price < min) {
      flash('제안 금액은 ${won(min)} 이상이어야 해요');
      return;
    }
    final list = [...?offers[it.id], Offer(price, msg)];
    _update(() => offers = {...offers, it.id: list});
    _store.saveOffers(offers);
    _user?.saveOffers(it.id, list);
    flash('가격 제안을 보냈어요. 요청자에게만 보여요');
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
    if (uid != null) _requests.add(it);
    flash(uid == null ? '부탁을 올렸어요 · 로그인하면 계정에 저장돼요' : (it.hot ? '급해요로 목록 맨 위에 올렸어요' : '부탁을 올렸어요'));
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
