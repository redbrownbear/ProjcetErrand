import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/partner_mission.dart';

class EarnRowFull extends StatelessWidget {
  final PartnerMission m;
  final bool done;
  final VoidCallback onOpen;
  const EarnRowFull({super.key, required this.m, required this.done, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: done ? AppColors.greenSoft : AppColors.line), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(13)), child: Text(m.icon, style: const TextStyle(fontSize: 26))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('제휴 · ${m.brand}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.purple)),
                Padding(padding: const EdgeInsets.only(top: 1), child: Text(m.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                Padding(padding: const EdgeInsets.only(top: 2), child: Text('${m.time} · ${m.reason}', style: const TextStyle(fontSize: 11.5, color: AppColors.sub))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(done ? '적립완료' : '+${nf(m.points)}P', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: done ? AppColors.green : AppColors.ink)),
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: done ? AppColors.greenSoft : AppColors.yellow, borderRadius: BorderRadius.circular(8)),
                child: Text(done ? '✓' : '참여하기', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: done ? AppColors.green : AppColors.ink)),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
