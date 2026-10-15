import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../models/tickets.dart';

/// 마이의 '내 응모권' 카드 — 누르면 이달의 럭키드로우로 간다.
class LuckyCard extends StatelessWidget {
  final AppNav nav;
  const LuckyCard({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) {
        final w = nav.store.wallet;
        final draw = LuckyDraw(DateTime.now());
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
          child: Tap(
            onTap: () => nav.openLucky(context),
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.confirmation_number_outlined, color: AppColors.yellowDeep, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('내 응모권 ${w.have}장', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          '${draw.month}월 럭키드로우 · 이번 달 응모 ${w.entered}장',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'D-${draw.dday}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sub),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
