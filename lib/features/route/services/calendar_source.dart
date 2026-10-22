import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/stable_sort.dart';

/// 폰 캘린더 일정 하나에서 꺼낸 것(A14) — **시간과 장소만**. 제목 · 참석자 · 메모는 읽어도 바로 버린다.
class CalendarSlot {
  final DateTime start;
  final DateTime end;
  final String location;
  const CalendarSlot({required this.start, required this.end, required this.location});
}

/// 캘린더를 읽은 결과
enum CalendarAccess { granted, denied, unsupported }

/// 폰 캘린더 읽기. 화면 테스트에서는 가짜로 바꿔 끼운다
abstract class CalendarSource {
  const CalendarSource();

  /// 읽기 권한을 묻는다(이미 있으면 바로 granted)
  Future<CalendarAccess> request();

  /// 오늘부터 [days]일 안, 장소가 적힌 일정만(종일 일정 제외), 이른 순
  Future<List<CalendarSlot>> upcoming({int days = 14});
}

/// iOS EventKit / Android 캘린더(device_calendar 패키지)
class DeviceCalendarSource extends CalendarSource {
  const DeviceCalendarSource();

  static bool get supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<CalendarAccess> request() async {
    if (!supported) return CalendarAccess.unsupported;
    try {
      final plugin = DeviceCalendarPlugin();
      var ok = await plugin.hasPermissions();
      if (ok.data != true) ok = await plugin.requestPermissions();
      return ok.data == true ? CalendarAccess.granted : CalendarAccess.denied;
    } catch (e) {
      debugPrint('캘린더 권한 확인 실패: $e');
      return CalendarAccess.denied;
    }
  }

  @override
  Future<List<CalendarSlot>> upcoming({int days = 14}) async {
    if (!supported) return const [];
    final plugin = DeviceCalendarPlugin();
    final now = DateTime.now();
    final params = RetrieveEventsParams(startDate: now, endDate: now.add(Duration(days: days)));
    final out = <CalendarSlot>[];
    try {
      final cals = await plugin.retrieveCalendars();
      for (final c in cals.data ?? const <Calendar>[]) {
        final id = c.id;
        if (id == null) continue;
        final events = await plugin.retrieveEvents(id, params);
        for (final e in events.data ?? const <Event>[]) {
          final slot = slotOf(start: e.start, end: e.end, location: e.location, allDay: e.allDay ?? false);
          if (slot != null) out.add(slot);
        }
      }
    } catch (e) {
      debugPrint('캘린더 읽기 실패: $e');
    }
    return sortSlots(out);
  }
}

/// 일정 하나 → 시간 · 장소만. 장소 없음 · 종일 · 시각 없음은 버린다
CalendarSlot? slotOf({DateTime? start, DateTime? end, String? location, bool allDay = false}) {
  final place = location?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
  if (allDay || start == null || place.isEmpty) return null;
  final s = start.toLocal();
  final e = (end ?? start.add(const Duration(hours: 1))).toLocal();
  return CalendarSlot(start: s, end: e.isBefore(s) ? s : e, location: place.length > 40 ? place.substring(0, 40) : place);
}

/// 이른 순 · 같은 시각 · 같은 장소는 하나만(캘린더 여러 개에 같은 일정이 있을 때)
List<CalendarSlot> sortSlots(List<CalendarSlot> all) {
  final seen = <String>{};
  final out = [
    for (final s in all)
      if (seen.add('${s.start.millisecondsSinceEpoch}|${s.location}')) s,
  ];
  out.sortStable((a, b) => a.start.compareTo(b.start));
  return out;
}
