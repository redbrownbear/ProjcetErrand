import '../storage/local_store.dart';

/// 겸이 말풍선(이벤트 · 혜택 안내) 노출 상한 (A24).
///
/// - 앱을 한 번 켜는 동안 [perSession]번까지
/// - 한 번 보인 뒤 [gap] 안에는 다른 화면에서 다시 띄우지 않는다(탭을 오갈 때마다 튀어나오지 않게)
/// - 닫기(×)를 누르면 [snooze] 동안 안 보인다(이 기기에 기억)
class BubbleQuota {
  static const perSession = 3;
  static const gap = Duration(minutes: 3);
  static const snooze = Duration(hours: 24);

  static int _shown = 0;
  static DateTime? _last;

  /// 테스트에서 바꿔 끼운다
  static DateTime Function() clock = DateTime.now;

  /// 지금 하나 띄워도 되면 true를 돌려주고 한 번 쓴 것으로 센다
  static bool take() {
    final now = clock();
    final until = LocalStore.read<int>('bubbleSnoozeUntil', 0);
    if (now.millisecondsSinceEpoch < until) return false;
    if (_shown >= perSession) return false;
    if (_last != null && now.difference(_last!) < gap) return false;
    _shown++;
    _last = now;
    return true;
  }

  static void dismiss() => LocalStore.write('bubbleSnoozeUntil', clock().add(snooze).millisecondsSinceEpoch);

  /// 테스트용 — 세션 카운트를 비운다
  static void reset() {
    _shown = 0;
    _last = null;
    LocalStore.remove('bubbleSnoozeUntil');
  }
}
