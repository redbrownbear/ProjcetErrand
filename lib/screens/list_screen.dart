import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../theme/colors.dart';
import '../widgets/chip_widget.dart';
import '../widgets/task_card.dart';

class ListScreen extends StatefulWidget {
  final String kind; // help | sea
  final List<TaskItem> items;
  final String scope;
  final List<int> grabbed;
  final VoidCallback onClose;
  final void Function(TaskItem) openDetail;
  const ListScreen({
    super.key, required this.kind, required this.items, required this.scope,
    required this.grabbed, required this.onClose, required this.openDetail,
  });
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  String sort = 'recommend';

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.mode == 'sea' || i.region == widget.scope;

  @override
  Widget build(BuildContext context) {
    final sea = widget.kind == 'sea';
    var list = sea
        ? widget.items.where((i) => i.mode == 'sea').toList()
        : widget.items.where((i) => (i.mode == 'ask' || i.mode == 'sea') && _inScope(i)).toList();

    list.sort((a, b) {
      final h = (b.hot ? 1 : 0) - (a.hot ? 1 : 0);
      if (h != 0) return h;
      if (sort == 'price') return b.price - a.price;
      if (sort == 'dist') return a.distM.compareTo(b.distM);
      if (sort == 'time') return a.mins.compareTo(b.mins);
      return 0;
    });

    const filters = [
      ['recommend', '추천순'], ['dist', '가까운 순'], ['price', '높은 사례비'], ['time', '짧은 시간순'],
    ];

    return Positioned.fill(
      child: Material(
        color: AppColors.page,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: const BoxDecoration(color: AppColors.card, border: Border(bottom: BorderSide(color: AppColors.line))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(99),
                      child: const Padding(padding: EdgeInsets.only(right: 2), child: Text('‹', style: TextStyle(fontSize: 24, color: AppColors.ink))),
                    ),
                    Text(sea ? '해외 대행구매' : '도와주기', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(left: 22, top: 4),
                    child: Text(
                      sea ? '그 나라에 있는 이웃이 대신 사서 가져다줘요' : '${widget.scope == "전국" ? "전국" : widget.scope} · 가는 길에 부탁 해결하고 사례비 받기',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
                    ),
                  ),
                  if (!sea)
                    Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: filters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 7),
                          itemBuilder: (context, i) {
                            final f = filters[i];
                            return ChipWidget(label: f[1], active: sort == f[0], onTap: () => setState(() => sort = f[0]));
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                children: [
                  if (sea)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        '✈️ 물건값은 영수증으로 정산되고, 사례비는 별도예요. 완료 확인 전까지 앱이 안전하게 보관해요.',
                        style: TextStyle(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w600, height: 1.55),
                      ),
                    ),
                  for (final it in list)
                    TaskCard(it: it, onOpen: () => widget.openDetail(it), done: widget.grabbed.contains(it.id)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
