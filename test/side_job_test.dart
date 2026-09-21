import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/benefits/data/partner_missions.dart';
import 'package:gyeomsa/features/benefits/models/mission_meta.dart';
import 'package:gyeomsa/features/benefits/screens/side_job_view.dart';
import 'package:gyeomsa/features/errand/navigation/errand_actions.dart';
import 'package:gyeomsa/features/errand/repositories/errand_repository.dart';

/// 부업 탭은 시안(`gyumsa-refined`)의 미션 중심 화면이다.
/// 검색·상태·조건 줄이 기준 폰 폭에서 넘치지 않는지와, 미션 조건 문구가
/// 목록에 그대로 나오는지를 본다.
Widget _view({List<String> done = const []}) {
  final items = LocalErrandRepository().fetchSeedItems();
  final actions = ErrandActions(
    grabbed: const [], onGrab: (_) {}, onOffer: (_, _, _) {}, offers: const {},
    isSaved: (_) => false, toggleSave: (_) {},
  );
  return MaterialApp(
    home: Scaffold(
      body: SideJobView(
        points: 3200, steps: 6430, coupons: const [], items: items, scope: '서울 서초구',
        actions: actions, monthEarn: 0, monthPoints: 0, freeLeft: 3, doneMissions: done,
        earn: (a, l, {required key, daily = true}) async {},
        isClaimed: (k, {daily = true}) => false,
        redeem: (_) {}, useCoupon: (_) {}, completeMission: (_) {},
        goPointsHub: () {}, flash: (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('부업 탭이 기준 폰 폭에서 넘침 없이 그려진다', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_view());
    await tester.pump();

    expect(find.text('오늘은 뭘 해볼까요?'), findsOneWidget);
    expect(find.text('가볍게 시작해요'), findsOneWidget);
    expect(find.text('어떤 부업을 찾으세요?'), findsOneWidget);
    for (final s in ['전체', '참여 중', '적립 완료']) {
      expect(find.text(s), findsWidgets, reason: '상태 탭 $s 누락');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('끝까지 내리면 파트너 안내가 나온다', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_view());
    await tester.pump();

    await tester.dragUntilVisible(
      find.text('겸사겸사와 브랜드 협업'),
      find.byType(ListView),
      const Offset(0, -400),
    );
    expect(find.text('겸사겸사와 브랜드 협업'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('미션 조건 문구 — 구매가 필요한 미션을 목록에서 구분한다', () {
    final shopping = partnerMissions.firstWhere((m) => m.id == 'm5');
    final trial = partnerMissions.firstWhere((m) => m.id == 'm2');
    final blog = partnerMissions.firstWhere((m) => m.cat == 'blog');
    final plain = partnerMissions.firstWhere((m) => m.id == 'm1');

    expect(shopping.costTag, '구매 필요');
    expect(shopping.isFree, isFalse);
    expect(trial.costTag, '구독 조건 확인');
    expect(blog.costTag, '선정형 체험');
    expect(plain.costTag, '구매 없음');
    expect(plain.isFree, isTrue);
    expect(plain.minutes, 3);
    // '방문'·'1~2시간'처럼 분으로 못 읽는 값은 3분 이내 필터에서 빠진다.
    expect(partnerMissions.firstWhere((m) => m.time == '방문').minutes, 999);
  });
}
