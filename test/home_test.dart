import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/benefits/models/attendance.dart';
import 'package:gyeomsa/features/benefits/widgets/attendance_card.dart';
import 'package:gyeomsa/features/errand/navigation/errand_actions.dart';
import 'package:gyeomsa/features/errand/repositories/errand_repository.dart';
import 'package:gyeomsa/features/errand/screens/home_content.dart';

/// 홈은 기획 시안 v33(`겸사겸사_v33.html`)을 따른다.
/// 부탁하기 · 돈벌기 두 갈래가 기준 폰 폭에서 넘치지 않는지와, 진입점이 제자리에 있는지를 본다.
Widget _home({List<String>? log}) {
  final items = LocalErrandRepository().fetchSeedItems();
  final actions = ErrandActions(
    grabbed: const [], onGrab: (_) {}, onOffer: (_, _, _) {}, offers: const {},
    isSaved: (_) => false, toggleSave: (_) {},
  );
  return MaterialApp(
    home: Scaffold(
      body: HomeContent(
        items: items, scope: '서울 서초구', actions: actions, points: 3200, steps: 6430,
        monthEarn: 84500, coupons: const [], doneMissions: const [],
        isClaimed: (k, {daily = true}) => false,
        earn: (a, l, {required key, daily = true}) async {},
        redeem: (_) {}, useCoupon: (_) {}, completeMission: (_) {}, flash: (_) {},
        goPay: () {}, goProfile: () {},
        goPost: () => log?.add('post'),
        goPostCat: (c) => log?.add('post:$c'),
        goPostSea: () => log?.add('post:sea'),
        goOverseasTab: () => log?.add('tab:os'),
        goSideTab: (s) => log?.add('tab:side$s'),
        goPointsHub: () {}, activeCount: 0, goActivity: () {},
        openJobPost: () {},
      ),
    ),
  );
}

void main() {
  testWidgets('부탁하기 — 겸이 카드와 자주 하는 부탁이 넘침 없이 그려진다', (tester) async {
    tester.view.physicalSize = const Size(375, 2600); // 홈 전체를 한 번에 그린다
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_home());
    await tester.pump();

    expect(find.text('가는 길에, 하나 더'), findsOneWidget);
    expect(find.text('이런 것도 부탁해도 돼요'), findsOneWidget);
    expect(find.text('자주 하는 부탁'), findsOneWidget);
    for (final s in ['동네 부탁', '해외 부탁', '단기알바']) {
      expect(find.text(s), findsWidgets, reason: '주요 서비스 $s 누락');
    }
    // 미션·공동구매는 바로가기 한 곳씩만 둔다.
    expect(find.text('미션'), findsOneWidget);
    expect(find.text('공동구매'), findsOneWidget);
    expect(find.text('우리 동네 제휴 가게'), findsOneWidget);
    // 걷기는 재원이 없어 화면에서 내렸다. (코드는 남아 있다 — WalkScreen·parkedAds)
    expect(find.textContaining('걷기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('자주 하는 부탁을 누르면 그 종류로 부탁 쓰기가 열린다', (tester) async {
    tester.view.physicalSize = const Size(375, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final log = <String>[];
    await tester.pumpWidget(_home(log: log));
    await tester.pump();

    await tester.tap(find.text('줄서기'));
    await tester.tap(find.text('공동구매'));
    expect(log, ['post:line', 'tab:side1']);
  });

  testWidgets('돈벌기 — 이번 달 번 금액과 내 주변 부탁 목록이 나온다', (tester) async {
    tester.view.physicalSize = const Size(375, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_home());
    await tester.pump();
    await tester.tap(find.text('돈벌기'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('누구나 할 수 있는 부업'), findsOneWidget);
    expect(find.text('이번 달 내가 번 금액'), findsOneWidget);
    expect(find.textContaining('84,500', findRichText: true), findsOneWidget);
    expect(find.text('지금 내 주변 부탁'), findsOneWidget);
    expect(find.text('부탁 전체 보기'), findsOneWidget);
    expect(find.text('미션·공구로 더 벌기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('출석 카드 — 오늘 받을 포인트와 이번 달 일수를 보여준다', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // 9월 15~20일 연속 출석 → 오늘(21일)이 7일째라 연속 보너스가 붙는다
    const attendance = Attendance(
      days: {'2026-09-15', '2026-09-16', '2026-09-17', '2026-09-18', '2026-09-19', '2026-09-20'},
      today: '2026-09-21',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AttendanceCard(attendance: attendance, onCheckIn: () {})),
    ));
    await tester.pump();

    expect(attendance.streak, 6);
    expect(attendance.todayReward, AttendRules.daily + AttendRules.streakBonus);
    expect(find.text('+11P 받기'), findsOneWidget);
    expect(find.textContaining('6일'), findsWidgets);
  });
}
