import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/widgets/app_icon.dart';

/// 흰 바탕에 옅은 테두리를 두른 작은 버튼 (글쓰기 · 같이하기)
class OutlineSmallButton extends StatelessWidget {
  final String? icon;
  final String label;
  final VoidCallback onTap;
  const OutlineSmallButton({super.key, this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: const BorderSide(color: AppColors.soft2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(AppIcon.data(icon!), size: 13, color: AppColors.ink), const SizedBox(width: 4)],
              Text(
                label,
                style: AppType.meta.copyWith(fontSize: 12.5, fontWeight: AppType.w600, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 회색 작은 버튼 (지갑 ›)
class SoftPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SoftPillButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.page,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 34,
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: AppColors.ink2),
              ),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.ink2),
            ],
          ),
        ),
      ),
    );
  }
}

/// 동그란 화살표 버튼 (이전 · 다음)
class RoundArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const RoundArrowButton({super.key, required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.soft2)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 30, height: 30, child: Icon(icon, size: 18, color: enabled ? AppColors.ink2 : AppColors.soft2)),
      ),
    );
  }
}

/// 회색 작은 정보 칩 (약 10분 · 180m)
class MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const MetaChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.ink2),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppType.caption.copyWith(fontSize: 11.5, fontWeight: AppType.w600, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}
