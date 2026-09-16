import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// 목록 상단의 필터 칩 (기획 시안 v9 `.chip`).
///
/// [pill]을 켜면 홈의 빠른 종류 칩(`.quick-task-categories`)이 된다 —
/// 더 둥글고 조금 크며, 선택 시 따뜻한 먹색으로 찬다.
class ChipWidget extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool pill;
  const ChipWidget({super.key, required this.label, this.active = false, this.onTap, this.pill = false});

  @override
  Widget build(BuildContext context) {
    final radius = pill ? AppRadius.pill : AppRadius.chip;
    final selected = pill ? AppColors.chipSelectedWarm : AppColors.chipSelected;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        constraints: BoxConstraints(minHeight: pill ? 38 : 34),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: pill ? 13 : 15),
        decoration: BoxDecoration(
          color: active ? selected : AppColors.card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: active ? selected : (pill ? const Color(0xFFE6E8E2) : AppColors.line)),
        ),
        child: Text(
          label,
          style: AppType.meta.copyWith(
            fontSize: pill ? 12 : 13,
            fontWeight: active ? AppType.w600 : AppType.w500,
            color: active ? Colors.white : (pill ? const Color(0xFF747A69) : const Color(0xFF72777E)),
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
