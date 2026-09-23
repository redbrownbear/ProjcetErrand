import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/fact_rows.dart';
import '../../../core/widgets/screen_frame.dart';
import '../models/job_posting.dart';

/// 내가 올린 단기알바 모집글 상세. 시안(`gyumsa-refined`)의 `GyJobDetail`.
///
/// 지원자가 지원 전에 알아야 할 근로 조건을 한 줄씩 그대로 보여준다.
class JobPostingDetailScreen extends StatelessWidget {
  final JobPosting job;
  const JobPostingDetailScreen({super.key, required this.job});

  static String _dt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  static String _day(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('회사명', job.company),
      ('회사 주소', job.companyAddress),
      if (job.businessNo.isNotEmpty) ('사업자등록번호', '${job.businessNo} · 확인 전'),
      ('근무 방식', job.workType),
      ('근무 장소', job.location),
      ('근무 시작', _dt(job.start)),
      ('근무 종료', _dt(job.end)),
      ('휴게시간', '${job.breakMin}분'),
      ('반복 일정', job.schedule.isEmpty ? '없음' : job.schedule),
      ('지원 조건', job.requirements.isEmpty ? '별도 조건 없음' : job.requirements),
      ('제공 혜택', job.benefits.isEmpty ? '별도 제공 없음' : job.benefits),
      ('급여 조건', job.payNote.isEmpty ? '별도 기재 없음' : job.payNote),
      ('지원 마감', _dt(job.deadline)),
      ('담당자', job.contact),
      ('지원 방법', job.contactLine),
    ];

    return ScreenFrame(
      title: '단기알바 상세',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
        children: [
          Text('${job.company} · ${job.headcount}명 모집',
              style: AppType.caption.copyWith(fontSize: 11, color: AppColors.greetingPoint)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(job.title, style: AppType.section.copyWith(fontSize: 22, height: 1.4, color: AppColors.attendTitle)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(job.payType, style: AppType.meta.copyWith(fontSize: 13)),
              Text('${nf(job.pay)}원',
                  style: AppType.section.copyWith(fontSize: 20, color: AppColors.green)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('세전 기준 · ${_day(job.payDate)} 지급 예정', style: AppType.caption.copyWith(fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
            child: Text('하는 일', style: AppType.sectionSmall.copyWith(fontSize: 16)),
          ),
          Text(job.desc, style: AppType.body.copyWith(fontSize: 13, height: 1.8, color: AppColors.sub)),
          const SizedBox(height: 14),
          FactRows(rows),
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(12)),
            child: Text('내가 등록한 모집글입니다. 실제 지원 접수는 연동 전이에요.',
                style: AppType.meta.copyWith(fontSize: 12, height: 1.8, color: AppColors.goalMintInk)),
          ),
        ],
      ),
    );
  }
}
