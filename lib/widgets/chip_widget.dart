import 'package:flutter/material.dart';

import '../theme/colors.dart';

class ChipWidget extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const ChipWidget({super.key, required this.label, this.active = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? AppColors.ink : AppColors.line),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
