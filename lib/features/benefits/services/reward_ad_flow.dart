import 'package:flutter/material.dart';

import '../../../core/ads/kakao_reward_ad.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/reward_ledger.dart';
import 'mission_engine.dart';

/// 광고 보고 포인트 받기 — 카카오 애드핏 리워드 동영상 한 번.
///
/// 애드핏 운영정책 5.3.3을 그대로 따른다.
/// 1. **자발적 참여(Opt-in)**: 사용자가 '광고 보고 받기'를 직접 눌렀을 때만 띄운다.
///    자동 재생하거나 다른 행동 중간에 끼워 넣지 않는다.
/// 2. **보상 안내**: 보상 조건 · 지급 여부 · 지급 시점 · 지급 제외 사유를 영상 **전에** 보여 준다.
///
/// 적립은 SDK가 '끝까지 봤다'고 알려 준 경우에만 한다([RewardAdResult.earned]).
/// 회차마다 적립 키가 달라서([MissionState.claimed]), 같은 회차를 두 번 받을 수 없다.
class RewardAdFlow {
  final EarnFn earn;
  final void Function(String) flash;
  final KakaoRewardAd ad;

  const RewardAdFlow({required this.earn, required this.flash, this.ad = const KakaoRewardAd()});

  /// 시청 전 안내에 쓰는 문구. 상세 화면·테스트에서도 같은 문장을 쓴다.
  static List<(String, String)> notice(MissionState s) => [
        ('보상 조건', '광고 영상을 끝까지 보면 받아요'),
        ('지급', '+${nf(s.m.points)}P · 시청이 끝나는 즉시 포인트로 들어와요'),
        ('하루 한도', '${s.m.cap}번까지 · 오늘 ${s.left}번 남았어요'),
        ('지급 제외', '중간에 닫았을 때, 보여 줄 광고가 없을 때, 한도를 넘겼을 때, 비정상적인 반복 시청으로 확인될 때'),
      ];

  Future<void> run(BuildContext context, MissionState s) async {
    if (s.done) {
      flash('오늘 광고 적립은 다 받았어요 · 내일 다시 볼 수 있어요');
      return;
    }
    if (!ad.isReady) {
      flash('카카오 광고 연결을 준비 중이에요');
      return;
    }

    final agreed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheet) => _NoticeSheet(rows: notice(s), onWatch: () => Navigator.of(sheet).pop(true)),
    );
    if (agreed != true) return;

    final result = await ad.show();
    switch (result) {
      case RewardAdResult.earned:
        await earn(s.m.points, '광고 보고 적립', key: s.m.ledgerKey(s.claimed), daily: s.m.daily);
      case RewardAdResult.skipped:
        flash('끝까지 보지 않아 적립되지 않았어요');
      case RewardAdResult.noFill:
        flash('지금은 보여 드릴 광고가 없어요 · 잠시 후 다시 시도해 주세요');
      case RewardAdResult.unavailable:
        flash('카카오 광고 연결을 준비 중이에요');
    }
  }
}

/// 시청 전 안내 시트 (Opt-in)
class _NoticeSheet extends StatelessWidget {
  final List<(String, String)> rows;
  final VoidCallback onWatch;
  const _NoticeSheet({required this.rows, required this.onWatch});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.surface)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('광고 보고 포인트 받기', style: AppType.section),
          Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 14),
            child: Text('카카오 애드핏 광고 영상이 재생돼요', style: AppType.caption),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(AppRadius.tile)),
            child: Column(children: [
              for (final (k, v) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 64, child: Text(k, style: AppType.meta.copyWith(fontWeight: AppType.w600))),
                    Expanded(child: Text(v, style: AppType.meta.copyWith(color: AppColors.ink2, height: 1.5))),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onWatch, child: const Text('광고 보고 받기')),
          ),
          Center(
            child: TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('다음에 할게요')),
          ),
        ]),
      ),
    );
  }
}
