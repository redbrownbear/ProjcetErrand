import '../core/storage/local_store.dart';
import '../features/errand/models/offer.dart';
import '../features/errand/models/task_item.dart';
import '../features/errand/models/trade.dart';
import '../features/pay/models/pay_entry.dart';

/// 이 기기에 남기는 사본의 읽기·쓰기.
///
/// 서버에 못 붙을 때의 보관소이자, 서버가 있을 때의 오프라인 사본이다.
/// 저장 형식(키 이름·JSON 모양)을 아는 곳은 여기 하나뿐이다.
class SessionStore {
  const SessionStore();

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

  void savePay(List<PayEntry> entries) => LocalStore.write('payEntries', [for (final e in entries) e.toJson()]);
}
