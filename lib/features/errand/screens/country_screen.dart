import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/section_header.dart';
import '../data/countries.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import '../widgets/task_card.dart';

class CountryScreen extends StatefulWidget {
  final String cc;
  final List<TaskItem> items;
  final ErrandActions actions;
  const CountryScreen({super.key, required this.cc, required this.items, required this.actions});
  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  String city = 'all';

  @override
  Widget build(BuildContext context) {
    final country = countryOf(widget.cc);
    var list = widget.items.where((i) => i.mode == 'sea' && i.cc == widget.cc).toList();
    if (city != 'all') list = list.where((i) => i.city == city).toList();

    return ScreenFrame(
      title: '${country.flag} ${country.name}',
      subtitle: '해외 대행 마켓',
      onBack: () => Navigator.of(context).pop(),
      accent: AppColors.purple,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: '전체', active: city == 'all', onTap: () => setState(() => city = 'all'))),
                for (final ci in country.cities)
                  Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: ci, active: city == ci, onTap: () => setState(() => city = ci))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            EmptyState(msg: '${country.name}${city != 'all' ? ' $city' : ''}에 아직 올라온 부탁이 없어요.\n첫 부탁을 올려보세요!')
          else
            for (final it in list) TaskCard(it: it, onOpen: () => widget.actions.open(context, it), done: widget.actions.grabbed.contains(it.id), rich: true),
        ],
      ),
    );
  }
}
