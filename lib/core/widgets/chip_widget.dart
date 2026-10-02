import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// 목록 상단의 필터 칩 (시안 v33 `.chip`).
///
/// 흰 바탕에 옅은 테두리, 선택되면 먹색으로 찬다. [pill]은 예전 홈 칩 자리에서
/// 쓰던 이름이라 남겨 두었고, 지금은 높이만 조금 더 크다.
class ChipWidget extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool pill;
  const ChipWidget({super.key, required this.label, this.active = false, this.onTap, this.pill = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Container(
        constraints: BoxConstraints(minHeight: pill ? 34 : 32),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.chipSelected : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: active ? AppColors.chipSelected : AppColors.soft2),
        ),
        child: Text(
          label,
          style: AppType.meta.copyWith(
            fontSize: 12.5,
            fontWeight: AppType.w600,
            color: active ? Colors.white : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

/// 상태 배지 (.pill). [neutral]이면 회색, 아니면 시안의 노란 배지.
class PillTag extends StatelessWidget {
  final String label;
  final bool neutral;
  const PillTag({super.key, required this.label, this.neutral = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: neutral ? AppColors.pillNeutral : AppColors.pill,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: AppType.caption.copyWith(
          fontSize: 12,
          fontWeight: AppType.w600,
          color: neutral ? AppColors.pillNeutralInk : AppColors.pillInk,
        ),
      ),
    );
  }
}
