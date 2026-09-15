import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/benefits/models/reward_ledger.dart';

void main() {
  group('RewardLedger', () {
    test('일일 보상은 하루에 한 번만 지급된다', () {
      final ledger = RewardLedger();
      expect(ledger.claim('walk'), isTrue);
      expect(ledger.claim('walk'), isFalse);
      expect(ledger.isClaimed('walk'), isTrue);
    });

    test('화면이 달라도 키가 같으면 같은 보상으로 본다', () {
      // 홈·혜택 탭·걷기 화면이 모두 walkRewardKey를 쓴다.
      final ledger = RewardLedger();
      expect(ledger.claim('walk'), isTrue); // 홈에서 받기
      expect(ledger.claim('walk'), isFalse); // 걷기 화면에서 또 받기
    });

    test('일회성 보상은 날짜가 바뀌어도 다시 받을 수 없다', () {
      final ledger = RewardLedger();
      expect(ledger.claim('mission:m1', daily: false), isTrue);
      expect(ledger.claim('mission:m1', daily: false), isFalse);
      expect(ledger.isClaimed('mission:m1', daily: false), isTrue);
    });

    test('키가 다르면 서로 영향을 주지 않는다', () {
      final ledger = RewardLedger();
      expect(ledger.claim('ad:0'), isTrue);
      expect(ledger.claim('ad:1'), isTrue);
      expect(ledger.claim('ad:0'), isFalse);
    });

    test('하루 기준은 기기 시간대가 아니라 한국 시간(UTC+9)이다', () {
      // UTC로는 3일 15:00이지만 한국에서는 이미 4일 00:00이다.
      expect(RewardLedger.todayKey(DateTime.utc(2026, 9, 3, 15)), '2026-09-04');
      expect(RewardLedger.todayKey(DateTime.utc(2026, 9, 3, 14, 59)), '2026-09-03');
    });

    test('날짜가 바뀌면 일일 보상을 다시 받을 수 있다', () {
      final ledger = RewardLedger();
      expect(ledger.claim('walk'), isTrue);
      // 어제 받은 것으로 기록을 바꿔치기하는 대신, 오늘 키와 다른 날은 미수령으로
      // 판정되는지를 todayKey로 확인한다.
      expect(RewardLedger.todayKey(DateTime.utc(2026, 1, 1)), isNot(RewardLedger.todayKey()));
    });
  });
}
