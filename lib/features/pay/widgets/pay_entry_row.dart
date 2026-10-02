import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_icon.dart';
import '../models/pay_entry.dart';

class PayEntryRow extends StatelessWidget {
  final PayEntry entry;
  const PayEntryRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final income = entry.isIncome;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F1F3))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: income ? AppColors.greenSoft : AppColors.page,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(AppIcon.data(entry.kind.icon), size: 18, color: income ? AppColors.green : AppColors.sub),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label.isEmpty ? entry.kind.label : entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(fontWeight: AppType.w500),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('${entry.kind.label} · ${dateTimeLabel(entry.at)}', style: AppType.caption),
                ),
              ],
            ),
          ),
          Text(
            '${income ? '+' : '−'}${nf(entry.amount.abs())}원',
            style: AppType.price.copyWith(fontSize: 15, color: income ? AppColors.green : AppColors.ink),
          ),
        ],
      ),
    );
  }
}
