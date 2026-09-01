import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 전체화면 하위 화면 공통 프레임 (뒤로가기 헤더 + 스크롤 바디)
class ScreenFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Color? accent;
  final Widget? right;
  final Widget child;
  const ScreenFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    this.accent,
    this.right,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: AppColors.page,
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            decoration: const BoxDecoration(color: AppColors.card, border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(99),
                    child: const Padding(padding: EdgeInsets.only(right: 2), child: Text('‹', style: TextStyle(fontSize: 24, color: AppColors.ink))),
                  ),
                  Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent ?? AppColors.ink))),
                  ?right,
                ]),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 22, top: 4),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ]),
      ),
    );
  }
}
