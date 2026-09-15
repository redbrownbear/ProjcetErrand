import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/errand/navigation/errand_actions.dart';
import 'package:gyeomsa/features/errand/repositories/errand_repository.dart';
import 'package:gyeomsa/features/errand/screens/home_content.dart';

/// 홈은 기획 시안 v9 구조를 따른다. 진입점이 한 곳씩만 있는지와
/// 기준 폰 폭에서 레이아웃이 넘치지 않는지를 확인한다.
Widget _home() {
  final items = LocalErrandRepository().fetchSeedItems();
  final actions = ErrandActions(
    grabbed: const [], onGrab: (_) {}, onOffer: (_, _, _) {}, offers: const {},
    isSaved: (_) => false, toggleSave: (_) {},
  );
  return MaterialApp(
    home: Scaffold(
      body: HomeContent(
        items: items, scope: '서울 서초구', actions: actions, points: 3200, steps: 6430,
        earnedCash: 0, coupons: const [], doneMissions: const [],
        isClaimed: (k, {daily = true}) => false,
        openRegion: () {},
        earn: (a, l, {required key, daily = true}) async {},
        redeem: (_) {}, useCoupon: (_) {}, completeMission: (_) {}, flash: (_) {},
        goPointsHub: () {}, activeCount: 0, goActivity: () {},
      ),
    ),
  );
}

void main() {
  testWidgets('v9 홈 구조가 기준 폰 폭에서 넘침 없이 그려진다', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_home());
    await tester.pump();

    // 누적 수익 + 목표, 출석, 주요 서비스 3개
    expect(find.text('지금까지 모은 금액'), findsOneWidget);
    expect(find.text('나의 목표 금액'), findsOneWidget);
    expect(find.textContaining('오늘 출석하고'), findsOneWidget);
    for (final s in ['동네 부탁', '해외 부탁', '단기알바']) {
      expect(find.text(s), findsWidgets, reason: '주요 서비스 $s 누락');
    }
    // 숏컷 4개
    for (final s in ['부탁 전체', '미션', '같이해요', '공동구매']) {
      expect(find.text(s), findsWidgets, reason: '숏컷 $s 누락');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('겹치던 진입점이 홈에서 한 곳으로 줄었다', (tester) async {
    tester.view.physicalSize = const Size(375, 2400); // 홈 전체를 한 번에 그린다
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_home());
    await tester.pump();

    // 걷기·미션·공동구매는 예전 홈에서 서너 군데씩 있었다. 지금은 숏컷 하나씩만 둔다.
    expect(find.text('공동구매'), findsOneWidget);
    expect(find.text('미션'), findsOneWidget);
    // 걷기는 '전체'를 펼쳐야만 나온다
    expect(find.textContaining('걷기 혜택'), findsNothing);
  });
}
