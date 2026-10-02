import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_icon.dart';

/// 섹션 제목 (기획 시안 v9 `SectionHeading` / `.section-heading`).
///
/// 제목 옆의 [count]는 시안의 `.count`와 같이 옅은 색 숫자로 붙고,
/// [onAction]을 주면 오른쪽에 '전체 보기 ›'가 생긴다.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final int? count;
  final VoidCallback? onAction;
  final String actionLabel;
  const SectionHeader({super.key, required this.title, this.sub, this.count, this.onAction, this.actionLabel = '전체 보기'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: title),
                      if (count != null)
                        TextSpan(
                          text: '  $count',
                          style: AppType.section.copyWith(fontWeight: AppType.w500, color: AppColors.sub),
                        ),
                    ],
                  ),
                  style: AppType.section,
                ),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(sub!, style: AppType.meta.copyWith(fontSize: 13, height: 1.5)),
                  ),
              ],
            ),
          ),
          if (onAction != null) TextAction(label: actionLabel, onTap: onAction!),
        ],
      ),
    );
  }
}

/// '전체 보기 ›' 같은 작은 글자 버튼
class TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const TextAction({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w500)),
            const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

/// 빈 상태. [compact]는 목록 안에 들어갈 때의 작은 형태.
class EmptyState extends StatelessWidget {
  final String msg;
  final String? title;
  final String icon;
  final String? action;
  final VoidCallback? onAction;
  final bool compact;
  const EmptyState({
    super.key,
    required this.msg,
    this.title,
    this.icon = 'search',
    this.action,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // v33 `.empty` — 72px 아이콘 상자, 굵은 제목, 먹색 꽉 찬 버튼.
    // 목록 안(compact)에서는 흰 카드 위라 상자를 회색으로, 탭 전체(회색 바탕)에서는 흰색으로 둔다.
    final box = compact ? 50.0 : 72.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 26 : 40, vertical: compact ? 28 : 72),
      child: Column(
        children: [
          Container(
            width: box,
            height: box,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: compact ? AppColors.page : AppColors.card,
              borderRadius: BorderRadius.circular(compact ? 17 : 24),
            ),
            child: Icon(AppIcon.data(icon), size: compact ? 22 : 30, color: AppColors.ink2),
          ),
          SizedBox(height: compact ? 15 : 18),
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: AppType.section.copyWith(fontSize: compact ? 16 : 19),
            ),
          Padding(
            padding: EdgeInsets.only(top: title == null ? 0 : 6),
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(
                fontSize: compact ? 13 : 14,
                fontWeight: AppType.w500,
                height: 1.55,
                color: AppColors.sub,
              ),
            ),
          ),
          if (action != null && onAction != null)
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: compact
                  ? OutlinedButton(
                      onPressed: onAction,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 43),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Text(action!, style: AppType.button.copyWith(fontSize: 13, color: AppColors.btnSecondaryInk)),
                    )
                  : FilledButton(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
                      ),
                      child: Text(
                        action!,
                        style: AppType.button.copyWith(fontSize: 15, fontWeight: AppType.w700, color: Colors.white),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// 얇은 구분선과, 섹션 사이를 끊는 두꺼운 띠.
class HDivider extends StatelessWidget {
  final bool thick;
  const HDivider({super.key, this.thick = false});
  @override
  Widget build(BuildContext context) {
    if (!thick) return const Divider(height: 1, thickness: 1, color: AppColors.line);
    return Container(height: 8, color: AppColors.band);
  }
}
