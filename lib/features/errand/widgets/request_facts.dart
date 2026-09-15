import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/task_item.dart';

/// 상세 화면의 "지원 전에 확인하세요" 거래 조건.
/// 샘플 데이터에 없는 항목은 지어내지 않고 확인 필요로 표시한다.
class RequestFacts extends StatelessWidget {
  final TaskItem it;
  const RequestFacts({super.key, required this.it});

  @override
  Widget build(BuildContext context) {
    final place = it.place;
    final rows = <List<String>>[
      ['마감', it.isExpired ? '${deadlineLabel(it)} · 마감됨' : deadlineLabel(it)],
      ['시작 장소', (place != null && place.isNotEmpty) ? place : '요청자 확인 필요'],
      ['완료 장소', it.deliveryPlace ?? '요청자와 협의 필요'],
      ['구매비', '${paymentLabels[it.payment] ?? '부담 방식 확인 필요'}${it.budget > 0 ? '\n물품 예산 ${won(it.budget)} · 사례비와 별도' : ''}'],
      ['완료 조건', it.completion ?? '지원 전 요청자와 확인해 주세요'],
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('지원 전에 확인하세요', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink))),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 72, child: Text(r[0], style: const TextStyle(fontSize: 13, color: AppColors.sub, fontWeight: FontWeight.w600))),
                Expanded(child: Text(r[1], style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.45))),
              ]),
            ),
        ],
      ),
    );
  }
}
