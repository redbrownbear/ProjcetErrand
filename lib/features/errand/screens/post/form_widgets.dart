import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';

/// 부탁 쓰기 폼에서 되풀이되는 조각들.

/// 단계 맨 위의 큰 제목
class StepTitle extends StatelessWidget {
  final String text;
  const StepTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        text,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3),
      ),
    );
  }
}

/// 입력 칸 위의 이름
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
      ),
    );
  }
}

/// 입력 칸 아래의 도움말
class FieldHint extends StatelessWidget {
  final String text;
  const FieldHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
    );
  }
}

/// 옅은 바탕의 안내 상자
class NoteBox extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const NoteBox(this.text, {super.key, this.bg = AppColors.yellowSoft, this.fg = AppColors.yellowDeep});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, height: 1.55, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 흰 바탕에 옅은 테두리를 두른 입력 칸 모양
InputDecoration formFieldDecoration(String hint) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.line),
  );
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    border: border,
    enabledBorder: border,
  );
}

/// 여러 개 중 하나를 고르는 상자. 고르면 [accent] 테두리와 [tint] 바탕이 된다.
class ChoiceBox extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final Color accent;
  final Color tint;
  final EdgeInsets padding;
  final Alignment? alignment;
  final double radius;

  const ChoiceBox({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.accent = AppColors.yellow,
    this.tint = AppColors.yellowSoft,
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    this.alignment,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: padding,
        alignment: alignment,
        decoration: BoxDecoration(
          color: selected ? tint : AppColors.card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: selected ? accent : AppColors.line, width: 1.5),
        ),
        child: child,
      ),
    );
  }
}

/// 자주 쓰는 값을 한 번에 고르는 버튼 줄 (10분 · 20분 …, 5천 · 1만 …)
class QuickPicks<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onPick;
  const QuickPicks({super.key, required this.values, required this.selected, required this.label, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final v in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onPick(v),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == selected ? AppColors.ink : AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: v == selected ? AppColors.ink : AppColors.line),
                  ),
                  child: Text(
                    label(v),
                    style: TextStyle(
                      color: v == selected ? Colors.white : AppColors.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// − 값 ＋ 로 올리고 내리는 줄
class ValueStepper extends StatelessWidget {
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool big;
  const ValueStepper({super.key, required this.value, required this.onMinus, required this.onPlus, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _button(Icons.remove_rounded, onMinus),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: big ? 26 : 18, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ),
        _button(Icons.add_rounded, onPlus),
      ],
    );
  }

  Widget _button(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line, width: 1.5),
          color: AppColors.card,
        ),
        child: Icon(icon, size: 22, color: AppColors.ink),
      ),
    );
  }
}
