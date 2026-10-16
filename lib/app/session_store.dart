import '../core/storage/local_store.dart';
import '../features/benefits/models/coupon.dart';
import '../features/errand/models/offer.dart';
import '../features/errand/models/task_item.dart';
import '../features/errand/models/trade.dart';
import '../features/pay/models/pay_entry.dart';

/// 이 기기에 남기는 사본의 읽기·쓰기.
///
/// 서버에 못 붙을 때의 보관소이자, 서버가 있을 때의 오프라인 사본이다.
/// 저장 형식(키 이름·JSON 모양)을 아는 곳은 여기 하나뿐이다.
///
/// 사본은 한 번에 한 사람 것이다. 누구 것인지 [loadOwner]로 남겨, 로그아웃하거나 다른 계정으로
/// 들어올 때 앞사람 자료가 화면에 남거나 새 계정으로 올라가지 않게 한다.
class SessionStore {
  const SessionStore();

  static const _accountKeys = [
    'requests',
    'bookmarks',
    'trades',
    'offers',
    'ledger',
    'missions',
    'payEntries',
    'points',
    'coupons',
  ];

  /// 이 사본이 어느 계정 것인지. 로그아웃 상태에서 쌓인 사본이면 null.
  String? loadOwner() {
    final v = LocalStore.read<String>('owner', '');
    return v.isEmpty ? null : v;
  }

  void saveOwner(String? uid) => uid == null ? LocalStore.remove('owner') : LocalStore.write('owner', uid);

  /// 계정 자료 사본을 모두 지운다. 서버에 원본이 있는 계정 자료에만 쓴다.
  void clearAccount() {
    for (final k in _accountKeys) {
      LocalStore.remove(k);
    }
  }

  // ── 읽기 ────────────────────────────────────────────────────────────────

  List<TaskItem> loadRequests() => [for (final j in LocalStore.read<List<dynamic>>('requests', const [])) ?TaskItem.fromJson(j)];

  List<int> loadBookmarks() => LocalStore.read<List<dynamic>>('bookmarks', const []).whereType<int>().toList();

  Map<int, Trade> loadTrades() => {
    for (final e in LocalStore.read<Map<String, dynamic>>('trades', const {}).entries)
      if (int.tryParse(e.key) != null && Trade.fromJson(e.value) != null) int.parse(e.key): Trade.fromJson(e.value)!,
  };

  Map<int, List<Offer>> loadOffers() => {
    for (final e in LocalStore.read<Map<String, dynamic>>('offers', const {}).entries)
      if (int.tryParse(e.key) != null && e.value is List)
        int.parse(e.key): [
          for (final o in e.value as List)
            if (o is Map && o['price'] is int) Offer(o['price'] as int, o['msg'] is String ? o['msg'] as String : ''),
        ],
  };

  /// 적립 원장 (key → 받은 날짜 또는 '*')
  Map<String, String> loadLedger() => {
    for (final e in LocalStore.read<Map<String, dynamic>>('ledger', const {}).entries)
      if (e.value is String) e.key: e.value as String,
  };

  List<String> loadMissions() => LocalStore.read<List<dynamic>>('missions', const []).whereType<String>().toList();

  int loadPoints() => LocalStore.read<int>('points', 0);

  List<Coupon> loadCoupons() => [for (final j in LocalStore.read<List<dynamic>>('coupons', const [])) ?Coupon.fromJson(j)];

  List<PayEntry> loadPay() => [for (final j in LocalStore.read<List<dynamic>>('payEntries', const [])) ?PayEntry.fromJson(j)];

  // ── 쓰기 ────────────────────────────────────────────────────────────────

  void saveRequests(List<TaskItem> created) => LocalStore.write('requests', [for (final it in created) it.toJson()]);

  void saveBookmarks(List<int> bookmarks) => LocalStore.write('bookmarks', bookmarks);

  void saveTrades(Map<int, Trade> trades) =>
      LocalStore.write('trades', {for (final e in trades.entries) '${e.key}': e.value.toJson()});

  void saveOffers(Map<int, List<Offer>> offers) => LocalStore.write('offers', {
    for (final e in offers.entries)
      '${e.key}': [
        for (final o in e.value) {'price': o.price, 'msg': o.msg},
      ],
  });

  void saveLedger(Map<String, String> entries) => LocalStore.write('ledger', entries);

  void saveMissions(List<String> done) => LocalStore.write('missions', done);

  void savePoints(int points) => LocalStore.write('points', points);

  void saveCoupons(List<Coupon> coupons) => LocalStore.write('coupons', [for (final c in coupons) c.toJson()]);

  void savePay(List<PayEntry> entries) => LocalStore.write('payEntries', [for (final e in entries) e.toJson()]);
}
