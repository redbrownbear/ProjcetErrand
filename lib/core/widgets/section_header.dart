import 'package:flutter/material.dart';

import '../theme/colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.sub, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                if (sub != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(sub!, style: const TextStyle(fontSize: 12, color: AppColors.sub))),
              ],
            ),
          ),
          if (onAction != null)
            InkWell(onTap: onAction, child: const Text('전체보기 ›', style: TextStyle(color: AppColors.sub, fontSize: 12))),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String msg;
  const EmptyState({super.key, required this.msg});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.sub, fontSize: 13, height: 1.6)),
    );
  }
}

class HDivider extends StatelessWidget {
  final bool thick;
  const HDivider({super.key, this.thick = false});
  @override
  Widget build(BuildContext context) {
    if (!thick) return const Divider(height: 1, thickness: 1, color: AppColors.line);
    return Container(
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(top: BorderSide(color: AppColors.line), bottom: BorderSide(color: AppColors.line)),
      ),
    );
  }
}
