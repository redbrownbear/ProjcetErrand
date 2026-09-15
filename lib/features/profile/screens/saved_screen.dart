import 'package:flutter/material.dart';

import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/section_header.dart';
import '../../community/widgets/community_card.dart';
import '../../errand/models/task_item.dart';
import '../../errand/navigation/errand_actions.dart';
import '../../errand/widgets/task_card.dart';

/// 마이 > 관심 저장. 상세 화면의 책갈피로 저장한 부탁·모임.
class SavedScreen extends StatelessWidget {
  final List<TaskItem> items;
  final List<int> bookmarks;
  final ErrandActions actions;
  const SavedScreen({super.key, required this.items, required this.bookmarks, required this.actions});

  @override
  Widget build(BuildContext context) {
    final saved = items.where((i) => bookmarks.contains(i.id)).toList();
    return ScreenFrame(
      title: '관심 저장',
      subtitle: '상세 화면의 책갈피로 저장한 부탁',
      onBack: () => Navigator.of(context).pop(),
      child: saved.isEmpty
          ? const Center(child: EmptyState(msg: '저장한 부탁이 없어요.\n상세 화면의 🔖를 눌러 보관하세요.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final it in saved)
                  it.mode == 'together'
                      ? CommunityCard(it: it, onOpen: () => actions.open(context, it), compact: true)
                      : TaskCard(it: it, onOpen: () => actions.open(context, it), done: actions.grabbed.contains(it.id)),
              ],
            ),
    );
  }
}
