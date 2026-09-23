import 'package:flutter/material.dart';

import '../../../core/navigation/screen_route.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../data/categories.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import '../widgets/task_card.dart';
import 'map_screen.dart';

class ListScreen extends StatefulWidget {
  final ScreenRoute config;
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;
  const ListScreen({
    super.key, required this.config, required this.items, required this.scope, required this.actions,
  });
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late String sort = widget.config.defaultSort ?? 'recommend';
  late String cat = widget.config.cat ?? 'all';
  String fdist = 'all';
  String ftime = 'all';
  String fprice = 'all';

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    var base = widget.items.where((i) {
      if (config.filter != null) return config.filter!(i);
      switch (config.base) {
        case 'earn':
          return (i.mode == 'ask' && _inScope(i)) || i.mode == 'sea';
        case 'ask':
          return i.mode == 'ask' && _inScope(i);
        case 'sea':
          return i.mode == 'sea';
        default:
          return _inScope(i);
      }
    }).toList();

    if (config.onlyHot) base = base.where((i) => i.hot).toList();
    if (config.maxMins != null) base = base.where((i) => i.mins > 0 && i.mins <= config.maxMins!).toList();
    if (config.catChips && cat != 'all') base = base.where((i) => i.cat == cat).toList();
    // 거리 미확인 부탁은 거리 조건에서 제외한다
    if (fdist != 'all') base = base.where((i) => i.distM != null && i.distM! <= double.parse(fdist)).toList();
    if (ftime != 'all') base = base.where((i) => i.mins > 0 && i.mins <= int.parse(ftime)).toList();
    if (fprice != 'all') base = base.where((i) => i.price >= int.parse(fprice)).toList();

    // 급해요 우선은 추천순에서만. 사용자가 고른 정렬(가까운 순 등)을 덮어쓰지 않는다.
    base.sort((a, b) {
      // '부탁하기'로 올린 진짜 부탁을 예시 데이터보다 항상 위에 둔다.
      if (a.sample != b.sample) return a.sample ? 1 : -1;
      switch (sort) {
        case 'price':
          return b.price - a.price;
        case 'dist':
          return a.distSort.compareTo(b.distSort);
        case 'time':
          return a.mins.compareTo(b.mins);
        case 'new':
          return b.id - a.id;
        case 'deals':
          return b.deals - a.deals;
        default:
          return a.hot == b.hot ? 0 : (a.hot ? -1 : 1);
      }
    });

    const sorts = [
      ['recommend', '추천순'], ['dist', '가까운 순'], ['price', '높은 사례비'], ['time', '짧은 시간순'], ['new', '최신순'],
    ];

    return Material(
      color: AppColors.page,
      // edge-to-edge(targetSdk 36)에서 헤더가 상태바에, 본문 끝이 제스처바에 깔린다.
      child: SafeArea(child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: const BoxDecoration(color: AppColors.card, border: Border(bottom: BorderSide(color: AppColors.line))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(99),
                  child: const Padding(padding: EdgeInsets.only(right: 2), child: Text('‹', style: TextStyle(fontSize: 24, color: AppColors.ink))),
                ),
                Expanded(child: Text(config.title ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink))),
                if (config.mapBtn)
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(items: widget.items, scope: widget.scope, actions: widget.actions))),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(9)),
                        child: const Text('🗺️ 지도', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ),
                    ),
                ]),
                if (config.subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 22, top: 4),
                    child: Text(config.subtitle!, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                if (config.sortable)
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sorts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final s = sorts[i];
                        return ChipWidget(label: s[1], active: sort == s[0], onTap: () => setState(() => sort = s[0]));
                      },
                    ),
                  ),
                if (config.catChips)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: '전체', active: cat == 'all', onTap: () => setState(() => cat = 'all'))),
                          for (final c in cats)
                            Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: '${c.icon} ${c.label}', active: cat == c.k, onTap: () => setState(() => cat = c.k))),
                        ],
                      ),
                    ),
                  ),
                if (config.sortable)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: '1km 이내', active: fdist == '1000', onTap: () => setState(() => fdist = fdist == '1000' ? 'all' : '1000'))),
                          Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: '3km 이내', active: fdist == '3000', onTap: () => setState(() => fdist = fdist == '3000' ? 'all' : '3000'))),
                          Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: '30분 이하', active: ftime == '30', onTap: () => setState(() => ftime = ftime == '30' ? 'all' : '30'))),
                          Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: '1만원 이상', active: fprice == '10000', onTap: () => setState(() => fprice = fprice == '10000' ? 'all' : '10000'))),
                          Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: '2만원 이상', active: fprice == '20000', onTap: () => setState(() => fprice = fprice == '20000' ? 'all' : '20000'))),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: base.isEmpty
                      ? const EmptyState(msg: '조건에 맞는 부탁이 없어요.')
                      : Column(children: [for (final it in base) TaskCard(it: it, onOpen: () => widget.actions.open(context, it), done: widget.actions.grabbed.contains(it.id), rich: true)]),
                ),
              ],
            ),
          ),
        ])),
    );
  }
}
