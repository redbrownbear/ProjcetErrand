import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../models/trust_level.dart';

/// 신뢰 레벨 안내 시트.
///
/// 계산 근거([TrustLevel.rule])를 그대로 보여 준다. 왜 올랐는지 모르는 숫자는
/// 신뢰가 아니라 의심을 만든다.
void showTrustSheet(BuildContext context, TrustLevel trust) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.surface))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _TrustDetail(trust: trust),
      ),
    ),
  );
}

class _TrustDetail extends StatelessWidget {
  final TrustLevel trust;
  const _TrustDetail({required this.trust});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: trust.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.emblem),
              ),
              child: Text('Lv.${trust.level}', style: AppType.price.copyWith(fontSize: 14, color: trust.color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('신뢰 레벨', style: AppType.caption),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(trust.name, style: AppType.section.copyWith(fontSize: 17, color: trust.color)),
                  ),
                ],
              ),
            ),
            Text('${trust.score}점', style: AppType.price.copyWith(fontSize: 15)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: trust.progress,
              minHeight: 6,
              backgroundColor: AppColors.page,
              valueColor: AlwaysStoppedAnimation(trust.color),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  trust.isFresh ? '첫 거래를 마치면 레벨이 올라가요' : trust.nextHint,
                  style: AppType.caption.copyWith(fontWeight: AppType.w600, color: trust.color),
                ),
              ),
              if (!trust.isMax) Text(_nextTierLabel, style: AppType.caption),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(TrustLevel.rule, style: AppType.caption.copyWith(height: 1.6)),
        ),
      ],
    );
  }

  String get _nextTierLabel {
    final next = TrustLevel.tiers.firstWhere((t) => t.$2 == trust.level + 1);
    return 'Lv.${next.$2} ${next.$3}';
  }
}
