import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/benefits/models/attendance.dart';
import 'package:gyeomsa/features/errand/navigation/errand_actions.dart';
import 'package:gyeomsa/features/errand/repositories/errand_repository.dart';
import 'package:gyeomsa/features/errand/screens/home_content.dart';
import 'package:gyeomsa/features/profile/models/trust_level.dart';

/// 홈은 기획 시안(v9 구조 + `gyumsa-refined`의 인사말·출석·소식)을 따른다.
/// 진입점이 한 곳씩만 있는지와 기준 폰 폭에서 레이아웃이 넘치지 않는지를 확인한다.
Widget _home({Attendance? attendance}) {
  final items = LocalErrandRepository().fetchSeedItems();
  final actions = ErrandActions(
    grabbed: const [], onGrab: (_) {}, onOffer: (_, _, _) {}, offers: const {},
    isSaved: (_) => false, toggleSave: (_) {},
  );
  return MaterialApp(
    home: Scaffold(
      body: HomeContent(
        items: items, scope: '서울 서초구', actions: actions, points: 3200, steps: 6430,
        payBalance: 0, trust: const TrustLevel(0), goPay: () {}, goProfile: () {},
        coupons: const [], doneMissions: const [],
        isClaimed: (k, {daily = true}) => false,
        openRegion: () {},
        earn: (a, l, {required key, daily = true}) async {},
        redeem: (_) {}, useCoupon: (_) {}, completeMission: (_) {}, flash: (_) {},
        goPointsHub: () {}, activeCount: 0, goActivity: () {},
        attendance: attendance ?? const Attendance(days: {}, today: '2026-09-21'),
        checkIn: () {},
        openJobPost: () {},
      ),
    ),
  );
}

void main() {
  testWidgets('홈 구조가 기준 폰 폭에서 넘침 없이 그려진다', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_home());
    await tester.pump();

    // 인사말 · 출석 달력 · 소식
    expect(find.text('오늘도, 겸사겸사'), findsOneWidget);
    expect(find.text('오늘도\n반가워요!'), findsOneWidget);
    expect(find.text('겸사겸사 소식'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('홈 전체 — 누적 수익·주요 서비스·숏컷이 한 곳씩 있다', (tester) async {
    tester.view.physicalSize = const Size(375, 3000); // 홈 전체를 한 번에 그린다
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_home());
    await tester.pump();

    expect(find.text('나의 목표 금액'), findsOneWidget);
    for (final s in ['동네 부탁', '해외 부탁', '단기알바']) {
      expect(find.text(s), findsWidgets, reason: '주요 서비스 $s 누락');
    }
    // 걷기·미션·공동구매는 예전 홈에서 서너 군데씩 있었다. 지금은 숏컷 하나씩만 둔다.
    expect(find.text('공동구매'), findsOneWidget);
    expect(find.text('미션'), findsOneWidget);
    expect(find.text('부탁 전체'), findsWidgets);
    expect(find.text('같이해요'), findsWidgets);
    // 걷기는 '전체'를 펼쳐야만 나온다
    expect(find.textContaining('걷기 혜택'), findsNothing);
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
    await tester.pumpWidget(_home(attendance: attendance));
    await tester.pump();

    expect(attendance.streak, 6);
    expect(attendance.todayReward, AttendRules.daily + AttendRules.streakBonus);
    expect(find.text('+11P 받기'), findsOneWidget);
    expect(find.textContaining('6일'), findsWidgets);
  });
}
