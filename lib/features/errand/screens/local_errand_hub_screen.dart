import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/hub_scaffold.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/section_header.dart';
import '../data/categories.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import '../widgets/task_card.dart';
import 'list_screen.dart';
import 'map_screen.dart';
import 'search_screen.dart';

/// 동네 부탁 허브.
///
/// 예전에는 홈 한 화면에 카테고리 그리드·반경/정렬·목록이 모두 깔려 있어서
/// 홈이 계속 길어졌다. 홈은 진입점만 남기고, 실제 탐색은 이 허브로 한 뎁스
/// 내려왔다. 목록을 더 좁히는 일(카테고리·반경·정렬·30분)은 전부 여기서 한다.
class LocalErrandHubScreen extends StatefulWidget {
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;

  /// 홈 숏컷에서 특정 종류를 눌러 들어온 경우의 초기 카테고리
  final String initialCat;

  const LocalErrandHubScreen({
    super.key,
    required this.items,
    required this.scope,
    required this.actions,
    this.initialCat = 'all',
  });

  @override
  State<LocalErrandHubScreen> createState() => _LocalErrandHubScreenState();
}

class _LocalErrandHubScreenState extends State<LocalErrandHubScreen> {
  late String cat = widget.initialCat;
  double radius = 3; // km
  String sort = 'dist';
  bool shortOnly = false;

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  /// 거리를 뺀 공통 조건 (지역 · 마감 · 종류 · 30분)
  bool _matches(TaskItem i) =>
      i.mode == 'ask' &&
      _inScope(i) &&
      !i.isExpired &&
      (cat == 'all' || i.cat == cat) &&
      (!shortOnly || (i.mins > 0 && i.mins <= 30));

  /// '부탁하기'로 올린 **진짜 부탁**. 항상 목록 맨 위에 최신순으로 둔다.
  ///
  /// 새로 올린 부탁은 아직 좌표가 없어서(`distM == null`) 반경 조건에 걸리면
  /// 목록에서 통째로 사라진다. 방금 올린 내 부탁이 안 보이는 게 제일 이상하므로,
  /// 반경·정렬과 무관하게 따로 뽑아 앞에 붙인다.
  List<TaskItem> get _realTasks =>
      widget.items.where((i) => !i.sample && _matches(i)).toList()..sort((a, b) => b.id.compareTo(a.id));

  /// 미리 만들어 둔 예시 부탁. 반경·정렬 조건을 그대로 따른다.
  List<TaskItem> get _sampleTasks {
    final list = widget.items
        .where((i) => i.sample && _matches(i) && i.distM != null && i.distM! <= radius * 1000)
        .toList();
    switch (sort) {
      case 'price':
        list.sort((a, b) => b.price - a.price);
      case 'time':
        list.sort((a, b) => a.mins.compareTo(b.mins));
      case 'deadline':
        list.sort((a, b) {
          final x = a.deadline, y = b.deadline;
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return x.compareTo(y);
        });
      case 'new':
        list.sort((a, b) => b.id.compareTo(a.id));
      default:
        list.sort((a, b) => a.distSort.compareTo(b.distSort));
    }
    return list;
  }

  /// 화면에 뿌리는 목록 = 내 진짜 부탁 + 예시
  List<TaskItem> get _tasks => [..._realTasks, ..._sampleTasks];

  String get _radiusLabel => radius < 1 ? '${(radius * 1000).round()}m' : '${radius % 1 == 0 ? radius.toInt() : radius}km';
  bool get _dirty => cat != 'all' || shortOnly || radius != 3 || sort != 'dist';

  void _goList(ScreenRoute config) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ListScreen(config: config, items: widget.items, scope: widget.scope, actions: widget.actions)),
      );

  void _goMap(List<TaskItem> list) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MapScreen(items: list, scope: widget.scope, actions: widget.actions)),
      );

  void _goSearch() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SearchScreen(items: widget.items, actions: widget.actions)),
      );

  @override
  Widget build(BuildContext context) {
    final list = _tasks;

    return HubScaffold(
      title: '동네 부탁',
      subtitle: '가까운 곳에서 하나 더',
      right: IconBtn(icon: 'search', label: '검색', onTap: _goSearch),
      children: [
        // ① 무엇을 부탁하나요 — 카테고리 (홈 숏컷 '전체' 펼침에서 이동)
        HubSection(
          title: '무엇을 부탁하나요',
          sub: '종류를 고르면 아래 목록이 바뀌어요',
          padded: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 76, mainAxisSpacing: 10, mainAxisExtent: 62),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _CatTile(cat: 'etc', label: '전체', active: cat == 'all', onTap: () => setState(() => cat = 'all')),
                for (final c in cats)
                  _CatTile(cat: c.k, label: c.label, active: cat == c.k, onTap: () => setState(() => cat = c.k)),
              ],
            ),
          ),
        ),

        // ② 지금, 내 주변 — 반경·정렬·30분·지도 + 목록
        HubSection(
          title: '지금, 내 주변',
          sub: '${list.length}개의 부탁 · 시작 장소까지의 예시 거리',
          onAction: () => _goList(const ScreenRoute(name: 'list', title: '부탁 전체', base: 'ask', sortable: true, catChips: true, mapBtn: true)),
          padded: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(children: [
                Expanded(
                  child: _Picker<double>(
                    label: '반경',
                    value: radius,
                    display: _radiusLabel,
                    items: const [
                      [0.5, '500m 이내'], [1.0, '1km 이내'], [3.0, '3km 이내'],
                      [5.0, '5km 이내'], [10.0, '10km 이내'], [20.0, '20km 이내'], [30.0, '30km 이내'],
                    ],
                    onChanged: (v) => setState(() => radius = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Picker<String>(
                    label: '정렬',
                    value: sort,
                    display: const {'dist': '가까운순', 'price': '사례비순', 'time': '짧은순', 'deadline': '마감임박', 'new': '최신순'}[sort]!,
                    items: const [
                      ['dist', '가까운순'], ['price', '사례비 높은순'], ['time', '소요시간 짧은순'],
                      ['deadline', '마감 임박순'], ['new', '최신순'],
                    ],
                    onChanged: (v) => setState(() => sort = v),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _goMap(list),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.map_outlined, size: 16, color: AppColors.ink),
                      const SizedBox(width: 4),
                      Text('지도', style: AppType.meta.copyWith(fontWeight: AppType.w600, color: AppColors.ink)),
                    ]),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Row(children: [
                InkWell(
                  onTap: () => setState(() => shortOnly = !shortOnly),
                  borderRadius: BorderRadius.circular(99),
                  child: ChipWidget(label: '30분 안에 끝나요', active: shortOnly),
                ),
                const Spacer(),
                if (_dirty)
                  TextButton(
                    onPressed: () => setState(() {
                      cat = 'all';
                      shortOnly = false;
                      radius = 3;
                      sort = 'dist';
                    }),
                    child: const Text('조건 초기화', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ),
              ]),
            ),
            if (list.isEmpty)
              const EmptyState(msg: '조건에 맞는 부탁이 없어요.\n거리 미확인 부탁은 반경 검색에서 제외됩니다.')
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  for (final it in list.take(12))
                    TaskCard(it: it, onOpen: () => widget.actions.open(context, it), done: widget.actions.grabbed.contains(it.id)),
                ]),
              ),
          ]),
        ),

        // ③ 조건별 모아보기 — 예전 홈의 테마 섹션들이 여기로 내려왔다
        HubSection(
          title: '이런 부탁은 어때요',
          sub: '자주 찾는 조건만 모아뒀어요',
          child: Column(children: [
            HubRow(
              icon: 'fire',
              title: '지금 급해요',
              sub: '요청자가 급하게 찾는 부탁',
              onTap: () => _goList(const ScreenRoute(name: 'list', title: '지금 급해요', base: 'ask', onlyHot: true, sortable: true)),
            ),
            HubRow(
              icon: 'clock',
              title: '30분 안에 끝나요',
              sub: '짧게 다녀올 수 있는 부탁',
              onTap: () => _goList(const ScreenRoute(name: 'list', title: '30분 안에 끝나요', base: 'ask', maxMins: 30, sortable: true, defaultSort: 'time')),
            ),
            HubRow(
              icon: 'sparkles',
              title: '사례비 높은 순',
              sub: '한 번에 크게 버는 부탁',
              onTap: () => _goList(const ScreenRoute(name: 'list', title: '사례비 높은 부탁', base: 'ask', sortable: true, defaultSort: 'price')),
            ),
          ]),
        ),
      ],
    );
  }
}

class _CatTile extends StatelessWidget {
  final String cat, label;
  final bool active;
  final VoidCallback onTap;
  const _CatTile({required this.cat, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(children: [
        Stack(children: [
          CatEmblem(cat: cat, size: 40, radius: 12, iconSize: 20),
          if (active)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ink, width: 1.4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 5),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
  }
}

/// 반경·정렬처럼 값을 하나 고르는 작은 드롭다운. 바텀시트로 열어 터치 영역을 넓게 둔다.
class _Picker<T> extends StatelessWidget {
  final String label;
  final T value;
  final String display;
  final List<List<Object>> items;
  final void Function(T) onChanged;
  const _Picker({required this.label, required this.value, required this.display, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Text('$label ', style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
          Expanded(child: Text(display, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
          const Text('▾', style: TextStyle(fontSize: 11, color: AppColors.faint)),
        ]),
      ),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 6), child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink))),
            for (final it in items)
              ListTile(
                title: Text(it[1] as String, style: TextStyle(fontSize: 14, fontWeight: it[0] == value ? FontWeight.w800 : FontWeight.w500, color: AppColors.ink)),
                trailing: it[0] == value ? const Text('✓', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)) : null,
                onTap: () {
                  Navigator.of(sheet).pop();
                  onChanged(it[0] as T);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
