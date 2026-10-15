import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gyeomsa/features/profile/models/trust_level.dart';
import 'package:gyeomsa/features/profile/models/user_profile.dart';
import 'package:gyeomsa/features/profile/screens/me_view.dart';

/// 마이 화면은 시안 v33의 `#myRoot`(프로필 → 숫자 세 칸 → 지갑 → 메뉴 묶음)를 따른다.
/// 로그인 상태의 화면이 기준 폰 폭에서 넘치지 않는지와, 원·포인트를 섞지 않는지를 본다.
Widget _me({List<String>? log}) {
  return MaterialApp(
    home: Scaffold(
      body: MeView(
        profile: const UserProfile(uid: 'u1', email: 'neighbor@example.com', nickname: '서초동 이웃', region: '서울 서초구', points: 3200),
        stats: const ProfileStats(completed: 12, requested: 5, monthEarnedCash: 44000, saved: 2, applied: 3),
        trust: const TrustLevel(40),
        points: 3200,
        payBalance: 44000,
        coupons: const [],
        useCoupon: (_) {},
        goPointsHub: () {},
        goPay: () => log?.add('pay'),
        goAttendance: () => log?.add('attendance'),
        freeLeft: 3,
        isLoggedIn: true,
        onLogin: () {},
        onOpenSaved: () {},
        onOpenApplied: () {},
        onOpenMine: () {},
        onOpenActivity: () {},
        onRename: (_) async {},
      ),
    ),
  );
}

void main() {
  testWidgets('마이 — 로그인 화면이 기준 폰 폭에서 넘침 없이 그려진다', (tester) async {
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_me());
    await tester.pump();

    expect(find.text('서초동 이웃'), findsOneWidget);
    expect(find.text('내 지갑'), findsOneWidget);
    // 겸사페이(원)와 포인트(P)는 더하지 않고 따로 적는다.
    expect(find.textContaining('44,000', findRichText: true), findsWidgets);
    expect(find.text('3,200P'), findsOneWidget);
    expect(find.textContaining('47,200', findRichText: true), findsNothing);
    for (final s in ['나의 활동', '돈 · 혜택', '계정']) {
      expect(find.text(s), findsOneWidget, reason: '메뉴 묶음 $s 누락');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('지갑 버튼이 겸사페이와 내역·출석으로 이어진다', (tester) async {
    tester.view.physicalSize = const Size(375, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final log = <String>[];
    await tester.pumpWidget(_me(log: log));
    await tester.pump();

    await tester.tap(find.text('출금·충전'));
    await tester.tap(find.text('내역·출석'));
    expect(log, ['pay', 'attendance']);
  });
}
