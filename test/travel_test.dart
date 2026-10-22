import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/travel/models/travel_plan.dart';
import 'package:gyeomsa/features/travel/repositories/travel_repository.dart';
import 'package:gyeomsa/features/travel/screens/travel_screens.dart';

/// A11 여행 · 출국 일정: 날짜 검사 · 상태 · 정렬, 입력 화면이 폰 폭에서 깨지지 않는다
void main() {
  final today = DateTime(2026, 10, 23);
  TravelPlan plan(String id, DateTime d, DateTime b) => TravelPlan(id: id, cc: 'jp', depart: d, back: b);

  test('날짜 문자열 · 며칠 · 상태', () {
    final p = plan('a', DateTime(2026, 11, 3), DateTime(2026, 11, 7));
    expect(p.toMap()['depart'], '2026-11-03');
    expect(TravelPlan.parseYmd('2026-11-07'), DateTime(2026, 11, 7));
    expect(TravelPlan.parseYmd('11/07'), isNull);
    expect(p.days, 5);
    expect(p.stateOn(today), 'upcoming');
    expect(p.daysLeft(today), 11);
    expect(p.stateOn(DateTime(2026, 11, 7, 23)), 'away');
    expect(p.stateOn(DateTime(2026, 11, 8)), 'past');
  });

  test('저장 전 검사', () {
    expect(plan('', DateTime(2026, 11, 3), DateTime(2026, 11, 3)).problemOn(today), isNull);
    expect(plan('', DateTime(2026, 11, 3), DateTime(2026, 11, 1)).problemOn(today), contains('귀국일'));
    expect(plan('', DateTime(2026, 10, 1), DateTime(2026, 10, 5)).problemOn(today), contains('지난'));
    expect(plan('x', DateTime(2026, 10, 1), DateTime(2026, 10, 5)).problemOn(today, isNew: false), isNull);
    expect(plan('', DateTime(2029, 1, 1), DateTime(2029, 1, 5)).problemOn(today), contains('2년'));
    expect(TravelPlan(id: '', cc: '', depart: today, back: today).problemOn(today), contains('나라'));
  });

  test('정렬: 여행 중 → 다가오는 순 → 지난 여행 최근 순', () {
    final list = [
      plan('past1', DateTime(2026, 8, 1), DateTime(2026, 8, 5)),
      plan('later', DateTime(2026, 12, 20), DateTime(2026, 12, 25)),
      plan('away', DateTime(2026, 10, 20), DateTime(2026, 10, 25)),
      plan('soon', DateTime(2026, 11, 1), DateTime(2026, 11, 2)),
      plan('past2', DateTime(2026, 9, 1), DateTime(2026, 9, 5)),
    ];
    expect(TravelPlan.sorted(list, today).map((p) => p.id), ['away', 'soon', 'later', 'past2', 'past1']);
  });

  testWidgets('추가 화면: 나라를 고르면 도시 칩, 날짜 전엔 저장 못 함', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: TravelEditScreen(repo: const TravelRepository('u1'), today: today)));
    await tester.pump();
    expect(find.text('여행 일정 추가'), findsOneWidget);
    expect(find.text('오사카'), findsNothing);
    await tester.tap(find.text('일본'));
    await tester.pump();
    expect(find.text('오사카'), findsOneWidget);
    await tester.tap(find.text('오사카'));
    await tester.pump();
    expect(find.text('출국일 · 귀국일 고르기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('고치기: 저장된 값을 보여 준다', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final p = TravelPlan(id: 't1', cc: 'vn', city: '다낭', depart: DateTime(2026, 11, 3), back: DateTime(2026, 11, 7), takeAsks: true);
    await tester.pumpWidget(MaterialApp(home: TravelEditScreen(repo: const TravelRepository('u1'), plan: p, today: today)));
    await tester.pump();
    expect(find.text('여행 일정 고치기'), findsOneWidget);
    expect(find.text('11.3 출국 → 11.7 귀국 · 5일'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
