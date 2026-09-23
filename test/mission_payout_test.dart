import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/benefits/data/daily_missions.dart';
import 'package:gyeomsa/features/benefits/data/point_rules.dart';
import 'package:gyeomsa/features/benefits/models/daily_mission.dart';

/// '가볍게 모으기'가 실제로 얼마를 지급하는지.
///
/// 이 계산이 틀려도 앱은 안 죽는다. 조용히 재원보다 더 주거나 덜 주고, 몇 달 뒤
/// 정산에서야 드러난다. 그래서 화면 없이 도는 이 테스트로 못 박는다.
void main() {
  final ad = dailyMissionById('ad')!;
  final coupang = dailyMissionById('coupang')!;
  final offerwall = dailyMissionById('offerwall')!;

  group('광고 — 정액', () {
    test('금액과 무관하게 정해진 값을 준다', () {
      expect(ad.pointsFor(0), PointRules.adWatch);
      expect(ad.pointsFor(50000), PointRules.adWatch);
    });

    test('하루에 받을 수 있는 총량이 재원을 넘지 않는다', () {
      // 3회를 다 봐도 그날 광고로 번 돈(최악 eCPM 기준) 안에 있어야 한다
      final paidOut = PointRules.adWatch * PointRules.adWatchCap;
      final earned = PointRules.adRevenueLow * PointRules.adWatchCap;
      expect(paidOut, lessThan(earned), reason: '광고를 볼수록 손해가 난다');
    });
  });

  group('쿠팡 — 주문액 정률', () {
    test('주문액에 비례한다', () {
      expect(coupang.pointsFor(30000), 300);
      expect(coupang.pointsFor(10000), 100);
    });

    test('정액이 아니라서 소액 주문에 과지급하지 않는다', () {
      // 예전에는 첫 주문에 2,500P 정액이었다. 1만원짜리를 사면
      // 수수료(3% 기준 300원)보다 훨씬 많이 나가 건당 적자였다.
      expect(coupang.pointsFor(10000), lessThan(2500));
    });

    test('어떤 금액이든 수수료 하한(1%) 안에서 지급된다', () {
      // 파트너스 수수료는 카테고리별 1~3%다. 가장 낮은 1% 카테고리(가전·디지털)
      // 에서도 남아야 어느 상품을 팔든 손해가 안 난다.
      for (final price in [1000, 9999, 30000, 123456, 1000000]) {
        final commission = price * 0.01; // 최저 요율로 번 돈
        expect(coupang.pointsFor(price), lessThanOrEqualTo(commission),
            reason: '$price원 주문에서 수수료보다 많이 준다');
      }
    });

    test('나누어떨어지지 않으면 내린다', () {
      // 12,345 × 1% = 123.45 → 올리면 재원보다 더 주는 쪽이다
      expect(coupang.pointsFor(12345), 123);
      expect(coupang.pointsFor(199), 1);
    });

    test('0원이나 음수는 적립하지 않는다', () {
      expect(coupang.pointsFor(0), 0);
      expect(coupang.pointsFor(-10000), 0);
    });
  });

  group('오퍼월 — 제휴사가 정한다', () {
    test('앱은 금액을 모른다', () {
      // 캠페인 단가는 제휴사 서버가 콜백으로 알려준다. 앱이 추측하면 안 된다.
      expect(offerwall.pointsFor(50000), 0);
      expect(offerwall.payoutLabel, '캠페인마다 다름');
    });

    test('콜백 단가에서 정해진 몫만 넘긴다', () {
      expect(PointRules.offerwallPoints(1000), 650);
      expect(PointRules.offerwallPoints(3000), 1950);
    });

    test('제휴사 단가보다 많이 주지 않는다', () {
      for (final payout in [500, 1234, 3000, 80000]) {
        expect(PointRules.offerwallPoints(payout), lessThan(payout),
            reason: '$payout원 캠페인에서 받은 것보다 많이 준다');
      }
    });

    test('0원이나 음수 콜백은 적립하지 않는다', () {
      expect(PointRules.offerwallPoints(0), 0);
      expect(PointRules.offerwallPoints(-1000), 0);
    });
  });

  group('지급 방식이 화면 문구와 어긋나지 않는다', () {
    test('정액 미션만 숫자를 약속한다', () {
      for (final m in dailyMissions) {
        if (m.payout == PayoutKind.fixed) {
          expect(m.points, greaterThan(0), reason: '${m.title}이 0P를 약속한다');
          expect(m.payoutLabel, contains('${m.points}'));
        } else {
          // 변동 지급인데 points에 값이 있으면 화면이 그 숫자를 약속해 버린다
          expect(m.points, 0, reason: '${m.title}은 변동 지급인데 고정 포인트가 적혀 있다');
        }
      }
    });

    test('즉시 적립되는 미션은 정액뿐이다', () {
      // 금액을 모르는 미션을 그 자리에서 적립하면 얼마를 줄지 알 수 없다
      for (final m in dailyMissions) {
        if (m.instant) {
          expect(m.payout, PayoutKind.fixed, reason: '${m.title}은 금액을 모르는데 즉시 적립한다');
        }
      }
    });
  });
}
