import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// 두 칸 전환. 흰 알약이 선택된 칸으로 미끄러진다.
class SegToggle extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final EdgeInsets margin;
  const SegToggle({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.margin = const EdgeInsets.fromLTRB(10, 2, 10, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.soft2, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
                      BoxShadow(color: Color(0x1F000000), blurRadius: 12, spreadRadius: -6, offset: Offset(0, 4)),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < labels.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == index,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(i),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: AppType.button.copyWith(
                                fontSize: 15,
                                fontWeight: AppType.w700,
                                color: i == index ? AppColors.ink : AppColors.sub,
                              ),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 회색 바탕 안의 작은 세그먼트
class MiniTabs extends StatelessWidget {
  final List<(String, int?)> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  const MiniTabs({super.key, required this.tabs, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: i == index
                        ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          tabs[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.meta.copyWith(
                            fontSize: 13,
                            fontWeight: i == index ? AppType.w700 : AppType.w600,
                            color: i == index ? AppColors.ink : AppColors.sub,
                          ),
                        ),
                      ),
                      if (tabs[i].$2 != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            '${tabs[i].$2}',
                            style: AppType.caption.copyWith(fontWeight: AppType.w700, color: AppColors.ink),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 밑줄 탭
class UnderlineTabs extends StatelessWidget {
  final List<(String, String?)> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final EdgeInsets margin;
  final double fontSize;
  final double gap;
  const UnderlineTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    this.margin = const EdgeInsets.fromLTRB(20, 0, 20, 10),
    this.fontSize = 14,
    this.gap = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Padding(
              padding: EdgeInsets.only(right: gap),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: fontSize > 15 ? 12 : 8.5),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: i == index ? AppColors.ink : Colors.transparent, width: 2)),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: tabs[i].$1),
                        if (tabs[i].$2 != null)
                          TextSpan(
                            text: ' ${tabs[i].$2}',
                            style: TextStyle(fontSize: fontSize - 2, color: AppColors.faint, fontWeight: AppType.w600),
                          ),
                      ],
                    ),
                    style: AppType.body.copyWith(
                      fontSize: fontSize,
                      fontWeight: AppType.w700,
                      color: i == index ? AppColors.ink : AppColors.faint,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
