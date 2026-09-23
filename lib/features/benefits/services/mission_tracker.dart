import '../../../core/storage/local_store.dart';
import '../models/reward_ledger.dart';

/// 여러 화면에 흩어진 행동을 미션 진행도로 모으는 곳.
///
/// '부탁 상세 3개 열어보기' 같은 미션은 미션 화면이 아니라 목록·상세에서
/// 진행된다. 그 화면들이 미션을 알 필요는 없으므로, 여기에 이름만 찍어 두고
/// 미션 쪽에서 세기만 한다.
///
/// 날짜가 바뀌면 자동으로 0이 된다. 기준 날짜는 [RewardLedger.todayKey]와
/// 같은 한국 시간이라, 적립 판정과 진행도가 어긋나지 않는다.
class MissionTracker {
  static const _store = 'missionCounters';

  /// 부탁 상세를 열었다
  static const openDetail = 'openDetail';

  /// 관심 저장을 했다
  static const saveTask = 'saveTask';

  /// 부탁을 올렸다
  static const postTask = 'postTask';

  static Map<String, int> _counts = {};
  static String _date = '';
  static bool _loaded = false;

  static void _ensure() {
    final today = RewardLedger.todayKey();
    if (_loaded && _date == today) return;

    final saved = LocalStore.read<Map<String, dynamic>>(_store, const {});
    if (saved['date'] == today && saved['c'] is Map) {
      _counts = {
        for (final e in (saved['c'] as Map).entries)
          if (e.value is int) '${e.key}': e.value as int,
      };
    } else {
      _counts = {}; // 날짜가 바뀌었으면 오늘치는 새로 센다
    }
    _date = today;
    _loaded = true;
  }

  static int count(String name) {
    _ensure();
    return _counts[name] ?? 0;
  }

  /// 같은 대상을 두 번 세지 않도록 [unique]에 부탁 id 같은 식별자를 넘긴다.
  /// 이미 센 대상이면 아무 일도 하지 않고 false.
  static bool bump(String name, {Object? unique}) {
    _ensure();
    if (unique != null) {
      final seenKey = '$name:seen:$unique';
      if (_counts.containsKey(seenKey)) return false;
      _counts[seenKey] = 1;
    }
    _counts[name] = (_counts[name] ?? 0) + 1;
    LocalStore.write(_store, {'date': _date, 'c': _counts});
    return true;
  }

  /// 테스트에서 상태를 비울 때 쓴다.
  static void reset() {
    _counts = {};
    _date = '';
    _loaded = false;
    LocalStore.remove(_store);
  }
}
