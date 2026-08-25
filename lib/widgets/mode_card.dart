import 'package:flutter/material.dart';

import '../theme/colors.dart';

class ModeCard extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final Color bg, tcol;
  final String title;
  const ModeCard({super.key, required this.active, required this.onTap, required this.bg, required this.title, required this.tcol});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: active ? AppColors.ink : Colors.transparent, width: 2.5),
          ),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: tcol)),
        ),
      ),
    );
  }
}
