import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../models/tickets.dart';

/// 겸이 옆 말풍선 — 이달의 럭키드로우로 이어진다 (v77 '겸이의 말풍선').
///
/// [HeroCard]의 `bubble`에 넣는다. [reward]는 이 탭에서 한 일로 받는 응모권 문구다.
class LuckyBubble extends StatelessWidget {
  final String reward;
  final VoidCallback onTap;
  const LuckyBubble({super.key, required this.reward, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final draw = LuckyDraw(DateTime.now());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 176),
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.yellowLine),
          boxShadow: const [BoxShadow(color: Color(0x59785A00), blurRadius: 16, spreadRadius: -6, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 11, color: AppColors.yellowDeep),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    draw.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.yellowDeep,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${LuckyDraw.prizes.first.title} 추첨 중!',
              maxLines: 2,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 1),
            Text(
              reward,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.sub),
            ),
          ],
        ),
      ),
    );
  }
}
