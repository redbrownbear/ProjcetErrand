import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/partner_mission.dart';

class PartnerCard extends StatelessWidget {
  final PartnerMission m;
  final bool done;
  final VoidCallback onOpen;
  const PartnerCard({super.key, required this.m, required this.done, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 194,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(11)), child: Text(m.icon, style: const TextStyle(fontSize: 19))),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('제휴 · ${m.brand}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.purple)),
                    Padding(padding: const EdgeInsets.only(top: 1), child: Text('${m.time} · ${m.reason}', style: const TextStyle(fontSize: 10.5, color: AppColors.faint), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(height: 36, child: Text(m.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 좌담회처럼 자릿수가 큰 미션(+50,000P)이 오면 '참여하기' 칩과
                  // 부딪힌다. 카드 폭이 고정이라 숫자 쪽을 줄여서 받아낸다.
                  Flexible(
                    child: Text(done ? '적립 완료' : '+${nf(m.points)}P',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: done ? AppColors.green : AppColors.blue)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(color: done ? AppColors.greenSoft : AppColors.yellow, borderRadius: BorderRadius.circular(9)),
                    child: Text(done ? '✓' : '참여하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: done ? AppColors.green : AppColors.ink)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
