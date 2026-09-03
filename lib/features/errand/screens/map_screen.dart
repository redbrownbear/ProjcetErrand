import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
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
      child: MapView(items: items, scope: scope, actions: actions),
    );
  }
}
