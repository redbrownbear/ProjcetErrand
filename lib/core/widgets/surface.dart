import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_icon.dart';

/// 시안 v33의 화면 뼈대 조각들.
///
/// v33은 옅은 회색 바탕(`--soft`) 위에 흰 카드(`.sec`)를 8px 간격으로 쌓는다.
/// 카드 안 제목은 `.sh`, 카드 밖 아래 주석은 `.foot`이다.

/// 흰 섹션 카드 (.sec — 좌우 10px 여백, 모서리 18, 위아래 16·10)
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

/// 카드 안 섹션 제목 (.sh). 오른쪽에 '전체보기 ›' 같은 글자 버튼을 둘 수 있다.
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: title),
                if (count != null) TextSpan(text: ' $count', style: const TextStyle(color: AppColors.sub)),
              ]),
              style: AppType.sectionSmall,
            ),
          ),
          ?trailing,
          if (action != null) TextLink(label: action!, onTap: onAction),
        ]),
        if (sub != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(sub!, style: AppType.meta.copyWith(fontSize: 12.5, color: AppColors.sub)),
          ),
      ]),
    );
  }
}

/// '전체보기 ›' 글자 버튼 (.sh .m)
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
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w500, color: color)),
          Icon(Icons.chevron_right_rounded, size: 16, color: color),
        ]),
      ),
    );
  }
}

/// 두 칸 전환 (.seg — 부탁하기 | 돈벌기). 흰 알약이 선택된 칸으로 미끄러진다.
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
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth / labels.length;
        return Stack(children: [
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
          Row(children: [
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
          ]),
        ]);
      }),
    );
  }
}

/// 회색 바탕 안의 작은 세그먼트 (.mtabs — 전체 6 | 참여 중 2 | 적립 완료 0)
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
      child: Row(children: [
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
                  boxShadow: i == index ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))] : null,
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                      child: Text('${tabs[i].$2}',
                          style: AppType.caption.copyWith(fontWeight: AppType.w700, color: AppColors.ink)),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

/// 밑줄 탭 (.nt · .stabs — 동네 부탁 | 단기알바 3)
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
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(children: [
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
                  TextSpan(children: [
                    TextSpan(text: tabs[i].$1),
                    if (tabs[i].$2 != null)
                      TextSpan(text: ' ${tabs[i].$2}', style: TextStyle(fontSize: fontSize - 2, color: AppColors.faint, fontWeight: AppType.w600)),
                  ]),
                  style: AppType.body.copyWith(
                    fontSize: fontSize,
                    fontWeight: AppType.w700,
                    color: i == index ? AppColors.ink : AppColors.faint,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// 작은 상태 배지 (.bd — 지금 가능 · 급해요 · 내가 올림)
class StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const StatusBadge(this.label, {super.key, required this.bg, required this.fg});

  const StatusBadge.green(this.label, {super.key})
      : bg = AppColors.greenSoft,
        fg = AppColors.green;
  const StatusBadge.red(this.label, {super.key})
      : bg = AppColors.redSoft,
        fg = AppColors.red;
  const StatusBadge.blue(this.label, {super.key})
      : bg = AppColors.blueSoft,
        fg = AppColors.blue;
  const StatusBadge.yellow(this.label, {super.key})
      : bg = AppColors.yellowSoft,
        fg = AppColors.yellowInk;
  const StatusBadge.gray(this.label, {super.key})
      : bg = AppColors.page,
        fg = AppColors.sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: AppType.caption.copyWith(fontSize: 11, fontWeight: AppType.w600, color: fg, height: 1.3)),
    );
  }
}

/// 둥근 사각 아이콘 타일 (.tile)
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

/// 회색 꽉 찬 버튼 (.morebtn — 부탁 전체 보기)
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
              child: Text(label, style: AppType.button.copyWith(fontWeight: AppType.w600, color: AppColors.ink2)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 카드 밖 맨 아래 주석 (.foot)
class FootNote extends StatelessWidget {
  final String text;
  const FootNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(text, textAlign: TextAlign.center, style: AppType.caption.copyWith(color: AppColors.faint, height: 1.5)),
    );
  }
}

/// 넘김 점 (.can-dots — 선택된 점만 길다)
class PageDots extends StatelessWidget {
  final int count;
  final int index;
  const PageDots({super.key, required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (int i = 0; i < count; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: i == index ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: i == index ? AppColors.ink : AppColors.soft2,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
    ]);
  }
}

/// '이런 것도 부탁해도 돼요' (.can) — 예시 한 줄이 몇 초마다 바뀐다.
///
/// 예시는 실제 부탁이 아니라 **이런 것도 올려도 된다는 안내**다. 누르면 부탁 쓰기로 간다.
class ExampleRotator extends StatefulWidget {
  final String question;
  final List<({String icon, String title, Color color})> items;
  final void Function(int index) onTap;
  final String footLabel;
  final VoidCallback onFoot;
  const ExampleRotator({
    super.key,
    required this.question,
    required this.items,
    required this.onTap,
    required this.footLabel,
    required this.onFoot,
  });

  @override
  State<ExampleRotator> createState() => _ExampleRotatorState();
}

class _ExampleRotatorState extends State<ExampleRotator> {
  int i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (mounted) setState(() => i = (i + 1) % widget.items.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.items[i];
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.question, style: AppType.sectionSmall.copyWith(fontSize: 15, letterSpacing: -0.6)),
        const SizedBox(height: 8),
        Material(
          color: AppColors.page,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          child: InkWell(
            onTap: () => widget.onTap(i),
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: SizedBox(
              height: 46,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(a),
                    child: child,
                  ),
                ),
                child: Padding(
                  key: ValueKey(i),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(11)),
                      child: Icon(AppIcon.data(it.icon), size: 20, color: it.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(it.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.body.copyWith(fontSize: 13.5, fontWeight: AppType.w700, letterSpacing: -0.4)),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        PageDots(count: widget.items.length, index: i),
        InkWell(
          onTap: widget.onFoot,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(widget.footLabel,
                    textAlign: TextAlign.center,
                    style: AppType.meta.copyWith(fontWeight: AppType.w500, color: AppColors.sub)),
              ),
              const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.sub),
            ]),
          ),
        ),
      ]),
    );
  }
}
