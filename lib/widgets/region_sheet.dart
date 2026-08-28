import 'package:flutter/material.dart';

import '../data/items.dart';
import '../theme/colors.dart';

class RegionSheet extends StatelessWidget {
  final String scope;
  final void Function(String) onPick;
  final VoidCallback onClose;
  const RegionSheet({super.key, required this.scope, required this.onPick, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: const Color(0x73141420),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              decoration: const BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
                  const Text('어디를 볼까요?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  const Text('같은 동네가 아니어도 전국 어디든 볼 수 있어요', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
                  const SizedBox(height: 16),
                  for (final r in regions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => onPick(r),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                          decoration: BoxDecoration(
                            color: scope == r ? AppColors.ink : AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scope == r ? AppColors.ink : AppColors.line),
                          ),
                          child: Text(
                            r == '전국' ? '전국 전체 보기' : r,
                            style: TextStyle(fontSize: 14, color: scope == r ? Colors.white : AppColors.ink, fontWeight: scope == r ? FontWeight.w700 : FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
