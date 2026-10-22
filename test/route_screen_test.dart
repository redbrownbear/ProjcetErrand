import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/route/models/commute_route.dart';
import 'package:gyeomsa/features/route/repositories/route_repository.dart';
import 'package:gyeomsa/features/route/screens/route_screens.dart';

/// A08 동선 입력 화면: 폰 폭에서 깨지지 않고, 출발 · 도착을 고르기 전엔 저장할 수 없다
void main() {
  Future<void> phone(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump();
  }

  testWidgets('새 동선: 기본값(출근 · 평일 · 08~09시 · 대중교통 · 500m), 칩으로 바꾸기', (tester) async {
    await phone(tester, const RouteEditScreen(repo: RouteRepository('u1')));
    expect(find.text('동선 추가'), findsOneWidget);
    expect(find.text('출발 고르기'), findsOneWidget);
    expect(find.text('08:00 출발'), findsOneWidget);
    await tester.tap(find.text('주말'));
    await tester.tap(find.text('자전거'));
    await tester.tap(find.text('2km'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('고치기: 저장된 동선 값을 그대로 보여 준다', (tester) async {
    const r = CommuteRoute(
      id: 'r1',
      name: '퇴근',
      from: RoutePoint(label: '강남역', cell6: 'wydm9x'),
      to: RoutePoint(label: '방배역', cell6: 'wydm9q'),
      days: [1, 3, 5],
      start: '18:30',
      end: '19:30',
      mode: 'walk',
      radiusM: 1000,
    );
    await phone(tester, const RouteEditScreen(repo: RouteRepository('u1'), route: r));
    expect(find.text('동선 고치기'), findsOneWidget);
    expect(find.text('강남역'), findsOneWidget);
    expect(find.text('18:30 출발'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
