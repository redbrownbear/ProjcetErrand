import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../../core/widgets/surface.dart';
import '../../errand/models/task_item.dart';
import '../../errand/widgets/task_card.dart';
import '../data/trip_seeds.dart';

/// 홈 · 해외 탭이 같이 쓰는 v77 조각 — 여행 도구 칸과 '가는 김에' 글 목록.

/// '여행 어디 갈까?' · '세계 제안 지도' 회색 도구 칸 (.pp-tools)
class TripTools extends StatelessWidget {
  final AppNav nav;
  final bool abroad;
  const TripTools({super.key, required this.nav, this.abroad = false});

  @override
  Widget build(BuildContext context) {
    final dart = ToolTile(
      lead: const _Target(),
      title: '여행 어디 갈까?',
      sub: abroad ? '다트를 던져 정해요' : '다트를 던져 정해요 · 명소·맛집·숙소까지',
      compact: abroad,
      onTap: () => nav.openDart(context, abroad: abroad),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: abroad
          ? Row(
              children: [
                Expanded(
                  child: ToolTile(
                    lead: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.public_rounded, size: 20, color: AppColors.blue),
                    ),
                    title: '세계 제안 지도',
                    sub: '나라별 제안, 요청 한눈에',
                    compact: true,
                    onTap: () => nav.openWorld(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: dart),
              ],
            )
          : dart,
    );
  }
}

class _Target extends StatelessWidget {
  const _Target();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.red, width: 5),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// 가는 김에 글 — 실제 글(서버) 먼저, 예시 글은 뒤에. 마감된 글은 뺀다.
List<TaskItem> tripItems(AppNav nav) {
  final real = nav.items().where((i) => i.isTrip && !i.isExpired).toList();
  final ids = {for (final i in real) i.id};
  return [...real, ...tripSeeds.where((s) => !ids.contains(s.id))];
}

/// 가는 김에 — 사람들은 지금 어디로 가고 있을까요? (.gkm)
/// '지금 내 주변 부탁'과 같은 줄 모양([TaskCard])으로 보여 준다.
class TripFeedSection extends StatelessWidget {
  final AppNav nav;
  final VoidCallback onAll;
  final int take;
  const TripFeedSection({super.key, required this.nav, required this.onAll, this.take = 3});

  @override
  Widget build(BuildContext context) {
    final list = tripItems(nav).take(take).toList();
    final grabbed = nav.actions().grabbed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('가는 김에', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                      SizedBox(height: 3),
                      Text('사람들은 지금 어디로 가고 있을까요?', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
                    ],
                  ),
                ),
                LineButton(label: '글쓰기', icon: 'pencil', height: 28, onTap: () => nav.openTripPost(going: true)),
                const SizedBox(width: 6),
                TextLink(label: '전체보기', onTap: onAll),
              ],
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < list.length; i++)
              TaskCard(
                it: list[i],
                onOpen: () => nav.actions().open(context, list[i]),
                done: grabbed.contains(list[i].id),
                last: i == list.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}
