import 'package:flutter/material.dart';

import '../../../core/backend/server_api.dart';
import '../../../core/net/place_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/kit.dart';
import '../../trip/widgets/trip_parts.dart';
import '../data/route_places.dart';
import '../models/commute_route.dart';
import '../repositories/match_repository.dart';
import '../repositories/route_repository.dart';
import 'calendar_import_screen.dart';

/// 마이 › 내 동선 (개발 To-do A08). 정기 동선 목록 · 켜기/끄기 · 고치기 · 지우기, 최대 6개.
/// 등록한 동선은 서버가 약 1km 격자로 바꿔 '내 동선에 맞는 부탁' 추천(A13)에 쓴다. 정확한 좌표는 저장하지 않는다.
class RouteListScreen extends StatefulWidget {
  final String uid;
  final RouteRepository? repo;

  /// '내 동선에 맞는 부탁'을 누르면 그 부탁 상세로(A13)
  final void Function(int requestId)? onOpenRequest;
  final MatchRepository? matches;
  const RouteListScreen({super.key, required this.uid, this.repo, this.onOpenRequest, this.matches});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  // 구독은 화면이 열려 있는 동안 한 번만 연다(다시 그릴 때마다 새로 열지 않게)
  late final RouteRepository r = widget.repo ?? RouteRepository(widget.uid);
  late final Stream<List<CommuteRoute>> routes = r.watch();
  late final MatchRepository matches = widget.matches ?? MatchRepository(widget.uid);
  late final Stream<List<RouteMatch>> matchList = matches.watch();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommuteRoute>>(
      stream: routes,
      builder: (context, snap) {
        final list = snap.data ?? const <CommuteRoute>[];
        final full = list.length >= CommuteRoute.maxRoutes;
        void edit([CommuteRoute? route]) => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => RouteEditScreen(repo: r, route: route, count: list.length)),
        );
        return PageFrame(
          title: '내 동선',
          bottom: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: BigButton(
              label: full ? '동선은 ${CommuteRoute.maxRoutes}개까지예요' : '동선 추가하기',
              onTap: full ? null : () => edit(),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(
                '자주 다니는 길을 적어 두면, 그 길에서 가까운 부탁을 먼저 알려 드려요. '
                '위치는 약 1km 칸으로만 저장하고 실시간 위치는 모으지 않아요.',
                style: AppType.meta.copyWith(fontSize: 13, height: 1.55),
              ),
              if (!full)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: LineButton(
                    label: '캘린더 일정에서 동선 찾기',
                    height: 40,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => CalendarImportScreen(repo: r, count: list.length)),
                    ),
                  ),
                ),
              if (list.isNotEmpty) _MatchList(repo: matches, stream: matchList, onOpen: widget.onOpenRequest),
              const SizedBox(height: 14),
              if (snap.connectionState == ConnectionState.waiting && list.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Text(
                    '아직 등록한 동선이 없어요.\n출근길 · 퇴근길부터 적어 보세요.',
                    textAlign: TextAlign.center,
                    style: AppType.meta.copyWith(fontSize: 13.5, height: 1.6),
                  ),
                )
              else
                for (final route in list)
                  _RouteCard(
                    route: route,
                    onEdit: () => edit(route),
                    onToggle: (on) => r.setActive(route.id, on),
                    onDelete: () => r.delete(route.id),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// 내 동선에 맞는 부탁(서버가 부탁이 올라올 때 계산해 둔 것)
class _MatchList extends StatelessWidget {
  final MatchRepository repo;
  final Stream<List<RouteMatch>> stream;
  final void Function(int requestId)? onOpen;
  const _MatchList({required this.repo, required this.stream, this.onOpen});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RouteMatch>>(
      stream: stream,
      builder: (context, snap) {
        final list = snap.data ?? const <RouteMatch>[];
        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('내 동선에 맞는 부탁', style: AppType.sectionSmall),
              const SizedBox(height: 4),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 8),
                  child: Text('아직 없어요. 동선 근처에 부탁이 올라오면 여기 모이고, 낮 시간엔 알림도 보내요(하루 3번까지).', style: AppType.meta.copyWith(height: 1.5)),
                )
              else
                for (final m in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body.copyWith(fontWeight: AppType.w600)),
                    subtitle: Text(
                      [m.routeName, '약 ${m.extraMin < 1 ? 1 : m.extraMin}분 더', if (m.area.isNotEmpty) m.area, if (m.price > 0) '${m.price}원'].join(' · '),
                      style: AppType.meta,
                    ),
                    onTap: onOpen == null ? null : () => onOpen!(m.requestId),
                    trailing: IconButton(
                      tooltip: '관심 없음',
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.sub),
                      onPressed: () => repo.dismiss(m.requestId),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _RouteCard extends StatefulWidget {
  final CommuteRoute route;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  const _RouteCard({required this.route, required this.onEdit, required this.onToggle, required this.onDelete});

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  bool confirm = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.route;
    final dim = !r.active || r.overLimit;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(r.name, style: AppType.sectionSmall.copyWith(color: dim ? AppColors.sub : AppColors.ink)),
              ),
              Switch(value: r.active, activeTrackColor: AppColors.green, onChanged: widget.onToggle),
            ],
          ),
          Text(
            '${r.from.label} → ${r.to.label}',
            style: AppType.body.copyWith(fontSize: 15, fontWeight: AppType.w600, color: dim ? AppColors.sub : AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            '${r.dayLabel} · ${r.start}~${r.end} · ${CommuteRoute.modes[r.mode]} · 반경 ${r.radiusLabel}',
            style: AppType.meta.copyWith(fontSize: 12.5),
          ),
          if (r.overLimit)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('동선이 너무 많아 추천에서 빠졌어요', style: AppType.meta.copyWith(color: AppColors.red)),
            ),
          Row(
            children: [
              TextButton(onPressed: widget.onEdit, child: const Text('고치기')),
              TextButton(
                onPressed: () {
                  if (confirm) {
                    widget.onDelete();
                  } else {
                    setState(() => confirm = true);
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                child: Text(confirm ? '한 번 더 누르면 지워져요' : '지우기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 동선 추가 · 고치기. 이름 → 출발 · 도착 → 요일 · 시간 → 이동수단 · 반경 순으로, 대부분 칩을 누르는 것으로 끝난다.
class RouteEditScreen extends StatefulWidget {
  final RouteRepository repo;
  final CommuteRoute? route;

  /// 지금 등록된 동선 수(새로 만들 때 상한 확인)
  final int count;

  /// 캘린더 일정에서 채운 새 동선(A14) — 도착 · 요일 · 시간. 사용자가 확인하고 저장한다
  final RouteDraft? draft;
  const RouteEditScreen({super.key, required this.repo, this.route, this.count = 0, this.draft});

  @override
  State<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends State<RouteEditScreen> {
  late final TextEditingController name = TextEditingController(text: widget.route?.name ?? widget.draft?.name ?? '출근');
  late RoutePoint? from = widget.route?.from;
  late RoutePoint? to = widget.route?.to ?? widget.draft?.to;
  late Set<int> days = {
    ...?widget.route?.days,
    if (widget.route == null) ...(widget.draft?.days ?? const [1, 2, 3, 4, 5]),
  };
  late TimeOfDay start = _parse(widget.route?.start ?? widget.draft?.start ?? '08:00');
  late TimeOfDay end = _parse(widget.route?.end ?? widget.draft?.end ?? '09:00');
  late String mode = widget.route?.mode ?? 'transit';
  late int radius = widget.route?.radiusM ?? 500;
  bool saving = false;
  String? error;

  static TimeOfDay _parse(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.tryParse(p.first) ?? 8, minute: int.tryParse(p.last) ?? 0);
  }

  static String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(context: context, initialTime: isStart ? start : end);
    if (t == null) return;
    setState(() {
      if (isStart) {
        start = t;
        // 끝 시각이 시작보다 이르면 한 시간 뒤로 맞춘다
        if (end.hour * 60 + end.minute <= t.hour * 60 + t.minute) end = TimeOfDay(hour: (t.hour + 1) % 24, minute: t.minute);
      } else {
        end = t;
      }
    });
  }

  Future<void> _pickPlace(bool isFrom) async {
    final picked = await showPlacePicker(context, title: isFrom ? '어디서 출발해요?' : '어디로 가요?', sub: '약 1km 칸으로만 저장해요');
    if (picked == null) return;
    final p = RoutePoint.at(picked.label, picked.lat, picked.lng);
    setState(() => isFrom ? from = p : to = p);
  }

  Future<void> _save() async {
    if (from == null || to == null) {
      setState(() => error = '출발과 도착을 골라 주세요');
      return;
    }
    final r = CommuteRoute(
      id: widget.route?.id ?? '',
      name: name.text.trim(),
      from: from!,
      to: to!,
      days: days.toList(),
      start: _fmt(start),
      end: _fmt(end),
      mode: mode,
      radiusM: radius,
      active: widget.route?.active ?? true,
    );
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.repo.save(r, existing: widget.count);
      if (mounted) Navigator.pop(context);
    } on ServerException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(t, style: AppType.sectionSmall),
  );

  Widget _place(String hint, RoutePoint? p, VoidCallback onTap) => Material(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(Icons.place_outlined, size: 20, color: p == null ? AppColors.faint : AppColors.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                p?.label ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body.copyWith(fontSize: 15, color: p == null ? AppColors.faint : AppColors.ink),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ready = from != null && to != null && days.isNotEmpty && name.text.trim().isNotEmpty;
    return PageFrame(
      title: widget.route == null ? '동선 추가' : '동선 고치기',
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: BigButton(label: saving ? '저장하는 중…' : '저장하기', onTap: ready && !saving ? _save : null),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _label('이름'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final n in routeNames)
                ChipWidget(label: n, active: name.text == n, onTap: () => setState(() => name.text = n)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: name,
            maxLength: 20,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '직접 적기', counterText: ''),
          ),
          _label('어디서 어디로'),
          _place('출발 고르기', from, () => _pickPlace(true)),
          const SizedBox(height: 8),
          _place('도착 고르기', to, () => _pickPlace(false)),
          _label('언제'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (label, set) in const [('평일', {1, 2, 3, 4, 5}), ('주말', {6, 7}), ('매일', {1, 2, 3, 4, 5, 6, 7})])
                ChipWidget(label: label, active: days.length == set.length && days.containsAll(set), onTap: () => setState(() => days = {...set})),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                ChipWidget(
                  label: CommuteRoute.dayNames[d - 1],
                  active: days.contains(d),
                  onTap: () => setState(() => days.contains(d) ? days.remove(d) : days.add(d)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: LineButton(label: '${_fmt(start)} 출발', height: 44, onTap: () => _pickTime(true))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~')),
              Expanded(child: LineButton(label: '${_fmt(end)} 도착', height: 44, onTap: () => _pickTime(false))),
            ],
          ),
          _label('어떻게'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in CommuteRoute.modes.entries)
                ChipWidget(label: e.value, active: mode == e.key, onTap: () => setState(() => mode = e.key)),
            ],
          ),
          _label('길에서 얼마나 떨어진 부탁까지'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in routeRadii)
                ChipWidget(label: m < 1000 ? '${m}m' : '${m ~/ 1000}km', active: radius == m, onTap: () => setState(() => radius = m)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('좁을수록 길에 딱 붙은 부탁만, 넓을수록 조금 돌아가는 부탁까지 알려 드려요.', style: AppType.meta),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(error!, style: AppType.meta.copyWith(color: AppColors.red, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// 동선 입력에 미리 채울 값(캘린더 일정에서 — A14)
class RouteDraft {
  final String name;
  final RoutePoint? to;
  final List<int> days;
  final String start;
  final String end;
  const RouteDraft({required this.name, this.to, required this.days, required this.start, required this.end});
}

/// 고른 장소. 좌표를 어떻게 저장할지(격자로 줄일지)는 부르는 쪽이 정한다
class PickedPlace {
  final String label;
  final double lat;
  final double lng;
  const PickedPlace(this.label, this.lat, this.lng);
}

/// 장소 고르기: 자주 쓰는 역 → 장소 검색(키가 있을 때) → 지도에서 콕 찍기. 동선 · 부탁 쓰기에서 같이 쓴다
Future<PickedPlace?> showPlacePicker(BuildContext context, {required String title, required String sub}) =>
    showSheet<PickedPlace>(context, (_) => _PlaceSheet(title: title, sub: sub));

class _PlaceSheet extends StatefulWidget {
  final String title;
  final String sub;
  const _PlaceSheet({required this.title, required this.sub});

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  final q = TextEditingController();
  final api = const NaverLocalApi();
  List<NearbyPlace> found = const [];
  bool searching = false;
  String? note;
  (double, double)? pin;
  final pinName = TextEditingController(text: '지도에서 고른 곳');

  @override
  void dispose() {
    q.dispose();
    pinName.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final k = q.text.trim();
    if (k.length < 2) return;
    setState(() {
      searching = true;
      note = null;
    });
    try {
      final r = await api.search(k);
      setState(() {
        found = r;
        note = r.isEmpty ? '찾는 곳이 없어요. 지도에서 골라 보세요.' : null;
      });
    } catch (_) {
      setState(() => note = '지금은 장소 검색을 쓸 수 없어요. 아래 역이나 지도에서 골라 주세요.');
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void _done(String label, double lat, double lng) => Navigator.pop(context, PickedPlace(label, lat, lng));

  @override
  Widget build(BuildContext context) {
    final filter = q.text.trim();
    final stations = routeStations.where((s) => filter.isEmpty || s.$1.contains(filter)).toList();
    return SheetFrame(
      title: widget.title,
      sub: widget.sub,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (api.ready)
            TextField(
              controller: q,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: '역 · 동 · 건물 이름',
                suffixIcon: IconButton(
                  tooltip: '찾기',
                  onPressed: searching ? null : _search,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
            )
          else
            TextField(
              controller: q,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '역 이름으로 거르기'),
            ),
          if (note != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(note!, style: AppType.meta)),
          for (final p in found)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name),
              subtitle: Text(p.address, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => _done(p.name, p.lat, p.lon),
            ),
          const SizedBox(height: 10),
          Text('자주 다니는 역', style: AppType.meta.copyWith(fontWeight: AppType.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final s in stations) ChipWidget(label: s.$1, onTap: () => _done(s.$1, s.$2, s.$3))],
          ),
          const SizedBox(height: 14),
          Text('지도에서 고르기', style: AppType.meta.copyWith(fontWeight: AppType.w600)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: TripMap(
              trips: const [],
              scope: '서울 서초구',
              height: 200,
              onOpen: (_) {},
              picked: pin,
              onPick: (lat, lng) => setState(() => pin = (lat, lng)),
            ),
          ),
          if (pin != null) ...[
            const SizedBox(height: 8),
            TextField(controller: pinName, maxLength: 40, decoration: const InputDecoration(labelText: '이 곳 이름', counterText: '')),
            const SizedBox(height: 8),
            BigButton(label: '이 곳으로', onTap: () => _done(pinName.text.trim().isEmpty ? '지도에서 고른 곳' : pinName.text.trim(), pin!.$1, pin!.$2)),
          ],
        ],
      ),
    );
  }
}
