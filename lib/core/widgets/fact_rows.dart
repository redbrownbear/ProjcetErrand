import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// 이름-값을 한 줄씩 쌓은 표. 시안(`gyumsa-refined`)의 `.facts-v9` / `.g3-rows`.
///
/// 미션 상세의 '참여 전에 확인하세요', 단기알바 상세의 근무 조건처럼
/// **지원 전에 확인해야 하는 조건**을 빠짐없이 나열할 때 쓴다.
class FactRows extends StatelessWidget {
  final List<(String, String)> rows;
  const FactRows(this.rows, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final (k, v) in rows)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 10, child: Text(k, style: AppType.meta.copyWith(fontSize: 12, height: 1.6))),
            const SizedBox(width: 16),
            Expanded(
              flex: 11,
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: AppType.meta.copyWith(
                      fontSize: 12, height: 1.6, fontWeight: AppType.w600, color: AppColors.inkSoft)),
            ),
          ]),
        ),
    ]);
  }
}
