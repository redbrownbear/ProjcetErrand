import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/route/models/commute_route.dart';
import 'package:gyeomsa/features/route/repositories/route_repository.dart';
import 'package:gyeomsa/features/route/screens/calendar_import_screen.dart';
import 'package:gyeomsa/features/route/services/calendar_source.dart';

class _Fake extends CalendarSource {
  final CalendarAccess access;
  final List<CalendarSlot> slots;
  const _Fake(this.access, [this.slots = const []]);
  @override
  Future<CalendarAccess> request() async => access;
  @override
  Future<List<CalendarSlot>> upcoming({int days = 14}) async => slots;
}

/// A14 캘린더 → 동선: 시간 · 장소만 꺼내고, 고르면 동선 입력에 채운다
void main() {
  test('일정 하나 → 시간 · 장소만, 장소 없음 · 종일 일정은 버림', () {
    final s = slotOf(start: DateTime(2026, 10, 27, 19), end: DateTime(2026, 10, 27, 21), location: '  강남역   11번 출구 ')!;
    expect(s.location, '강남역 11번 출구');
    expect(slotOf(start: DateTime(2026, 10, 27, 19), location: ''), isNull);
    expect(slotOf(start: DateTime(2026, 10, 27), location: '집', allDay: true), isNull);
    expect(slotOf(location: '집'), isNull);
  });

  test('같은 일정은 하나만, 이른 순', () {
    final a = CalendarSlot(start: DateTime(2026, 10, 28, 9), end: DateTime(2026, 10, 28, 10), location: 'A');
    final b = CalendarSlot(start: DateTime(2026, 10, 27, 9), end: DateTime(2026, 10, 27, 10), location: 'B');
    expect(sortSlots([a, b, a]).map((s) => s.location), ['B', 'A']);
  });

  test('동선 초안: 그 요일 · 도착 한 시간 전부터', () {
    final d = draftFromSlot(CalendarSlot(start: DateTime(2026, 10, 27, 19, 30), end: DateTime(2026, 10, 27, 21), location: '강남역'));
    expect(d.days, [DateTime.tuesday]);
    expect(d.start, '18:30');
    expect(d.end, '19:30');
    final early = draftFromSlot(CalendarSlot(start: DateTime(2026, 10, 27, 0, 20), end: DateTime(2026, 10, 27, 1), location: 'x'));
    expect(early.start, '00:00');
  });

  Future<void> phone(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump();
  }

  testWidgets('허용하면 장소 있는 일정 목록', (tester) async {
    final slot = CalendarSlot(start: DateTime(2026, 10, 27, 19), end: DateTime(2026, 10, 27, 21), location: '강남역');
    await phone(tester, CalendarImportScreen(repo: const RouteRepository('u1'), source: _Fake(CalendarAccess.granted, [slot])));
    expect(find.textContaining('제목 · 참석자 · 메모는 읽지 않아요'), findsOneWidget);
    await tester.tap(find.text('캘린더 읽기 허용'));
    await tester.pumpAndSettle();
    expect(find.text('강남역'), findsOneWidget);
    expect(find.text('10.27 (${CommuteRoute.dayNames[1]}) 19:00~21:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('거절하면 설정 안내', (tester) async {
    await phone(tester, const CalendarImportScreen(repo: RouteRepository('u1'), source: _Fake(CalendarAccess.denied)));
    await tester.tap(find.text('캘린더 읽기 허용'));
    await tester.pumpAndSettle();
    expect(find.textContaining('허용되지 않았어요'), findsOneWidget);
  });
}
