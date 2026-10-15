import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/widgets/surface.dart';

/// 홈 바로가기 '전체' — 홈에 다 올리지 못한 진입점을 한 장에 모은다.
void showAllServicesSheet(BuildContext context, List<(String icon, String label, VoidCallback go)> entries) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.surface))),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.soft2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
              child: Text('전체 서비스', style: AppType.pageTitle),
            ),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [
                for (final (icon, label, go) in entries)
                  InkWell(
                    onTap: () {
                      Navigator.of(sheet).pop();
                      go();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconTile(icon: icon, bg: AppColors.page, fg: AppColors.ink2, size: 44, radius: 14),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(fontSize: 11.5, fontWeight: AppType.w600, color: AppColors.ink2),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
