import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_icon.dart';

/// 작은 상태 배지
class StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const StatusBadge(this.label, {super.key, required this.bg, required this.fg});

  const StatusBadge.green(this.label, {super.key}) : bg = AppColors.greenSoft, fg = AppColors.green;
  const StatusBadge.red(this.label, {super.key}) : bg = AppColors.redSoft, fg = AppColors.red;
  const StatusBadge.blue(this.label, {super.key}) : bg = AppColors.blueSoft, fg = AppColors.blue;
  const StatusBadge.yellow(this.label, {super.key}) : bg = AppColors.yellowSoft, fg = AppColors.yellowInk;
  const StatusBadge.gray(this.label, {super.key}) : bg = AppColors.page, fg = AppColors.sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: AppType.caption.copyWith(fontSize: 11, fontWeight: AppType.w600, color: fg, height: 1.3),
      ),
    );
  }
}

/// 둥근 사각 아이콘 타일
class IconTile extends StatelessWidget {
  final String icon;
  final Color bg;
  final Color fg;
  final double size;
  final double iconSize;
  final double radius;
  const IconTile({
    super.key,
    required this.icon,
    this.bg = AppColors.orangeSoft,
    this.fg = AppColors.orange,
    this.size = 40,
    this.iconSize = 22,
    this.radius = AppRadius.emblem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      child: Icon(AppIcon.data(icon), size: iconSize, color: fg),
    );
  }
}
