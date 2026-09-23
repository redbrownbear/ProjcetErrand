import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// 입력 한 칸. 시안(`gyumsa-refined`)의 `.g2-field` — 라벨 · 입력 · 도움말이 한 묶음이다.
///
/// 새로 붙는 등록 화면(브랜드 협업 제안 · 단기알바 모집 · 해외 사다주기)이 모두
/// 같은 규격을 쓰므로 한 곳에 뒀다.
class AppField extends StatelessWidget {
  final String label;
  final bool required;
  final String? hint;
  final String? placeholder;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.placeholder,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label(label: label, required: required),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: AppType.body.copyWith(fontSize: 14, height: 1.5),
          decoration: fieldDecoration(placeholder),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(hint!, style: AppType.caption.copyWith(fontSize: 11, height: 1.6)),
          ),
      ]),
    );
  }

  static InputDecoration fieldDecoration(String? placeholder) => InputDecoration(
        hintText: placeholder,
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: _border(AppColors.line),
        enabledBorder: _border(AppColors.line),
        focusedBorder: _border(AppColors.green),
      );

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: color),
      );
}

/// 고르는 칸. `.g2-field`의 `<select>` 자리다.
class AppSelectField extends StatelessWidget {
  final String label;
  final bool required;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label(label: label, required: required),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : options.first,
          isExpanded: true,
          style: AppType.body.copyWith(fontSize: 14),
          decoration: AppField.fieldDecoration(null),
          items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o))],
          onChanged: (v) => onChanged(v ?? options.first),
        ),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String label;
  final bool required;
  const _Label({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(
      style: AppType.body.copyWith(fontSize: 13, fontWeight: AppType.w600, color: AppColors.inkSoft),
      children: [
        TextSpan(text: label),
        if (required) TextSpan(text: ' *', style: TextStyle(color: AppColors.green)),
      ],
    ));
  }
}

/// 날짜(·시각)를 고르는 칸. `<input type="datetime-local">` 자리다.
class AppDateField extends StatelessWidget {
  final String label;
  final bool required;
  final String? hint;
  final DateTime? value;
  final bool withTime;
  final DateTime? first;
  final DateTime? last;
  final ValueChanged<DateTime> onChanged;

  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.hint,
    this.withTime = true,
    this.first,
    this.last,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final start = first ?? now.subtract(const Duration(days: 1));
    final init = (value != null && !value!.isBefore(start)) ? value! : now.add(const Duration(hours: 2));
    final date = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(start.year, start.month, start.day),
      lastDate: last ?? now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    if (!withTime) {
      onChanged(DateTime(date.year, date.month, date.day));
      return;
    }
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(init));
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String get _text {
    final v = value;
    if (v == null) return withTime ? '날짜와 시각 선택' : '날짜 선택';
    String two(int n) => n.toString().padLeft(2, '0');
    final day = '${v.year}.${two(v.month)}.${two(v.day)}';
    return withTime ? '$day ${two(v.hour)}:${two(v.minute)}' : day;
  }

  @override
  Widget build(BuildContext context) {
    final empty = value == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label(label: label, required: required),
        const SizedBox(height: 9),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.faint),
              const SizedBox(width: 9),
              Expanded(
                child: Text(_text,
                    style: AppType.body.copyWith(fontSize: 14, color: empty ? AppColors.faint : AppColors.ink)),
              ),
            ]),
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(hint!, style: AppType.caption.copyWith(fontSize: 11, height: 1.6)),
          ),
      ]),
    );
  }
}

/// 확인 체크 한 줄 (.g2-check)
class AppCheckRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  const AppCheckRow({super.key, required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.green,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(label, style: AppType.meta.copyWith(fontSize: 12, height: 1.7, color: AppColors.inkSoft)),
          ),
        ]),
      ),
    );
  }
}
