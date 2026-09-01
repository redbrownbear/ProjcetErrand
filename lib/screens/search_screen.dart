import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../widgets/community_card.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_header.dart';
import '../widgets/task_card.dart';

class SearchScreen extends StatefulWidget {
  final List<TaskItem> items;
  final List<int> grabbed;
  final VoidCallback onClose;
  final void Function(TaskItem) openDetail;
  const SearchScreen({super.key, required this.items, required this.grabbed, required this.onClose, required this.openDetail});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final qCtrl = TextEditingController();
  static const suggestions = ['줄서기', '성심당', '재고 사진', '택배', '돈키호테', '영양제', '강아지', '영화'];

  @override
  void dispose() {
    qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final term = qCtrl.text.trim().toLowerCase();
    final results = term.isEmpty
        ? <TaskItem>[]
        : widget.items.where((i) => ('${i.title} ${i.desc} ${catOf(i.cat).label} ${i.country ?? ''} ${i.region ?? ''}').toLowerCase().contains(term)).toList();

    return ScreenFrame(
      title: '검색',
      onBack: widget.onClose,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          TextField(
            controller: qCtrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '🔍 줄서기, 사오기, 사진, 대행, 영화 같이…',
              filled: true, fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            ),
          ),
          if (term.isEmpty) ...[
            const Padding(padding: EdgeInsets.fromLTRB(0, 14, 0, 9), child: Text('추천 검색어', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink))),
            Wrap(
              spacing: 7, runSpacing: 7,
              children: [
                for (final s in suggestions)
                  InkWell(
                    onTap: () {
                      qCtrl.text = s;
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: AppColors.line), color: AppColors.card),
                      child: Text(s, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (term.isNotEmpty && results.isEmpty) const EmptyState(msg: '검색 결과가 없어요. 다른 키워드로 찾아보세요.'),
          for (final it in results)
            it.mode == 'together'
                ? CommunityCard(it: it, onOpen: () => widget.openDetail(it))
                : TaskCard(it: it, onOpen: () => widget.openDetail(it), done: widget.grabbed.contains(it.id), rich: true),
        ],
      ),
    );
  }
}
