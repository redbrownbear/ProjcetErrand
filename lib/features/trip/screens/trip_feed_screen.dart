import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../widgets/trip_widgets.dart';

/// 가는 김에 — 전체보기
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
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) {
        final list = nav.store.trips.where((t) => f == 0 || (f == 1 ? t.going : !t.going)).toList();
        return PageFrame(
          title: '가는 김에',
          bottom: BigButton(label: '가는 김에 글쓰기', icon: 'pencil', onTap: () => nav.openTripForm(context)),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text('사람들은 지금 어디로 가고 있을까요?', style: TextStyle(fontSize: 13, color: AppColors.sub)),
              ),
              ChipRow(labels: const ['전체', '가요', '찾아요'], index: f, onChanged: (i) => setState(() => f = i)),
              const SizedBox(height: 10),
              for (final t in list)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: TripCard(
                    t: t,
                    onCta: () => t.going ? nav.openAskForm() : nav.flash('도와주기 의사를 전했어요 · ${t.author} 님이 확인하면 채팅이 열려요'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
