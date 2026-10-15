import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/hub_scaffold.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/select_box.dart';
import '../data/categories.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import '../services/nearby_query.dart';
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
  late NearbyQuery _query = NearbyQuery(cat: widget.initialCat);

  bool get _dirty => _query.cat != 'all' || _query.shortOnly || _query.radius != 3 || _query.sort != 'dist';

  void _set(NearbyQuery next) => setState(() => _query = next);

  void _goList(ScreenRoute config) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ListScreen(config: config, items: widget.items, scope: widget.scope, actions: widget.actions),
    ),
  );

  void _goMap(List<TaskItem> list) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MapScreen(items: list, scope: widget.scope, actions: widget.actions),
    ),
  );

  void _goSearch() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SearchScreen(items: widget.items, actions: widget.actions),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final list = _query.apply(widget.items, widget.scope);

    return HubScaffold(
      title: '동네 부탁',
      subtitle: '가까운 곳에서 하나 더',
      right: IconBtn(icon: 'search', label: '검색', onTap: _goSearch),
      children: [
        HubSection(
          title: '무엇을 부탁하나요',
          sub: '종류를 고르면 아래 목록이 바뀌어요',
          padded: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 76,
                mainAxisSpacing: 10,
                mainAxisExtent: 62,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _CatTile(
                  cat: 'etc',
                  label: '전체',
                  active: _query.cat == 'all',
                  onTap: () => _set(_query.copyWith(cat: 'all')),
                ),
                for (final c in cats)
                  _CatTile(
                    cat: c.k,
                    label: c.label,
                    active: _query.cat == c.k,
                    onTap: () => _set(_query.copyWith(cat: c.k)),
                  ),
              ],
            ),
          ),
        ),
        HubSection(
          title: '지금, 내 주변',
          sub: '${list.length}개의 부탁 · 시작 장소까지의 예시 거리',
          onAction: () =>
              _goList(const ScreenRoute(name: 'list', title: '부탁 전체', base: 'ask', sortable: true, catChips: true, mapBtn: true)),
          padded: false,
          child: Column(
            children: [
              _filterRow(list),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Row(
                  children: [
                    const Spacer(),
                    if (_dirty)
                      TextButton(
                        onPressed: () => _set(const NearbyQuery()),
                        child: Text(
                          '조건 초기화',
                          style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w700, color: AppColors.ink),
                        ),
                      ),
                  ],
                ),
              ),
              if (list.isEmpty)
                const EmptyState(msg: '조건에 맞는 부탁이 없어요.\n거리 미확인 부탁은 반경 검색에서 제외됩니다.')
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final it in list.take(12))
                        TaskCard(
                          it: it,
                          onOpen: () => widget.actions.open(context, it),
                          done: widget.actions.grabbed.contains(it.id),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        HubSection(
          title: '이런 부탁은 어때요',
          sub: '자주 찾는 조건만 모아뒀어요',
          child: Column(
            children: [
              HubRow(
                icon: 'fire',
                title: '지금 급해요',
                sub: '요청자가 급하게 찾는 부탁',
                onTap: () =>
                    _goList(const ScreenRoute(name: 'list', title: '지금 급해요', base: 'ask', onlyHot: true, sortable: true)),
              ),
              HubRow(
                icon: 'clock',
                title: '30분 안에 끝나요',
                sub: '짧게 다녀올 수 있는 부탁',
                onTap: () => _goList(
                  const ScreenRoute(
                    name: 'list',
                    title: '30분 안에 끝나요',
                    base: 'ask',
                    maxMins: 30,
                    sortable: true,
                    defaultSort: 'time',
                  ),
                ),
              ),
              HubRow(
                icon: 'sparkles',
                title: '사례비 높은 순',
                sub: '한 번에 크게 버는 부탁',
                onTap: () => _goList(
                  const ScreenRoute(name: 'list', title: '사례비 높은 부탁', base: 'ask', sortable: true, defaultSort: 'price'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 반경 · 정렬 · 30분 · 지도. 홈의 '지금 내 주변 부탁'과 같은 조건이다.
  Widget _filterRow(List<TaskItem> list) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SelectBox<double>(
            label: '반경',
            icon: Icons.place_outlined,
            value: _query.radius,
            display: '${_query.radiusLabel} 이내',
            items: NearbyQuery.radiusOptions,
            onChanged: (v) => _set(_query.copyWith(radius: v)),
          ),
          const SizedBox(width: 6),
          SelectBox<String>(
            label: '정렬',
            value: _query.sort,
            display: NearbyQuery.sortLabels[_query.sort]!,
            items: NearbyQuery.sortOptions,
            onChanged: (v) => _set(_query.copyWith(sort: v)),
          ),
          const SizedBox(width: 6),
          ToggleBox(
            label: '30분 이내',
            active: _query.shortOnly,
            onTap: () => _set(_query.copyWith(shortOnly: !_query.shortOnly)),
          ),
          const SizedBox(width: 6),
          ToggleBox(label: '지도', icon: Icons.map_outlined, active: false, onTap: () => _goMap(list)),
        ],
      ),
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
      child: Column(
        children: [
          Stack(
            children: [
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
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: active ? FontWeight.w700 : FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
