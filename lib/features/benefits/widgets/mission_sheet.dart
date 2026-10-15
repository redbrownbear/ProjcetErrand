import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';

/// 미션 결과를 보여 주는 바텀시트. 미션마다 내용만 갈아 끼운다.
class MissionSheet extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  const MissionSheet({super.key, required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.surface)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppType.section),
              Padding(
                padding: const EdgeInsets.only(top: 3, bottom: 14),
                child: Text(subtitle, style: AppType.caption),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// 미션 시트 안의 선택지 한 줄
class MissionChoiceButton extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;
  const MissionChoiceButton({super.key, required this.label, this.hint = '', required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.page,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.meta.copyWith(fontSize: 14, fontWeight: AppType.w600, color: AppColors.ink, height: 1.4),
            ),
            if (hint.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption),
              ),
          ],
        ),
      ),
    );
  }
}
