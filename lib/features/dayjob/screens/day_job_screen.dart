import 'package:flutter/material.dart';

import '../../../core/compliance/disclosures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chip_widget.dart';
import '../../../core/widgets/screen_frame.dart';
import '../data/day_jobs.dart';
import '../models/day_job.dart';
import '../models/job_posting.dart';
import '../repositories/job_posting_repository.dart';
import '../widgets/day_job_card.dart';
import 'day_job_detail_screen.dart';
import 'job_posting_detail_screen.dart';

/// 단기알바 전체 화면.
/// 가이드 §6대로 공연·행사·전시 스태프와 단기알바를 하나의 카테고리로 묶었다.
class DayJobScreen extends StatefulWidget {
  final void Function(DayJob) onApply;

  /// 단기알바 모집 등록. 시안(`gyumsa-refined`)의 '알바 모집하기 +'.
  final VoidCallback? onPost;
  const DayJobScreen({super.key, required this.onApply, this.onPost});
  @override
  State<DayJobScreen> createState() => _DayJobScreenState();
}

class _DayJobScreenState extends State<DayJobScreen> {
  String cat = 'all';
  List<JobPosting> postings = JobPostingRepository.load();

  Future<void> _post() async {
    widget.onPost?.call();
    // 등록 화면은 셸이 띄운다. 돌아오면 내가 올린 모집글을 다시 읽는다.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => postings = JobPostingRepository.load());
  }

  @override
  Widget build(BuildContext context) {
    final list = List.of(dayJobsByCat(cat))..sort((a, b) => b.pay - a.pay);
    final mine = postings.where((p) => !p.closed).toList();
    return ScreenFrame(
      title: '단기알바',
      subtitle: '오늘·이번 주에 끝나는 일만 모았어요',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          if (widget.onPost != null) ...[
            Row(children: [
              Expanded(child: Text('내가 올린 모집 ${mine.length}건', style: AppType.sectionSmall.copyWith(fontSize: 13))),
              TextButton(
                onPressed: _post,
                style: TextButton.styleFrom(foregroundColor: AppColors.green, minimumSize: const Size(0, 34)),
                child: Text('알바 모집하기 +', style: AppType.caption.copyWith(fontSize: 12, color: AppColors.green)),
              ),
            ]),
            for (final p in mine) _MyPostingCard(job: p),
            const SizedBox(height: 10),
          ],
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

/// 내가 올린 모집글 카드 (.g2-job-card)
class _MyPostingCard extends StatelessWidget {
  final JobPosting job;
  const _MyPostingCard({required this.job});

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final start = '${job.start.year}.${two(job.start.month)}.${two(job.start.day)} ${two(job.start.hour)}:${two(job.start.minute)}';
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobPostingDetailScreen(job: job))),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${job.company} · ${job.headcount}명 모집', style: AppType.caption.copyWith(fontSize: 11)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(job.title, style: AppType.sectionSmall.copyWith(fontSize: 16)),
          ),
          Text('$start · ${job.location}', style: AppType.caption.copyWith(fontSize: 11)),
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text('${job.payType} ${nf(job.pay)}원',
                style: AppType.body.copyWith(fontSize: 14, fontWeight: AppType.w700, color: AppColors.green)),
          ),
        ]),
      ),
    );
  }
}

/// 공고 상세 열기. 홈 탭과 전체 화면이 같은 경로를 쓰게 한곳에 둔다.
void openDayJob(BuildContext context, DayJob j, void Function(DayJob) onApply) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => DayJobDetailScreen(j: j, onApply: () => onApply(j))));
}
