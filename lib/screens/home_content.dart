import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../theme/colors.dart';
import '../widgets/nearby_card.dart';
import '../widgets/together_row.dart';

class HomeContent extends StatelessWidget {
  final List<TaskItem> items;
  final String scope;
  final List<int> grabbed;
  final void Function(TaskItem) openDetail;
  final VoidCallback openPost;
  final void Function(String) openList;
  final VoidCallback openRegion;

  const HomeContent({
    super.key,
    required this.items,
    required this.scope,
    required this.grabbed,
    required this.openDetail,
    required this.openPost,
    required this.openList,
    required this.openRegion,
  });

  bool _inScope(TaskItem i) => scope == '전국' || i.region == scope;

  @override
  Widget build(BuildContext context) {
    final nearby = items.where((i) => i.mode == 'ask' && i.distM < 100000 && _inScope(i)).toList()
      ..sort((a, b) {
        final d = a.distM.compareTo(b.distM);
        return d != 0 ? d : a.mins.compareTo(b.mins);
      });
    final nearbyTop = nearby.take(6).toList();
    final together = items.where((i) => i.mode == 'together' && _inScope(i)).toList();

    final shortScope = scope == '전국' ? '전국' : scope.replaceFirst(RegExp(r'^(서울|부산|대전) '), '');

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: openRegion,
                  child: Row(children: [
                    Text(shortScope, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(width: 5),
                    const Text('▾', style: TextStyle(color: AppColors.faint, fontSize: 13)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(99)),
                  child: const Text('3,200P', style: TextStyle(color: AppColors.yellowDeep, fontWeight: FontWeight.w800, fontSize: 12.5)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.28, letterSpacing: -0.3),
                    children: [
                      const TextSpan(text: '가는 길에 하나 더,\n동네에서 '),
                      TextSpan(text: '겸사겸사', style: TextStyle(backgroundColor: AppColors.yellow.withValues(alpha: .55))),
                      const TextSpan(text: ' 벌어요'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text('근처에 부탁하고, 가는 길에 도와주고 사례비를 받아요', style: TextStyle(fontSize: 13.5, color: AppColors.sub)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
            child: Row(children: [
              Expanded(
                child: InkWell(
                  onTap: openPost,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🙋', style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 26),
                        const Text('부탁하기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
                        const SizedBox(height: 3),
                        Text('필요한 일을 근처에', style: TextStyle(fontSize: 12, color: AppColors.ink.withValues(alpha: .62))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: InkWell(
                  onTap: () => openList('help'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🤝', style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 26),
                        const Text('도와주기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 3),
                        const Text('가는 길에 벌기', style: TextStyle(fontSize: 12, color: Colors.white60)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('가는 길에 할 수 있어요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                      const SizedBox(height: 3),
                      const Text('가깝고 금방 끝나는 부탁부터', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
                    ],
                  ),
                ),
                TextButton(onPressed: () => openList('help'), child: const Text('더보기', style: TextStyle(color: AppColors.sub, fontSize: 12.5))),
              ],
            ),
          ),
          if (nearbyTop.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: Text('이 지역엔 아직 가까운 부탁이 없어요. 지역을 ‘전국’으로 바꿔보세요.', style: TextStyle(color: AppColors.sub, fontSize: 13, height: 1.6)),
            )
          else
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
                itemCount: nearbyTop.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final it = nearbyTop[i];
                  return NearbyCard(it: it, onOpen: () => openDetail(it), done: grabbed.contains(it.id));
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
            child: InkWell(
              onTap: () => openList('sea'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  const Text('✈️', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('해외에 있는 이웃에게 부탁하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.purple)),
                        const SizedBox(height: 2),
                        Text('여행·출장 중인 사람이 대신 사다줘요', style: TextStyle(fontSize: 12, color: AppColors.purple.withValues(alpha: .8))),
                      ],
                    ),
                  ),
                  const Text('›', style: TextStyle(color: AppColors.purple, fontSize: 18)),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
            child: Text.rich(
              const TextSpan(
                children: [
                  TextSpan(text: '같이할 사람 ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  TextSpan(text: '· 동네생활', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sub)),
                ],
              ),
            ),
          ),
          ...together.map((it) => TogetherRow(it: it, onOpen: () => openDetail(it))),
        ],
      ),
    );
  }
}
