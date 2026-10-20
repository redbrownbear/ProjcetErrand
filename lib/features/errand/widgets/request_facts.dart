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
    // 정확한 장소는 공개 글에 없다(보안 규칙 v2 — private/detail). 글쓴이와 수락된 사람만 본다.
    final hidden = it.ownerUid != null && !it.isMine;
    final rows = it.isGoing
        ? <List<String>>[
            ['가는 곳', it.cc != null ? [it.country ?? '해외', ?place].join(' · ') : (it.region ?? place ?? '글쓴이 확인 필요')],
            ['받는 기한', it.isExpired ? '${deadlineLabel(it)} · 마감됨' : deadlineLabel(it)],
            ['전달 장소', it.deliveryPlace ?? (hidden ? '수락되면 채팅으로 정해요' : '글쓴이와 협의')],
            ['물건값', '영수증을 보고 따로 주고받아요'],
            ['전달·완료', it.completion ?? '부탁 전에 글쓴이와 확인해 주세요'],
          ]
        : <List<String>>[
            ['마감', it.isExpired ? '${deadlineLabel(it)} · 마감됨' : deadlineLabel(it)],
            ['시작 장소', (place != null && place.isNotEmpty) ? place : (hidden ? '${it.region ?? '동네'} · 정확한 장소는 수락되면 보여요' : '요청자 확인 필요')],
            ['완료 장소', it.deliveryPlace ?? (hidden ? '수락되면 보여요' : '요청자와 협의 필요')],
            ['구매비', '${paymentLabels[it.payment] ?? '부담 방식 확인 필요'}${it.budget > 0 ? '\n물품 예산 ${won(it.budget)} · 사례비와 별도' : ''}'],
            ['완료 조건', it.completion ?? '지원 전 요청자와 확인해 주세요'],
          ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              it.isGoing ? '부탁 전에 확인하세요' : '지원 전에 확인하세요',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      r[0],
                      style: const TextStyle(fontSize: 13, color: AppColors.sub, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(r[1], style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.45)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
