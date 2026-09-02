import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../errand/models/task_item.dart';

class ChatView extends StatelessWidget {
  final List<TaskItem> items;
  final List<int> grabbed;
  const ChatView({super.key, required this.items, required this.grabbed});
  @override
  Widget build(BuildContext context) {
    final chats = items.where((i) => grabbed.contains(i.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(22, 20, 22, 12), child: Text('채팅', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink))),
        if (chats.isEmpty)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text('아직 이어진 이웃이 없어요.\n부탁에 지원하거나 동행을 신청해보세요.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.sub, fontSize: 13.5, height: 1.7)),
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              children: chats.map((it) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                  child: Row(children: [
                    Container(
                      width: 46, height: 46, alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.page, shape: BoxShape.circle),
                      child: const Text('🙂', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.who, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                        ],
                      ),
                    ),
                    const Text('방금', style: TextStyle(fontSize: 11, color: AppColors.faint)),
                  ]),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
