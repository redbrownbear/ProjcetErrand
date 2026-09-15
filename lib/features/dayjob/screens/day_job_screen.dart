import 'package:flutter/material.dart';

import '../../../core/compliance/disclosures.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../data/day_jobs.dart';
import '../models/day_job.dart';
import '../widgets/day_job_card.dart';
import 'day_job_detail_screen.dart';

/// 단기알바 전체 화면.
/// 가이드 §6대로 공연·행사·전시 스태프와 단기알바를 하나의 카테고리로 묶었다.
class DayJobScreen extends StatefulWidget {
  final void Function(DayJob) onApply;
  const DayJobScreen({super.key, required this.onApply});
  @override
  State<DayJobScreen> createState() => _DayJobScreenState();
}

class _DayJobScreenState extends State<DayJobScreen> {
  String cat = 'all';

  @override
  Widget build(BuildContext context) {
    final list = List.of(dayJobsByCat(cat))..sort((a, b) => b.pay - a.pay);
    return ScreenFrame(
      title: '단기알바',
      subtitle: '오늘·이번 주에 끝나는 일만 모았어요',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in dayJobCats)
                    Padding(padding: const EdgeInsets.only(right: 7), child: ChipWidget(label: c[1], active: cat == c[0], onTap: () => setState(() => cat = c[0]))),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 6, 0, 10),
            child: Text('금액 높은 순 · 지급일과 준비물까지 목록에서 바로 확인할 수 있어요', style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
          ),
          for (final j in list) DayJobCard(j: j, onOpen: () => openDayJob(context, j, widget.onApply)),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(12)),
            child: Text(Disclosures.labor.body, style: const TextStyle(fontSize: 11.5, color: AppColors.blue, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

/// 공고 상세 열기. 홈 탭과 전체 화면이 같은 경로를 쓰게 한곳에 둔다.
void openDayJob(BuildContext context, DayJob j, void Function(DayJob) onApply) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => DayJobDetailScreen(j: j, onApply: () => onApply(j))));
}
