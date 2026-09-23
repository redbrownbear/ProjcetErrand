import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/daily_mission.dart';
import '../models/mission_provider.dart';
import '../services/mission_engine.dart';

/// '가볍게 모으기' 목록의 한 줄.
///
/// 오른쪽 버튼 하나로 상태를 전부 말한다 — 받기 / 진행도 / 완료 / 준비 중.
/// 눌러도 되는지 아닌지가 색으로 먼저 읽히게 하고, 이유는 눌렀을 때 알려 준다.
class DailyMissionRow extends StatelessWidget {
  final MissionState s;
  final VoidCallback onTap;
  const DailyMissionRow({super.key, required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locked = s.locked;
    final done = s.done;

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: done ? AppColors.page : AppColors.card,
            border: Border.all(color: done ? AppColors.line : const Color(0xFFE9EBEF)),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? AppColors.line : AppColors.page,
                borderRadius: BorderRadius.circular(AppRadius.emblem),
              ),
              child: Text(s.m.icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(s.m.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.meta.copyWith(
                            fontSize: 14.5, fontWeight: AppType.w600, color: done ? AppColors.sub : AppColors.ink)),
                  ),
                  if (!done && !locked && s.m.cap > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text('${s.left}회 남음', style: AppType.caption.copyWith(color: AppColors.yellowDeep)),
                    ),
                ]),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(locked ? _lockedHint : s.m.sub,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            _right(done: done, locked: locked),
          ]),
        ),
      ),
    );
  }

  /// 잠긴 미션에는 무엇을 기다리는지 적는다. 사용자에게는 제휴 준비로만 보이고,
  /// 개발 중에는 어떤 키가 없는지 [MissionProvider.statusLabel]로 바로 보인다.
  String get _lockedHint => '${s.provider.name} · ${s.provider.statusLabel}';

  Widget _right({required bool done, required bool locked}) {
    if (done) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.green),
        const SizedBox(width: 5),
        Text('완료', style: AppType.caption.copyWith(color: AppColors.green, fontWeight: AppType.w600)),
      ]);
    }
    if (locked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.pillNeutral, borderRadius: BorderRadius.circular(AppRadius.chip)),
        child: Text('준비 중', style: AppType.caption.copyWith(color: AppColors.pillNeutralInk)),
      );
    }
    // 정해진 값이 있는 미션만 노란 '받기' 배지를 단다. 쿠팡·오퍼월처럼 얼마가
    // 들어올지 모르는 미션에 '+2,500P'를 박으면 실제 적립액과 어긋나므로,
    // 숫자 대신 기준(주문액의 1% · 캠페인마다 다름)을 그대로 보여 준다.
    final fixed = s.m.payout == PayoutKind.fixed;
    return Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: fixed ? AppColors.yellow : AppColors.pillNeutral,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(fixed ? '+${nf(s.m.points)}P' : s.m.payoutLabel,
            style: AppType.button.copyWith(fontSize: 12.5, color: fixed ? AppColors.ink : AppColors.pillNeutralInk)),
      ),
      if (s.statusLabel.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(s.statusLabel, style: AppType.caption.copyWith(fontSize: 10.5)),
        ),
    ]);
  }
}
