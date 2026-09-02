import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import 'map_view.dart';

class MapScreen extends StatelessWidget {
  final List<TaskItem> items;
  final String scope;
  final ErrandActions actions;
  const MapScreen({super.key, required this.items, required this.scope, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.page,
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          decoration: const BoxDecoration(color: AppColors.card, border: Border(bottom: BorderSide(color: AppColors.line))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                InkWell(onTap: () => Navigator.of(context).pop(), borderRadius: BorderRadius.circular(99), child: const Padding(padding: EdgeInsets.only(right: 2), child: Text('‹', style: TextStyle(fontSize: 24, color: AppColors.ink)))),
                const Text('지도', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ]),
              Padding(padding: const EdgeInsets.only(left: 22, top: 4), child: Text('${shortRegion(scope)} 주변 부탁', style: const TextStyle(fontSize: 12, color: AppColors.sub))),
            ],
          ),
        ),
        Expanded(child: MapView(items: items, scope: scope, actions: actions)),
      ]),
    );
  }
}
