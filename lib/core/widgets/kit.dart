import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_icon.dart';

/// v77 시안이 화면마다 되풀이하는 작은 부품들.
///
/// 시안은 회색 바탕(#F2F4F6) 위에 좌우 10px 여백을 둔 흰 카드를 8px 간격으로 쌓는다.
/// 카드 안 글자는 좌우 20px 들여 쓴다. 이 값들을 여기 한 곳에 모았다.

/// 눌리는 영역. 물결 대신 살짝 어두워지는 시안의 `:active` 느낌을 낸다.
class Tap extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double radius;
  const Tap({super.key, required this.onTap, required this.child, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashFactory: NoSplash.splashFactory,
        highlightColor: const Color(0x0A191F28),
        child: child,
      ),
    );
  }
}

/// 흰 카드 (.sec). [title]을 주면 카드 머리(.sh)가 생긴다.
class Sec extends StatelessWidget {
  final String? title;
  final Widget? titleTrailing;
  final String? more;
  final VoidCallback? onMore;
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Color color;
  const Sec({
    super.key,
    this.title,
    this.titleTrailing,
    this.more,
    this.onMore,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(10, 8, 10, 0),
    this.padding = const EdgeInsets.fromLTRB(0, 16, 0, 10),
    this.color = AppColors.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
            child: Row(children: [
              Expanded(child: Text(title!, style: AppType.section)),
              ?titleTrailing,
              if (more != null && onMore != null) MoreLink(label: more!, onTap: onMore!),
            ]),
          ),
        child,
      ]),
    );
  }
}

/// '전체 ›' 같은 옅은 글자 링크
class MoreLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const MoreLink({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: AppType.meta.copyWith(fontSize: 13)),
          const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.sub),
        ]),
      ),
    );
  }
}

/// 국내 / 해외 큰 글자 탭 (.scp3). 켜진 쪽 아래에 짧은 막대가 붙는다.
class BigTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final Color accent;
  const BigTabs({super.key, required this.labels, required this.index, required this.onChanged, this.accent = AppColors.yellow});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 22),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(labels[i], style: AppType.bigTab.copyWith(color: i == index ? AppColors.ink : AppColors.tabIdle)),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: i == index ? 34 : 0,
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

/// 회색 바탕 안에 흰 알약이 움직이는 세그먼트 (.seg · .os-seg)
class Seg extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final EdgeInsets margin;
  final Widget Function(int i, bool on)? iconOf;
  const Seg({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.margin = const EdgeInsets.fromLTRB(10, 10, 10, 0),
    this.iconOf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.segBg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                alignment: Alignment.center,
                decoration: i == index
                    ? BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
                          BoxShadow(color: Color(0x1F000000), blurRadius: 12, spreadRadius: -6, offset: Offset(0, 4)),
                        ],
                      )
                    : null,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (iconOf != null) ...[iconOf!(i, i == index), const SizedBox(width: 5)],
                  Flexible(
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: labels.length >= 3 ? 14 : 15,
                        fontWeight: i == index ? FontWeight.w700 : FontWeight.w600,
                        color: i == index ? AppColors.ink : AppColors.sub,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

/// 글자 아래 밑줄로 켜지는 탭 (마켓 4칸 · 동네 부탁/단기알바 · 우리 동네/여행)
class UnderTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double fontSize;
  final EdgeInsets padding;
  final bool divider;
  final Map<int, String> counts;
  const UnderTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.fontSize = 17,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 0),
    this.divider = true,
    this.counts = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: divider ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))) : null,
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 18),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 9, 0, 9),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: i == index ? AppColors.ink : Colors.transparent, width: 2)),
                ),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: labels[i]),
                    if (counts[i] != null)
                      TextSpan(text: ' ${counts[i]}', style: const TextStyle(color: AppColors.yellowInk)),
                  ]),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
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

/// 둥근 필터 칩 줄. 켜진 칩은 먹색 바탕.
class ChipRow extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final EdgeInsets padding;
  const ChipRow({super.key, required this.labels, required this.index, required this.onChanged, this.padding = const EdgeInsets.symmetric(horizontal: 20)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final on = i == index;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppColors.ink : AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: on ? AppColors.ink : AppColors.outline),
              ),
              child: Text(
                labels[i],
                style: TextStyle(fontSize: 13.5, fontWeight: on ? FontWeight.w700 : FontWeight.w600, color: on ? Colors.white : AppColors.inkSoft),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 응모권 표시 (.tkchip · .tkb)
class TicketChip extends StatelessWidget {
  final int n;
  final bool boxed;
  const TicketChip(this.n, {super.key, this.boxed = true});

  @override
  Widget build(BuildContext context) {
    final row = Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.confirmation_number_outlined, size: 13, color: AppColors.yellowInk),
      const SizedBox(width: 3),
      Text('+$n', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.yellowInk)),
    ]);
    if (!boxed) return row;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(7)),
      child: row,
    );
  }
}

/// 작은 상태 배지 (.bd) — '지금 가능' · '중고' · '참여 중'
class Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final double fontSize;
  const Pill(this.label, {super.key, this.bg = AppColors.greenSoft, this.fg = AppColors.green, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: fg, height: 1.3)),
    );
  }
}

/// 나라 코드 상자 (JP · US …)
class CodeBox extends StatelessWidget {
  final String code;
  final Color bg;
  final Color fg;
  final double size;
  const CodeBox(this.code, {super.key, this.bg = AppColors.page, this.fg = AppColors.inkSoft, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Text(code, style: TextStyle(fontSize: size * 0.37, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.2)),
    );
  }
}

/// 꽉 찬 큰 버튼. 노랑(기본) · 파랑(해외) · 먹색(제안)
class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? icon;
  final Color bg;
  final Color fg;
  final double height;
  final bool glow;
  final double? fontSize;
  const BigButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.bg = AppColors.yellow,
    this.fg = AppColors.ink,
    this.height = 50,
    this.glow = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: glow ? [BoxShadow(color: bg.withValues(alpha: 0.6), blurRadius: 18, spreadRadius: -8, offset: const Offset(0, 8))] : null,
        ),
        child: Tap(
          onTap: onTap,
          radius: 15,
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[AppIcon(icon!, size: 19, color: fg), const SizedBox(width: 6)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize ?? (height < 44 ? 13.5 : 16), fontWeight: FontWeight.w800, color: fg),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 테두리만 있는 작은 흰 버튼 (.gk-cta · .gkm-write)
class LineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? icon;
  final double height;
  const LineButton({super.key, required this.label, required this.onTap, this.icon, this.height = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.outline),
      ),
      child: Tap(
        onTap: onTap,
        radius: 9,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[AppIcon(icon!, size: 14), const SizedBox(width: 4)],
            Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ]),
        ),
      ),
    );
  }
}

/// 회색 꽉 찬 버튼 (.morebtn)
class GrayButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final EdgeInsets margin;
  const GrayButton({super.key, required this.label, required this.onTap, this.margin = const EdgeInsets.fromLTRB(20, 6, 20, 4)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: 46,
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(13)),
      child: Tap(
        onTap: onTap,
        radius: 13,
        child: Center(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkSoft))),
      ),
    );
  }
}

/// 아이콘 타일 + 제목 + 설명 + › 로 된 회색 도구 칸 (.pp-tool)
class ToolTile extends StatelessWidget {
  final Widget lead;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final bool compact;
  const ToolTile({super.key, required this.lead, required this.title, required this.sub, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(18)),
      child: Tap(
        onTap: onTap,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            lead,
            SizedBox(width: compact ? 8 : 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(sub, maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.sub)),
              ]),
            ),
            if (!compact) const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faint),
          ]),
        ),
      ),
    );
  }
}

/// 아래에서 올라오는 시트의 뼈대 (#sheet). 손잡이 + 제목 + 부제.
class SheetFrame extends StatelessWidget {
  final String? title;
  final String? sub;
  final Widget child;
  final Widget? bottom;
  const SheetFrame({super.key, this.title, this.sub, required this.child, this.bottom});

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.9;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 6, 20, bottom == null ? 20 : 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (title != null) Text(title!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.6)),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(sub!, style: const TextStyle(fontSize: 13.5, color: AppColors.sub, height: 1.5)),
                  ),
                if (title != null || sub != null) const SizedBox(height: 16),
                child,
              ]),
            ),
          ),
          if (bottom != null) Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 12), child: bottom),
        ]),
      ),
    );
  }
}

Future<T?> showSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: builder(ctx),
      ),
    );

/// 회색 바탕 + 뒤로가기 헤더로 된 전체화면 (.page)
class PageFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? bottom;
  final List<Widget> actions;
  final Color background;
  const PageFrame({super.key, required this.title, required this.child, this.bottom, this.actions = const [], this.background = AppColors.page});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: SafeArea(
        child: Column(children: [
          SizedBox(
            height: 52,
            child: Row(children: [
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
                tooltip: '뒤로 가기',
              ),
              Expanded(
                child: Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              SizedBox(width: 54, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions)),
            ]),
          ),
          Expanded(child: child),
          if (bottom != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              color: background,
              child: bottom,
            ),
        ]),
      ),
    );
  }
}

/// 폼 안의 라벨 (.lab)
class FieldLabel extends StatelessWidget {
  final String text;
  final String? hint;
  const FieldLabel(this.text, {super.key, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(children: [
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
        if (hint != null) ...[const SizedBox(width: 6), Text(hint!, style: const TextStyle(fontSize: 12, color: AppColors.faint))],
      ]),
    );
  }
}

/// 이름 첫 글자 동그라미 (.gk-av)
class Avatar extends StatelessWidget {
  final String name;
  final double size;
  const Avatar(this.name, {super.key, this.size = 24});

  static const _tones = [
    (Color(0xFFE3ECFD), Color(0xFF3A7BF5)),
    (Color(0xFFE2F5EC), Color(0xFF18A874)),
    (Color(0xFFFFF1DC), Color(0xFFE08A00)),
    (Color(0xFFF1EEFF), Color(0xFF5B4BE0)),
    (Color(0xFFFDEDEE), Color(0xFFF04452)),
  ];

  @override
  Widget build(BuildContext context) {
    final t = _tones[name.hashCode.abs() % _tones.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.$1, shape: BoxShape.circle),
      child: Text(name.isEmpty ? '?' : name.characters.first, style: TextStyle(fontSize: size * 0.46, fontWeight: FontWeight.w700, color: t.$2)),
    );
  }
}
