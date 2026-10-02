import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// 누르면 바텀시트로 고르는 상자 (반경 · 정렬 · 종류)
class SelectBox<T> extends StatelessWidget {
  final String label;
  final IconData? icon;
  final T value;
  final String display;
  final List<(T, String)> items;
  final void Function(T) onChanged;
  const SelectBox({
    super.key,
    required this.label,
    this.icon,
    required this.value,
    required this.display,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.soft2),
      ),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: AppColors.sub), const SizedBox(width: 4)],
              Text(
                display,
                style: AppType.meta.copyWith(fontSize: 13, fontWeight: AppType.w600, color: AppColors.ink),
              ),
              const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.sub),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.surface))),
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.7),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
                  child: Text(label, style: AppType.pageTitle.copyWith(fontSize: 16)),
                ),
                for (final (v, text) in items)
                  ListTile(
                    title: Text(text, style: AppType.body.copyWith(fontWeight: v == value ? AppType.w700 : AppType.w400)),
                    trailing: v == value ? const Icon(Icons.check_rounded, size: 19, color: AppColors.ink) : null,
                    onTap: () {
                      Navigator.of(sheet).pop();
                      onChanged(v);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 켜고 끄는 작은 상자 (30분 이내 · 지도)
class ToggleBox extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;
  const ToggleBox({super.key, required this.label, this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.ink : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: active ? AppColors.ink : AppColors.soft2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: active ? Colors.white : AppColors.ink2),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppType.meta.copyWith(
                  fontSize: 13,
                  fontWeight: AppType.w600,
                  color: active ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
