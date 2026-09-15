import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/day_job.dart';

/// 단기알바 공고 카드. 홈의 단기알바 탭과 단기알바 전체 화면이 같은 카드를 쓴다.
///
/// 가이드 §11이 "화면에 전면 표시"하라고 한 항목(지급일·난이도·준비물·신원확인)을
/// 상세로 숨기지 않고 목록에서도 칩으로 보여준다.
class DayJobCard extends StatelessWidget {
  final DayJob j;
  final VoidCallback onOpen;

  /// 홈처럼 좁은 자리에서는 칩 줄을 생략해 목록이 길어지지 않게 한다.
  final bool compact;

  const DayJobCard({super.key, required this.j, required this.onOpen, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(13)), child: Text(j.icon, style: const TextStyle(fontSize: 24))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${j.cat} · ${j.org}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.blue)),
                    Padding(padding: const EdgeInsets.only(top: 1), child: Text(j.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('${j.hours} · ${j.region}', style: const TextStyle(fontSize: 11.5, color: AppColors.sub))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(won(j.pay), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text(j.payKind, style: const TextStyle(fontSize: 11, color: AppColors.sub))),
                ],
              ),
            ]),
            if (!compact)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final t in ['💵 ${j.payDate}', '💪 ${j.level}', '🎒 ${j.gear}', '🪪 ${j.idCheck}'])
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(8)),
                      child: Text(t, style: const TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w600)),
                    ),
                ]),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('💵 ${j.payDate} · 🪪 ${j.idCheck}', style: const TextStyle(fontSize: 11, color: AppColors.sub)),
              ),
          ],
        ),
      ),
    );
  }
}
