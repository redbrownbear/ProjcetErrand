import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/section_header.dart';
import '../../errand/models/task_item.dart';
import '../data/categories.dart';
import '../widgets/community_card.dart';

class CommunityScreen extends StatefulWidget {
  final List<TaskItem> items;
  final String scope;
  final String? initCat;
  final VoidCallback onClose;
  final void Function(TaskItem) openDetail;
  const CommunityScreen({
    super.key, required this.items, required this.scope, this.initCat,
    required this.onClose, required this.openDetail,
  });
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late String tc = widget.initCat ?? 'all';

  bool _inScope(TaskItem i) => widget.scope == '전국' || i.region == widget.scope;

  @override
  Widget build(BuildContext context) {
    var feed = widget.items.where((i) => i.mode == 'together' && _inScope(i)).toList();
    if (tc != 'all') feed = feed.where((i) => i.tcat == tc).toList();

    return ScreenFrame(
      title: '같이해요',
      subtitle: '${shortRegion(widget.scope)} 동네생활',
      onBack: widget.onClose,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: '전체', active: tc == 'all', onTap: () => setState(() => tc = 'all'))),
                for (final c in tcats)
                  Padding(padding: const EdgeInsets.only(right: 6), child: ChipWidget(label: '${c.icon} ${c.label}', active: tc == c.k, onTap: () => setState(() => tc = c.k))),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(12)),
            child: const Text('🛡 안전한 장소에서 만나요 · 공개된 장소 권장 · 개인 연락처 노출 최소화 · 앱 내 채팅 이용 · 신고/차단 제공', style: TextStyle(fontSize: 11.5, color: Color(0xFF1B8A5A), fontWeight: FontWeight.w500, height: 1.55)),
          ),
          if (feed.isEmpty)
            const EmptyState(msg: '이 카테고리엔 아직 글이 없어요.')
          else
            for (final it in feed) CommunityCard(it: it, onOpen: () => widget.openDetail(it)),
        ],
      ),
    );
  }
}
