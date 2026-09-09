/// 포인트 적립 중복 방지 원장.
///
/// 예전에는 화면마다 `bool claimed` 로컬 상태를 따로 들고 있어서, 같은 보상을
/// 화면을 옮겨가며 몇 번이고 다시 받을 수 있었다. (걷기 적립 버튼만 해도 홈·혜택
/// 탭·걷기 화면 세 곳에 있어서 하루에 세 번 적립됐다.)
/// 적립 이력을 여기 한 곳에 모아, 어느 화면에서 눌렀든 한 번만 받게 한다.
class RewardLedger {
  /// key -> 받은 날짜(일일 보상) 또는 [_once](일회성 보상)
  final Map<String, String> _claims = {};

  static const String _once = '*';

  /// 하루 기준은 한국 시간(UTC+9). 기기 시간대 설정과 무관하게 같은 날로 취급한다.
  static String todayKey([DateTime? now]) {
    final kst = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 9));
    final m = kst.month.toString().padLeft(2, '0');
    final d = kst.day.toString().padLeft(2, '0');
    return '${kst.year}-$m-$d';
  }

  /// [daily]가 true면 "오늘 이미 받았는지", false면 "한 번이라도 받았는지".
  bool isClaimed(String key, {bool daily = true}) =>
      daily ? _claims[key] == todayKey() : _claims.containsKey(key);

  /// 아직 안 받은 보상이면 기록하고 true. 이미 받았으면 아무것도 안 하고 false.
  bool claim(String key, {bool daily = true}) {
    if (isClaimed(key, daily: daily)) return false;
    _claims[key] = daily ? todayKey() : _once;
    return true;
  }
}

/// 적립 요청. [key]가 같으면 같은 보상으로 보고 중복 지급을 막는다.
typedef EarnFn = Future<void> Function(int amt, String label, {required String key, bool daily});

/// 해당 보상을 이미 받았는지. 버튼을 "완료" 상태로 그릴 때 쓴다.
typedef IsClaimedFn = bool Function(String key, {bool daily});
