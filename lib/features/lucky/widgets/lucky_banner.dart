import 'package:flutter/material.dart';

import '../../../app/app_nav.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/kit.dart';
import '../models/tickets.dart';

/// 마켓 맨 위 럭키드로우 띠 (.sld)
class LuckyBanner extends StatelessWidget {
  final AppNav nav;
  const LuckyBanner({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    final draw = LuckyDraw(DateTime.now());
    return ListenableBuilder(
      listenable: nav.store,
      builder: (context, _) => Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFF3C4), Color(0xFFFFE7A0)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.liveLine),
        ),
        child: Tap(
          onTap: () => nav.openLucky(context),
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                  child: Transform.rotate(angle: -0.5, child: const Icon(Icons.flight_rounded, color: AppColors.blue, size: 28)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${draw.month}월 LUCKY DRAW',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.yellowDeep,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              'D-${draw.dday}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.yellow),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '미션 하고 도쿄 왕복 항공권 + 호텔 받아가세요',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '미션마다 응모권 +1~+5 · 내 응모권 ${nav.store.wallet.have}장',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(11)),
                  child: const Text(
                    '응모',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.yellow),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
