import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// 흰 섹션 카드
class SecCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  const SecCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(10, 8, 10, 0),
    this.padding = const EdgeInsets.fromLTRB(0, 16, 0, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: child,
    );
  }
}

/// 카드 안 섹션 제목. 오른쪽에 '전체보기 ›' 같은 글자 버튼을 둘 수 있다.
class SecHead extends StatelessWidget {
  final String title;
  final String? count;
  final String? sub;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsets padding;
  const SecHead({
    super.key,
    required this.title,
    this.count,
    this.sub,
    this.action,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: title),
                      if (count != null)
                        TextSpan(
                          text: ' $count',
                          style: const TextStyle(color: AppColors.sub),
                        ),
                    ],
                  ),
                  style: AppType.sectionSmall,
                ),
              ),
              ?trailing,
              if (action != null) TextLink(label: action!, onTap: onAction),
            ],
          ),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(sub!, style: AppType.meta.copyWith(fontSize: 12.5, color: AppColors.sub)),
            ),
        ],
      ),
    );
  }
}

/// '전체보기 ›' 글자 버튼
class TextLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  const TextLink({super.key, required this.label, this.onTap, this.color = AppColors.sub});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w500, color: color),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

/// 회색 꽉 찬 버튼
class SoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final EdgeInsets margin;
  const SoftButton({super.key, required this.label, required this.onTap, this.margin = const EdgeInsets.fromLTRB(20, 6, 20, 0)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            height: 46,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: AppType.button.copyWith(fontWeight: AppType.w600, color: AppColors.ink2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 카드 밖 맨 아래 주석
class FootNote extends StatelessWidget {
  final String text;
  const FootNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppType.caption.copyWith(color: AppColors.faint, height: 1.5),
      ),
    );
  }
}
