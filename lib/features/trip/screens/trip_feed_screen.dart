import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../../errand/widgets/task_card.dart';
import '../widgets/trip_widgets.dart';

/// 가는 김에 — 전체보기. '지금 내 주변 부탁'과 같은 줄 모양으로 보여 준다.
class TripFeedScreen extends StatefulWidget {
  final AppNav nav;
  const TripFeedScreen({super.key, required this.nav});

  @override
  State<TripFeedScreen> createState() => _TripFeedScreenState();
}

class _TripFeedScreenState extends State<TripFeedScreen> {
  int f = 0;

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    final actions = nav.actions();
    final changes = actions.changes;
    Widget body(BuildContext context) {
      final all = tripItems(nav);
      final list = all.where((t) => f == 0 || (f == 1 ? t.isGoing : !t.isGoing)).toList();
      final grabbed = nav.actions().grabbed;
      return ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text('사람들은 지금 어디로 가고 있을까요?', style: TextStyle(fontSize: 13, color: AppColors.sub)),
          ),
          ChipRow(labels: const ['전체', '제가 가요', '가는 분 찾아요'], index: f, onChanged: (i) => setState(() => f = i)),
          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text('아직 글이 없어요', style: TextStyle(color: AppColors.faint)),
                  ),
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
        ],
      );
    }

    return PageFrame(
      title: '가는 김에',
      bottom: Row(
        children: [
          Expanded(child: BigButton(label: '제가 가요', icon: 'pencil', onTap: () => nav.openTripPost(going: true))),
          const SizedBox(width: 8),
          Expanded(
            child: BigButton(label: '가는 분 찾아요', bg: AppColors.ink, fg: Colors.white, onTap: () => nav.openTripPost(going: false)),
          ),
        ],
      ),
      child: changes == null ? Builder(builder: body) : ListenableBuilder(listenable: changes, builder: (c, _) => body(c)),
    );
  }
}
