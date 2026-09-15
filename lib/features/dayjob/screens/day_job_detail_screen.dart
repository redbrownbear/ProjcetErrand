import 'package:flutter/material.dart';

import '../../../core/compliance/disclosures.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/screen_frame.dart';
import '../models/day_job.dart';

/// 일감 상세. 가이드 §11이 요구한 7가지 정보를 접거나 숨기지 않고 한 화면에 전부 편다.
class DayJobDetailScreen extends StatelessWidget {
  final DayJob j;
  final VoidCallback onApply;
  const DayJobDetailScreen({super.key, required this.j, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: '단기알바',
      subtitle: '${j.cat} · ${j.org}',
      onBack: () => Navigator.of(context).pop(),
      child: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            Row(children: [
              Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(18)), child: Text(j.icon, style: const TextStyle(fontSize: 32))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${j.source} · ${j.org}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.blue)),
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text(j.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.3))),
                  ],
                ),
              ),
            ]),

            // 가장 먼저 보여야 할 값: 얼마를 언제 받는가
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.payKind, style: const TextStyle(fontSize: 12.5, color: Colors.white60)),
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text(won(j.pay), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.yellow))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('지급일', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text(j.payDate, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white))),
                  ],
                ),
              ]),
            ),

            const Padding(padding: EdgeInsets.fromLTRB(0, 18, 0, 8), child: Text('일하기 전에 꼭 보는 정보', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                for (final e in [
                  ['⏱', '예상 시간', j.hours],
                  ['📍', '위치', j.place],
                  ['📅', '지급일', j.payDate],
                  ['💪', '업무 난이도', j.level],
                  ['🎒', '준비물', j.gear],
                  ['🪪', '신원확인', j.idCheck],
                  ['🗂', '공고 출처', j.source],
                  ['⏳', '마감', j.closing],
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e[0], style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      SizedBox(width: 76, child: Text(e[1], style: const TextStyle(fontSize: 12.5, color: AppColors.sub))),
                      Expanded(child: Text(e[2], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.4))),
                    ]),
                  ),
              ]),
            ),

            const Padding(padding: EdgeInsets.fromLTRB(0, 18, 0, 6), child: Text('업무 안내', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
              child: Text(j.desc, style: const TextStyle(fontSize: 13.5, color: Color(0xFF3A3D42), height: 1.6)),
            ),

            // 근로계약 주체를 흐리지 않는다 (§11)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(bottom: 5), child: Text('ℹ️ ${Disclosures.labor.label}', style: const TextStyle(fontSize: 11.5, color: AppColors.blue, fontWeight: FontWeight.w800))),
                  Text(Disclosures.labor.body, style: const TextStyle(fontSize: 12, color: AppColors.blue, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('${j.payKind} ${won(j.pay)} · 지원하기', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
