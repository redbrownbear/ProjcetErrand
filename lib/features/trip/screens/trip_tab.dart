import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../errand/models/task_item.dart';
import '../widgets/trip_parts.dart';
import 'trip_screens.dart';

/// 하단 탭 '가는 김에' (시안 v78) — 누가 가면, 나도 하나!
///
/// 지도 · 나 여기 가요 · 내 활동 · 내 일정 · 전체/오늘/내일 일정 목록 · 멀리 가는 길(제안) 연결.
class TripTab extends StatefulWidget {
  final AppNav nav;
  const TripTab({super.key, required this.nav});

  @override
  State<TripTab> createState() => _TripTabState();
}

class _TripTabState extends State<TripTab> {
  String day = '전체';
  String query = '';

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    final listen = nav.session;
    Widget body(BuildContext context) {
      final mine = tripList(nav, mine: true);
      final others = tripList(nav, mine: false);
      final list = others.where((t) {
        final okDay = day == '전체' || tripDay(tripAt(t)) == day;
        final q = query.replaceAll(' ', '');
        final okQ = q.isEmpty || (t.place ?? t.title).replaceAll(' ', '').contains(q);
        return okDay && okQ;
      }).toList();
      final badge = nav.session?.tripBadge ?? 0;
      int pendingOf(TaskItem t) => nav.session?.receivedFor(t.id).length ?? 0;
      return ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('누가 가면,\n나도 하나!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.25)),
                SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 13.5, color: AppColors.sub, height: 1.55),
                    children: [
                      TextSpan(text: '가는 사람이 갈 곳을 찍어두면, 이웃이 '),
                      TextSpan(text: '“어! 나도!”', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                      TextSpan(text: ' 하고 필요한 걸 부탁해요.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: TripMap(
              trips: [...list, ...mine],
              scope: nav.session?.scope ?? '전국',
              height: 230,
              onOpen: (t) => openTrip(context, nav, t),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                TripRegisterButton(onTap: () => openTripRegister(context, nav)),
                const Spacer(),
                TripActivityLink(count: badge, onTap: () => openTripActivity(context, nav)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [for (final t in mine) MyTripCard(t: t, pending: pendingOf(t), onTap: () => openTrip(context, nav, t))],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            child: TextField(
              onChanged: (v) => setState(() => query = v.trim()),
              maxLength: 20,
              decoration: const InputDecoration(
                hintText: '장소로 찾기 · 예) 이마트',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                counterText: '',
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                for (final d in const ['전체', '오늘', '내일'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(d),
                      selected: day == d,
                      onSelected: (_) => setState(() => day = d),
                      showCheckmark: false,
                    ),
                  ),
                const Spacer(),
                Text('${list.length}건', style: const TextStyle(fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                if (list.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(18)),
                    child: const Text('조건에 맞는 일정이 없어요. 첫 일정을 올려 보세요!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.sub)),
                  ),
                for (final t in list) TripRow(t: t, onTap: () => openTrip(context, nav, t)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Material(
              color: AppColors.page,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => nav.openProposalList(context, abroad: false),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('멀리 가는 길에도 있어요', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('대전→서울, 도쿄처럼 지역 간 이동 제안', style: TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppColors.sub),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      color: AppColors.card,
      child: listen == null ? Builder(builder: body) : ListenableBuilder(listenable: listen, builder: (c, _) => body(c)),
    );
  }
}

/// '+ 나 여기 가요' 검은 버튼
class TripRegisterButton extends StatelessWidget {
  final VoidCallback onTap;
  const TripRegisterButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: const SizedBox(
          height: 34,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text('나 여기 가요', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// '내 활동 (2)' 링크
class TripActivityLink extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const TripActivityLink({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('내 활동', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.sub)),
            if (count > 0)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(9)),
                child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
