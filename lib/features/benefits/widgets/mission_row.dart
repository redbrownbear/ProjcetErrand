import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class MissionRow extends StatelessWidget {
  final String icon, label;
  final int points;
  final String? sub;
  final String? cta;
  final List<int>? prog; // [current, total]
  final bool done;
  final VoidCallback? onClaim;
  const MissionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.points,
    this.sub,
    this.cta,
    this.prog,
    this.done = false,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
      child: Row(children: [
        Container(
          width: 38, height: 38, alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(11)),
          child: Text(icon, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  children: [
                    TextSpan(text: label),
                    TextSpan(text: ' +${points}P', style: const TextStyle(color: AppColors.blue)),
                  ],
                ),
              ),
              if (sub != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(sub!, style: const TextStyle(fontSize: 11.5, color: AppColors.sub))),
              if (prog != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: prog![0] / prog![1], minHeight: 5,
                          backgroundColor: AppColors.page, color: AppColors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text('${prog![0]}/${prog![1]}', style: const TextStyle(fontSize: 11, color: AppColors.sub, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ],
          ),
        ),
        if (cta != null)
          InkWell(
            onTap: done ? null : onClaim,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(color: done ? AppColors.greenSoft : AppColors.ink, borderRadius: BorderRadius.circular(9)),
              child: Text(done ? '완료 ✓' : cta!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: done ? AppColors.green : Colors.white)),
            ),
          ),
      ]),
    );
  }
}
