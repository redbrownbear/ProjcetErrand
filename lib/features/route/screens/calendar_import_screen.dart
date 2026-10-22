import 'package:flutter/material.dart';

import '../../../core/net/place_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../models/commute_route.dart';
import '../repositories/route_repository.dart';
import '../services/calendar_source.dart';
import 'route_screens.dart';

String _two(int n) => n.toString().padLeft(2, '0');
String _hm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// 일정 → 동선 초안. 도착 시각에 맞춰 한 시간 전부터 이동한다고 보고, 그 요일로 채운다
RouteDraft draftFromSlot(CalendarSlot s, {RoutePoint? to}) {
  final arrive = s.start;
  final leave = arrive.subtract(const Duration(hours: 1));
  final sameDay = leave.day == arrive.day;
  return RouteDraft(
    name: '일정',
    to: to,
    days: [arrive.weekday],
    start: sameDay ? _hm(leave) : '00:00',
    end: _hm(arrive) == '00:00' ? '00:30' : _hm(arrive),
  );
}

/// 내 동선 › 캘린더에서 찾기 (A14). 폰 캘린더의 다가오는 일정 중 장소가 있는 것만 보여 주고,
/// 하나를 고르면 동선 입력 화면에 도착 · 요일 · 시간을 채워 확인받는다.
/// 일정의 제목 · 참석자는 읽지 않고(시간 · 장소만 꺼냄), 캘린더 내용은 어디에도 저장하지 않는다.
class CalendarImportScreen extends StatefulWidget {
  final RouteRepository repo;
  final int count;
  final CalendarSource source;
  const CalendarImportScreen({super.key, required this.repo, this.count = 0, this.source = const DeviceCalendarSource()});

  @override
  State<CalendarImportScreen> createState() => _CalendarImportScreenState();
}

class _CalendarImportScreenState extends State<CalendarImportScreen> {
  CalendarAccess? access;
  List<CalendarSlot>? slots;
  bool loading = false;
  String? note;

  Future<void> _allow() async {
    setState(() => loading = true);
    final a = await widget.source.request();
    final list = a == CalendarAccess.granted ? await widget.source.upcoming() : const <CalendarSlot>[];
    if (!mounted) return;
    setState(() {
      access = a;
      slots = list;
      loading = false;
    });
  }

  /// 장소 글자를 좌표로 — 장소 검색 키가 있으면 첫 결과, 없거나 못 찾으면 직접 고르기
  Future<void> _pick(CalendarSlot s) async {
    RoutePoint? to;
    const api = NaverLocalApi();
    if (api.ready) {
      setState(() => note = '"${s.location}" 위치를 찾는 중이에요');
      try {
        final found = await api.search(s.location, display: 1);
        if (found.isNotEmpty) to = RoutePoint.at(s.location, found.first.lat, found.first.lon);
      } catch (_) {}
    }
    if (!mounted) return;
    if (to == null) {
      final picked = await showPlacePicker(context, title: '"${s.location}"은 어디예요?', sub: '약 1km 칸으로만 저장해요');
      if (picked == null || !mounted) {
        setState(() => note = null);
        return;
      }
      to = RoutePoint.at(s.location, picked.lat, picked.lng);
    }
    setState(() => note = null);
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => RouteEditScreen(repo: widget.repo, count: widget.count, draft: draftFromSlot(s, to: to))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: '캘린더에서 동선 찾기',
      bottom: access == null
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: BigButton(label: loading ? '확인하는 중…' : '캘린더 읽기 허용', onTap: loading ? null : _allow),
            )
          : null,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            '앞으로 2주 동안의 일정 중 장소가 적힌 것만 보여 드려요. 고른 일정의 장소 · 요일 · 시간으로 동선을 채우고, 저장 전에 확인할 수 있어요.',
            style: AppType.meta.copyWith(fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
            child: Text(
              '· 일정 제목 · 참석자 · 메모는 읽지 않아요(시간과 장소만)\n· 캘린더 내용은 어디에도 저장하지 않아요. 저장되는 건 확인한 동선(약 1km 칸)뿐이에요\n· 허용은 휴대폰 설정에서 언제든 끌 수 있어요',
              style: AppType.meta.copyWith(height: 1.6, color: AppColors.ink2),
            ),
          ),
          const SizedBox(height: 14),
          if (note != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(note!, style: AppType.meta)),
          ..._body(),
        ],
      ),
    );
  }

  List<Widget> _body() {
    switch (access) {
      case null:
        return const [];
      case CalendarAccess.unsupported:
        return [_center('이 기기에서는 캘린더를 읽을 수 없어요.\n휴대폰 앱에서 써 주세요.')];
      case CalendarAccess.denied:
        return [_center('캘린더 읽기가 허용되지 않았어요.\n휴대폰 설정 › 앱 › 겸사겸사 › 권한에서 캘린더를 켜 주세요.')];
      case CalendarAccess.granted:
        final list = slots ?? const [];
        if (list.isEmpty) return [_center('앞으로 2주 안에 장소가 적힌 일정이 없어요.')];
        return [
          for (final s in list)
            Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.event_outlined, color: AppColors.ink2),
                title: Text(s.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body.copyWith(fontWeight: AppType.w700)),
                subtitle: Text(
                  '${s.start.month}.${s.start.day} (${CommuteRoute.dayNames[s.start.weekday - 1]}) ${_hm(s.start)}~${_hm(s.end)}',
                  style: AppType.meta,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                onTap: () => _pick(s),
              ),
            ),
        ].expand((w) => [w, const SizedBox(height: 8)]).toList();
    }
  }

  Widget _center(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Text(t, textAlign: TextAlign.center, style: AppType.meta.copyWith(fontSize: 13.5, height: 1.6)),
  );
}
