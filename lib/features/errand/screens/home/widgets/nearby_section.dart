import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../../../core/widgets/surface.dart';
import '../../../../dayjob/models/day_job.dart';
import '../../../../dayjob/widgets/day_job_card.dart';
import '../../../data/categories.dart';
import '../../../models/task_item.dart';
import '../../../widgets/task_card.dart';
import '../../map/map_canvas.dart';
import '../../map/map_centers.dart';
import '../../../services/nearby_query.dart';
import '../../../../../core/widgets/select_box.dart';

/// '지금 내 주변 부탁' — 동네 부탁 / 단기알바 탭, 조건 줄, 목록 또는 지도.
///
/// 조건([query])은 홈이 들고 있고, 여기서는 지도에서 고른 핀만 기억한다.
/// 지도는 목록과 **같은 조건의 결과**([tasks])를 그대로 올린다.
class NearbySection extends StatefulWidget {
  final NearbyQuery query;
  final ValueChanged<NearbyQuery> onQuery;

  /// [query]를 적용한 부탁 목록
  final List<TaskItem> tasks;
  final List<DayJob> jobs;
  final String scope;

  /// 이미 지원한 부탁 id
  final List<int> grabbed;

  final void Function(TaskItem) onOpenTask;
  final void Function(DayJob) onOpenJob;
  final VoidCallback onOpenAllTasks;
  final VoidCallback onOpenAllJobs;

  const NearbySection({
    super.key,
    required this.query,
    required this.onQuery,
    required this.tasks,
    required this.jobs,
    required this.scope,
    required this.grabbed,
    required this.onOpenTask,
    required this.onOpenJob,
    required this.onOpenAllTasks,
    required this.onOpenAllJobs,
  });

  @override
  State<NearbySection> createState() => _NearbySectionState();
}

class _NearbySectionState extends State<NearbySection> {
  /// 목록에서 한 번에 보여 주는 개수. 나머지는 '부탁 전체 보기'로 넘긴다.
  static const _listLimit = 8;

  int? _pinned;

  NearbyQuery get _q => widget.query;

  void _set(NearbyQuery q) {
    _pinned = null;
    widget.onQuery(q);
  }

  @override
  Widget build(BuildContext context) {
    return SecCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SecHead(title: '지금 내 주변 부탁', action: '부탁 전체보기', onAction: widget.onOpenAllTasks),
          UnderlineTabs(
            tabs: [('동네 부탁', null), ('단기알바', '${widget.jobs.length}')],
            index: _q.kind == 'ask' ? 0 : 1,
            onChanged: (i) => _set(_q.copyWith(kind: i == 0 ? 'ask' : 'job', showMap: false)),
          ),
          if (_q.kind == 'ask') ...[
            _filterRow(),
            _countLine(),
            if (_q.showMap) _map() else _list(),
            SoftButton(label: '부탁 전체 보기', onTap: widget.onOpenAllTasks),
          ] else
            _dayJobs(),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          SelectBox<double>(
            label: '반경',
            icon: Icons.place_outlined,
            value: _q.radius,
            display: '${_q.radiusLabel} 이내',
            items: NearbyQuery.radiusOptions,
            onChanged: (v) => _set(_q.copyWith(radius: v)),
          ),
          const SizedBox(width: 6),
          SelectBox<String>(
            label: '정렬',
            value: _q.sort,
            display: NearbyQuery.sortLabels[_q.sort]!,
            items: NearbyQuery.sortOptions,
            onChanged: (v) => _set(_q.copyWith(sort: v)),
          ),
          const SizedBox(width: 6),
          SelectBox<String>(
            label: '종류',
            value: _q.cat,
            display: _q.cat == 'all' ? '전체 종류' : catOf(_q.cat).label,
            items: [('all', '전체 종류'), for (final c in cats) (c.k, c.label)],
            onChanged: (v) => _set(_q.copyWith(cat: v)),
          ),
          const SizedBox(width: 6),
          ToggleBox(
            label: '30분 이내',
            active: _q.shortOnly,
            onTap: () => _set(_q.copyWith(shortOnly: !_q.shortOnly)),
          ),
          const SizedBox(width: 6),
          ToggleBox(
            label: _q.showMap ? '목록' : '지도',
            icon: _q.showMap ? Icons.format_list_bulleted_rounded : Icons.map_outlined,
            active: _q.showMap,
            onTap: () => _set(_q.copyWith(showMap: !_q.showMap)),
          ),
        ],
      ),
    );
  }

  Widget _countLine() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${widget.tasks.length}',
              style: const TextStyle(fontWeight: AppType.w700, color: AppColors.ink),
            ),
            TextSpan(text: '개의 부탁 · ${_q.radiusLabel} 이내${_q.cat == 'all' ? '' : ' · ${catOf(_q.cat).label}'}'),
          ],
        ),
        style: AppType.meta,
      ),
    );
  }

  Widget _list() {
    if (widget.tasks.isEmpty) {
      return EmptyState(
        compact: true,
        title: '조건에 맞는 부탁이 없어요',
        msg: '거리 미확인 부탁은 반경 검색에서 제외됩니다.',
        action: '30km · 전체 종류로 보기',
        onAction: () => _set(NearbyQuery.widest),
      );
    }
    final shown = widget.tasks.take(_listLimit).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        children: [
          for (int i = 0; i < shown.length; i++)
            TaskCard(
              it: shown[i],
              onOpen: () => widget.onOpenTask(shown[i]),
              done: widget.grabbed.contains(shown[i].id),
              last: i == shown.length - 1,
            ),
        ],
      ),
    );
  }

  /// 좌표가 없는 부탁(방금 올린 부탁 등)은 지도에 찍을 수 없어서 개수를 따로 알려 준다.
  Widget _map() {
    final located = widget.tasks.where((i) => i.lat != null && i.lng != null).toList();
    final selected = located.where((i) => i.id == _pinned).firstOrNull ?? located.firstOrNull;
    final center = centerOf(widget.scope);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            located.length == widget.tasks.length ? '목록과 같은 조건의 결과예요' : '좌표가 있는 ${located.length}건만 지도에 표시돼요',
            textAlign: TextAlign.center,
            style: AppType.caption,
          ),
        ),
        Container(
          height: 300,
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(AppRadius.tile)),
          child: MapCanvas(
            pins: [
              for (final it in located)
                MapPin(
                  item: it,
                  lat: it.lat!,
                  lng: it.lng!,
                  label: (it.hot ? '급 ' : '') + kwon(it.price),
                  color: _pinColor(it, selected),
                ),
            ],
            selectedId: selected?.id,
            centerLat: center.$1,
            centerLng: center.$2,
            zoom: zoomOf(widget.scope),
            onPinTap: (it) => setState(() => _pinned = it.id),
          ),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TaskCard(
              it: selected,
              onOpen: () => widget.onOpenTask(selected),
              done: widget.grabbed.contains(selected.id),
              last: true,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('이 조건에는 지도에 찍을 부탁이 없어요', textAlign: TextAlign.center, style: AppType.meta),
          ),
      ],
    );
  }

  Color _pinColor(TaskItem it, TaskItem? selected) {
    if (it.id == selected?.id) return AppColors.heroAccent;
    return widget.grabbed.contains(it.id) ? AppColors.faint : AppColors.ink;
  }

  Widget _dayJobs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('근무일 · 근무시간 · 일급 · 지급일을 부탁과 구분해 안내해요', style: AppType.meta),
          const SizedBox(height: 10),
          for (final j in widget.jobs.take(4)) DayJobCard(j: j, onOpen: () => widget.onOpenJob(j), compact: true),
          SoftButton(label: '단기알바 전체 보기', onTap: widget.onOpenAllJobs, margin: const EdgeInsets.only(top: 6)),
        ],
      ),
    );
  }
}
