import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/benefits/data/daily_missions.dart';
import 'package:gyeomsa/features/benefits/data/daily_quiz.dart';
import 'package:gyeomsa/features/benefits/data/mission_providers.dart';
import 'package:gyeomsa/features/benefits/data/point_rules.dart';
import 'package:gyeomsa/features/benefits/models/daily_mission.dart';
import 'package:gyeomsa/features/benefits/models/mission_provider.dart';
import 'package:gyeomsa/features/benefits/models/reward_ledger.dart';
import 'package:gyeomsa/features/benefits/services/mission_engine.dart';

/// 적립 원장을 흉내 낸다. [MissionEngine]은 원장을 콜백으로만 보므로
/// 화면이나 저장소 없이 그대로 확인할 수 있다.
MissionEngine engineWith(Set<String> claimed, {List<DailyMission>? missions}) => MissionEngine(
      (key, {daily = true}) => claimed.contains(key),
      missions: missions ?? dailyMissions,
    );

void main() {
  group('재원 있는 미션만 서비스한다', () {
    test('서비스 중인 미션은 전부 제휴 재원이 있다', () {
      // 자체 재원(inapp) 미션은 전액 우리 마케팅비로 나간다. 사람이 늘수록
      // 손실이 정비례로 커져서 초기에는 두지 않기로 했다.
      for (final m in dailyMissions) {
        expect(m.providerId, isNot('inapp'), reason: '${m.title}은 재원이 없는데 서비스 목록에 있다');
      }
    });

    test('내려 둔 미션도 id로는 찾을 수 있다', () {
      // 되살릴 때 원장 키가 바뀌면 이미 받은 사람이 또 받게 된다.
      expect(dailyMissionById('quiz'), isNotNull);
      expect(dailyMissionById('attend')?.ledgerKey(), 'benefit:attend');
    });

    test('서비스 목록과 보류 목록에 같은 id가 없다', () {
      final live = {for (final m in dailyMissions) m.id};
      for (final m in parkedMissions) {
        expect(live, isNot(contains(m.id)), reason: '${m.id}가 양쪽에 다 있다');
      }
    });
  });

  group('지급 방식', () {
    test('광고는 정액, 쿠팡은 정률, 오퍼월은 제휴사가 정한다', () {
      expect(dailyMissionById('ad')!.payout, PayoutKind.fixed);
      expect(dailyMissionById('coupang')!.payout, PayoutKind.rate);
      expect(dailyMissionById('offerwall')!.payout, PayoutKind.partner);
    });

    test('쿠팡은 정액이 아니라 주문액 비율이다', () {
      // 정액으로 주면 1만원짜리를 산 사람에게도 8만원어치 판 만큼 줘야 한다.
      final m = dailyMissionById('coupang')!;
      expect(m.points, 0);
      expect(m.rate, PointRules.coupangRate);
      expect(m.payoutLabel, '주문액의 1%');

      // 수수료(카테고리별 1~3%) 안에서 지급돼야 어느 카테고리에서도 남는다
      expect(m.rate, lessThan(0.01 + 0.0001));
    });

    test('광고 단가는 최악의 eCPM에서도 재원 안에 있다', () {
      // 밴드 상단으로 잡으면 실측이 나쁘게 나왔을 때 곧바로 역마진이다.
      // 하단(11원)에 지급률을 곱한 값을 넘지 않아야 한다.
      final ceiling = PointRules.adRevenueLow * PointRules.adShare;
      expect(PointRules.adWatch, lessThanOrEqualTo(ceiling));
      expect(PointRules.adWatch * PointRules.adWatchCap, lessThan(PointRules.adRevenueLow * PointRules.adWatchCap));
    });

    test('변동 지급은 남은 포인트 합계에 섞이지 않는다', () {
      // 얼마 들어올지 모르는 값을 배너에 더하면 그 숫자가 거짓말이 된다.
      final only = [dailyMissionById('coupang')!, dailyMissionById('offerwall')!];
      expect(engineWith({}, missions: only).remainToday, 0);
    });

    test('눌러서 바로 받는 미션과 나중에 들어오는 미션이 구분된다', () {
      expect(dailyMissionById('ad')!.instant, isTrue);
      expect(dailyMissionById('coupang')!.instant, isFalse);
      expect(dailyMissionById('offerwall')!.instant, isFalse);

      expect(engineWith({}).stateOf(dailyMissionById('coupang')!).deferred, isTrue);
    });

    test('잠긴 미션은 지급 시점보다 잠긴 이유를 먼저 알린다', () {
      // 키가 없는 빌드에서 '확정 후 지급'이라고 하면 참여할 수 있다는 뜻이 된다.
      final s = engineWith({}).stateOf(dailyMissionById('coupang')!);
      expect(s.locked, isTrue);
      expect(s.statusLabel, 'API 키 등록 필요');
    });
  });

  group('데일리 미션 상태', () {
    test('회차가 있는 미션은 받은 만큼만 완료된다', () {
      final ad = dailyMissionById('ad')!;
      expect(ad.cap, greaterThan(1));

      final s = engineWith({ad.ledgerKey(0)}).stateOf(ad);
      expect(s.claimed, 1);
      expect(s.done, isFalse);
      expect(s.left, ad.cap - 1);

      final all = engineWith({for (var i = 0; i < ad.cap; i++) ad.ledgerKey(i)}).stateOf(ad);
      expect(all.done, isTrue);
      expect(all.left, 0);
    });

    test('회차 키는 서로 겹치지 않는다', () {
      final ad = dailyMissionById('ad')!;
      final keys = {for (var i = 0; i < ad.cap; i++) ad.ledgerKey(i)};
      expect(keys.length, ad.cap);
    });
  });

  group('홈에 올리는 미션', () {
    // 제휴 키가 없는 빌드에서는 지금 세 미션이 전부 잠긴다. 그래서 정렬 규칙은
    // 자체 재원(inapp) 미션을 끼워 넣어 확인한다 — 되살렸을 때의 동작이기도 하다.
    final revived = [
      dailyMissionById('firstpost')!, // 1회성 100P
      dailyMissionById('quiz')!, //      매일 20P
      dailyMissionById('attend')!, //    매일 10P
    ];

    test('잠긴 제휴 미션은 홈에 올리지 않는다', () {
      for (final s in engineWith({}).forHome()) {
        expect(s.locked, isFalse, reason: '${s.m.title}은 아직 연동 전인데 홈에 올라왔다');
      }
    });

    test('매일 되는 미션이 1회성보다 먼저 온다', () {
      // 포인트만으로 줄을 세우면 '첫 부탁 올리기'(100P)가 늘 위에 붙어서
      // 매일 들르는 사람에게 어제와 같은 화면이 된다.
      final rows = engineWith({}, missions: revived).forHome(take: 99);
      expect(rows.map((s) => s.m.id), ['quiz', 'attend', 'firstpost']);
    });

    test('다 받으면 홈 목록이 빈다', () {
      final claimed = {
        for (final m in revived)
          for (var i = 0; i < m.cap; i++) m.ledgerKey(i),
      };
      expect(engineWith(claimed, missions: revived).forHome(), isEmpty);
      expect(engineWith(claimed, missions: revived).remainToday, 0);
    });
  });

  group('미션 공급원', () {
    test('모든 미션의 공급원이 목록에 있다', () {
      final ids = {for (final p in missionProviders) p.id};
      for (final m in allMissions) {
        expect(ids, contains(m.providerId), reason: '${m.title}의 공급원 ${m.providerId} 누락');
      }
    });

    test('키가 필요한 공급원은 키 이름을 적어 둔다', () {
      for (final p in missionProviders) {
        if (p.status == LinkStatus.needsKey) {
          expect(p.keys, isNotEmpty, reason: '${p.name}에 필요한 dart-define 이름이 비어 있다');
        }
      }
    });

    test('자체 미션은 키 없이도 동작한다', () {
      expect(providerOf('inapp').usable, isTrue);
    });
  });

  group('오늘의 퀴즈', () {
    test('정답 번호가 보기 안에 있다', () {
      for (final q in quizItems) {
        expect(q.answer, inInclusiveRange(0, q.choices.length - 1));
        expect(q.tip, isNotEmpty);
      }
    });

    test('같은 날이면 같은 문제가 나온다', () {
      // 둘 다 한국 시간으로는 9월 18일이다 (UTC+9 → 10시와 19시)
      final a = quizOfDay(DateTime.utc(2026, 9, 18, 1));
      final b = quizOfDay(DateTime.utc(2026, 9, 18, 10));
      expect(a.q, b.q);
    });

    test('날짜가 바뀌면 문제도 바뀐다', () {
      // 한국 시간 기준으로 갈린다 ([RewardLedger.todayKey]와 같은 기준)
      final today = quizOfDay(DateTime.utc(2026, 9, 18, 5));
      final tomorrow = quizOfDay(DateTime.utc(2026, 9, 19, 5));
      expect(today.q, isNot(tomorrow.q));
      expect(RewardLedger.todayKey(DateTime.utc(2026, 9, 18, 5)), '2026-09-18');
    });
  });
}
