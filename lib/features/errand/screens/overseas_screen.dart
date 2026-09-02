import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/section_header.dart';
import '../../benefits/data/point_rules.dart';
import '../data/countries.dart';
import '../models/task_item.dart';
import '../navigation/errand_actions.dart';
import '../widgets/task_card.dart';
import 'country_screen.dart';

class OverseasScreen extends StatefulWidget {
  final List<TaskItem> items;
  final ErrandActions actions;
  const OverseasScreen({super.key, required this.items, required this.actions});
  @override
  State<OverseasScreen> createState() => _OverseasScreenState();
}

class _OverseasScreenState extends State<OverseasScreen> {
  final qCtrl = TextEditingController();

  @override
  void dispose() {
    qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sea = widget.items.where((i) => i.mode == 'sea').toList();
    final q = qCtrl.text.trim().toLowerCase();
    final results = q.isEmpty
        ? sea
        : sea.where((i) => ('${i.title}${i.country ?? ''}${i.place ?? ''}').toLowerCase().contains(q)).toList();

    return ScreenFrame(
      title: '해외 대행',
      subtitle: '여행·출장 중인 이웃이 대신 사다줘요 · 최소 ${nf(seaMin)}원',
      onBack: () => Navigator.of(context).pop(),
      accent: AppColors.purple,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          TextField(
            controller: qCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '🔍 나라·품목·매장 검색',
              filled: true, fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(0, 14, 0, 8), child: Text('어느 나라에서 필요하세요?', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink))),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8, crossAxisSpacing: 8,
            childAspectRatio: 0.92,
            children: countries.map((c) {
              final cnt = sea.where((i) => i.cc == c.cc).length;
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CountryScreen(cc: c.cc, items: widget.items, actions: widget.actions))),
                borderRadius: BorderRadius.circular(12),
                child: Stack(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      Text(c.flag, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 3),
                      Text(c.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ]),
                  ),
                  if (cnt > 0)
                    Positioned(
                      top: 5, right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(99)),
                        child: Text('$cnt', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.purple)),
                      ),
                    ),
                ]),
              );
            }).toList(),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(12)),
            child: const Text('✈️ 물건값은 영수증으로 정산, 사례비는 별도예요. 완료 확인 전까지 앱이 안전하게 보관해요.', style: TextStyle(fontSize: 11.5, color: AppColors.purple, fontWeight: FontWeight.w500, height: 1.55)),
          ),
          const Text('지금 올라온 해외 부탁', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 10),
          if (results.isEmpty)
            const EmptyState(msg: '검색 결과가 없어요.')
          else
            for (final it in results) TaskCard(it: it, onOpen: () => widget.actions.open(context, it), done: widget.actions.grabbed.contains(it.id), rich: true),
        ],
      ),
    );
  }
}
