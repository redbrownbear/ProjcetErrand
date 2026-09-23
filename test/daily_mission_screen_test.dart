import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/benefits/data/daily_missions.dart';
import 'package:gyeomsa/features/benefits/data/daily_quiz.dart';
import 'package:gyeomsa/features/benefits/models/daily_mission.dart';
import 'package:gyeomsa/features/benefits/screens/daily_mission_screen.dart';
import 'package:gyeomsa/features/benefits/services/mission_engine.dart';
import 'package:gyeomsa/features/benefits/services/mission_runner.dart';

/// 적립 요청 한 건
typedef _Earned = ({int amount, String label, String key});

void main() {
  late List<_Earned> earned;
  late Set<String> claimed;
  late List<String> toasts;

  MissionRunner runner() => MissionRunner(
        earn: (amount, label, {required key, daily = true}) async {
          earned.add((amount: amount, label: label, key: key));
          claimed.add(key);
        },
        flash: toasts.add,
        scope: '서울 서초구',
        goWalk: () {},
        goProfile: () {},
        goPost: () {},
        goList: () {},
      );

  Widget screen({List<DailyMission>? missions}) {
    final engine = MissionEngine(
      (key, {daily = true}) => claimed.contains(key),
      missions: missions ?? dailyMissions,
    );
    return MaterialApp(
      home: DailyMissionScreen(runner: runner(), engine: engine, goEarnHub: () {}),
    );
  }

  Future<void> pump(WidgetTester tester, {List<DailyMission>? missions}) async {
    tester.view.physicalSize = const Size(375, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(screen(missions: missions));
    await tester.pump();
  }

  setUp(() {
    earned = [];
    claimed = {};
    toasts = [];
  });

  group('서비스 중인 미션 세 개', () {
    testWidgets('광고·쿠팡·오퍼월이 그려지고 빈 구역은 나오지 않는다', (tester) async {
      await pump(tester);

      expect(find.text('오늘 할 수 있는 것'), findsOneWidget);
      expect(find.text('광고 영상 보고 적립'), findsOneWidget);
      expect(find.text('오늘의 특가로 주문하기'), findsOneWidget);
      expect(find.text('오퍼월에서 골라 하기'), findsOneWidget);

      // 1회성 미션은 전부 내려 둬서 그 구역 자체가 없어야 한다
      expect(find.text('한 번만 받는 것'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('재원 없는 미션은 목록에 없다', (tester) async {
      await pump(tester);

      for (final title in ['출석 체크', '오늘의 퀴즈', '동네 매장 체크인', '오늘 3,000보 걷기']) {
        expect(find.text(title), findsNothing, reason: '$title은 재원이 없어 내려 뒀다');
      }
    });

    testWidgets('잠긴 동안에는 지급 기준 대신 잠긴 이유를 보여 준다', (tester) async {
      await pump(tester);

      // 참여할 수 없는 미션에 '주문액의 1%'를 띄우면 지금 되는 것처럼 읽힌다
      expect(find.text('주문액의 1%'), findsNothing);
      expect(find.text('쿠팡 파트너스 · API 키 등록 필요'), findsOneWidget);
    });

    testWidgets('연동되면 금액 대신 지급 기준이 배지에 뜬다', (tester) async {
      // 변동 지급 미션이 지금은 전부 잠겨 있어, 자체 재원으로 같은 모양을 만들어
      // 배지 렌더링 경로를 확인한다. 연동이 끝나면 이 모습으로 보인다.
      const rateMission = DailyMission(
        id: 'rate-sample', icon: '🛒', title: '정률 지급 미션', sub: '주문액에 비례',
        points: 0, providerId: 'inapp', action: MissionAction.deal,
        payout: PayoutKind.rate, rate: 0.01, instant: false, verify: '구매 확정',
      );
      const partnerMission = DailyMission(
        id: 'partner-sample', icon: '🎁', title: '제휴사 지급 미션', sub: '캠페인마다 단가가 다름',
        points: 0, providerId: 'inapp', action: MissionAction.offerwall,
        payout: PayoutKind.partner, instant: false, verify: '제휴사 콜백',
      );

      await pump(tester, missions: [rateMission, partnerMission]);

      expect(find.text('주문액의 1%'), findsOneWidget);
      expect(find.text('캠페인마다 다름'), findsOneWidget);
      expect(find.text('확정 후 지급'), findsNWidgets(2));
    });

    testWidgets('연동 전에는 전부 준비 중이고 눌러도 적립되지 않는다', (tester) async {
      await pump(tester);

      expect(find.text('준비 중'), findsNWidgets(3));
      expect(find.text('미션 준비 중'), findsOneWidget);

      await tester.tap(find.text('오늘의 특가로 주문하기'));
      await tester.pump();

      expect(earned, isEmpty);
      expect(toasts.single, contains('쿠팡 파트너스'));
    });
  });

  group('내려 둔 미션은 되살릴 수 있다', () {
    // 실행부와 검증 코드가 그대로 남아 있는지 확인한다.
    // 재원이 생겨 목록으로 올렸을 때 바로 도는지가 이 테스트의 관심사다.
    final revived = [dailyMissionById('quiz')!, dailyMissionById('attend')!];

    testWidgets('퀴즈를 맞히면 포인트가 적립되고 완료로 바뀐다', (tester) async {
      await pump(tester, missions: revived);

      await tester.tap(find.text('오늘의 퀴즈'));
      await tester.pumpAndSettle();

      final quiz = quizOfDay();
      expect(find.text(quiz.q), findsOneWidget);

      await tester.tap(find.text(quiz.choices[quiz.answer]));
      await tester.pumpAndSettle();

      expect(earned.single.key, 'daily:quiz');
      expect(earned.single.amount, greaterThan(0));
      expect(find.text('완료'), findsWidgets);
    });

    testWidgets('틀리면 적립 없이 해설만 알려 준다', (tester) async {
      await pump(tester, missions: revived);

      await tester.tap(find.text('오늘의 퀴즈'));
      await tester.pumpAndSettle();

      final quiz = quizOfDay();
      final wrong = (quiz.answer + 1) % quiz.choices.length;
      await tester.tap(find.text(quiz.choices[wrong]));
      await tester.pumpAndSettle();

      expect(earned, isEmpty);
      expect(toasts.single, contains(quiz.tip));
    });

    testWidgets('홈에서 이미 출석했으면 두 번 받을 수 없다', (tester) async {
      claimed.add('benefit:attend');
      await pump(tester, missions: revived);

      await tester.tap(find.text('출석 체크'));
      await tester.pump();

      expect(earned, isEmpty);
      expect(toasts.single, contains('이미 받았어요'));
    });
  });
}
