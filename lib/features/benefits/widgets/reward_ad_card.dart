import 'package:flutter/material.dart';

import '../../../core/ads/kakao_reward_ad.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/surface.dart';
import '../data/daily_missions.dart';
import '../models/reward_ledger.dart';
import '../services/mission_engine.dart';
import '../services/reward_ad_flow.dart';

/// 광고 보고 포인트 받기 — 카카오 애드핏 리워드 동영상만 쓴다.
///
/// 데일리 미션의 'ad'와 같은 적립 키를 쓰므로, 여기서 보든 '매일 미션' 화면에서 보든
/// 하루 한도가 함께 줄어든다.
class RewardAdCard extends StatelessWidget {
  final IsClaimedFn isClaimed;
  final EarnFn earn;
  final void Function(String) flash;
  const RewardAdCard({super.key, required this.isClaimed, required this.earn, required this.flash});

  @override
  Widget build(BuildContext context) {
    final s = MissionEngine(isClaimed).stateOf(dailyMissions.firstWhere((m) => m.id == 'ad'));
    final ready = !s.locked && KakaoRewardAd.configured;
    final (label, active) = s.done
        ? ('오늘 완료', false)
        : ready
        ? ('+${nf(s.m.points)}P 받기', true)
        : ('준비 중', false);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const IconTile(icon: 'play', bg: AppColors.yellowSoft, fg: AppColors.yellowInk),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('광고 보고 포인트 받기', style: AppType.body.copyWith(fontWeight: AppType.w700)),
                const SizedBox(height: 2),
                Text(
                  ready || s.done ? '카카오 광고 영상 · 오늘 ${s.claimed}/${s.m.cap}번' : '카카오 광고 연결을 준비 중이에요',
                  style: AppType.meta.copyWith(fontWeight: AppType.w500),
                ),
              ],
            ),
          ),
          Material(
            color: active ? AppColors.yellow : AppColors.page,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => RewardAdFlow(earn: earn, flash: flash).run(context, s),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: AppType.meta.copyWith(
                    fontSize: 13,
                    fontWeight: AppType.w700,
                    color: active ? AppColors.ink : AppColors.sub,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
