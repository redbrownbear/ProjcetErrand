import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/benefits/screens/benefits_view.dart';
import 'package:gyeomsa/features/errand/navigation/errand_actions.dart';
import 'package:gyeomsa/features/errand/repositories/errand_repository.dart';

/// 부업 탭은 한때 재원 없는 포인트 약속으로 가득했다.
///
/// 출석·광고·프로필·친구초대를 `benefit:*` 키로 따로 굴렸고, '오늘 최대 +8,430P'
/// 같은 근거 없는 숫자와 '도쿄에서 14개' 같은 지어낸 수치가 섞여 있었다.
/// 화면을 고치다 보면 이런 게 슬그머니 돌아오기 쉬워서, 없다는 사실을 못 박는다.
Widget _benefits() {
  final items = LocalErrandRepository().fetchSeedItems();
  final actions = ErrandActions(
    grabbed: const [], onGrab: (_) {}, onOffer: (_, _, _) {}, offers: const {},
    isSaved: (_) => false, toggleSave: (_) {},
  );
  return MaterialApp(
    home: Scaffold(
      body: BenefitsView(
        points: 3200,
        coupons: const [],
        items: items,
        scope: '서울 서초구',
        actions: actions,
        monthEarn: 42000,
        freeLeft: 2,
        doneMissions: const [],
        earn: (a, l, {required key, daily = true}) async {},
        isClaimed: (k, {daily = true}) => false,
        redeem: (_) {},
        useCoupon: (_) {},
        completeMission: (_) {},
        goPointsHub: () {},
        flash: (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('재원 없는 자체 포인트 미션이 없다', (tester) async {
    tester.view.physicalSize = const Size(375, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_benefits());
    await tester.pump();

    // 전부 제휴사가 돈을 대지 않는 자체 지급이었다
    for (final gone in [
      '🚶 걸어서 벌기',
      '📅 연속 출석하고 벌기',
      '👥 친구랑 벌기',
      '오늘 받을 수 있는 포인트',
      '오늘의 수익 기회',
    ]) {
      expect(find.text(gone), findsNothing, reason: '$gone — 재원 없는 섹션이 돌아왔다');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('지어낸 숫자가 없다', (tester) async {
    tester.view.physicalSize = const Size(375, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_benefits());
    await tester.pump();

    // '최대 +8,430P'는 어디서도 계산되지 않는 값이었다
    expect(find.textContaining('8,430'), findsNothing);
    // 해외 부탁 개수는 목록에서 세야 한다
    expect(find.textContaining('도쿄'), findsNothing);
    // 셸이 늘 0을 넘기던 칸
    expect(find.text('이번 달 적립'), findsNothing);
  });

  testWidgets('실제 값이 있는 것은 그대로 보인다', (tester) async {
    tester.view.physicalSize = const Size(375, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_benefits());
    await tester.pump();

    expect(find.text('내 포인트'), findsOneWidget);
    expect(find.text('3,200P'), findsOneWidget);
    expect(find.text('이번 달 겸사 수익'), findsOneWidget);
    expect(find.text('+42,000원'), findsOneWidget);
    // freeLeft는 거래 기록에서 계산된 실제 값이다
    expect(find.textContaining('남은 무료 거래 2회'), findsOneWidget);
  });
}
