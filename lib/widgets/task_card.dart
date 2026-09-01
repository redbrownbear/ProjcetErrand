import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/countries.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import 'tag.dart';

/// 세로 리스트용 컴팩트 카드. rich=true면 신뢰지표 행을 추가로 보여준다.
class TaskCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen;
  final bool done;
  final bool rich;
  final int? rank;
  const TaskCard({super.key, required this.it, required this.onOpen, this.done = false, this.rich = false, this.rank});

  @override
  Widget build(BuildContext context) {
    final sea = it.mode == 'sea';
    final paid = it.mode != 'together';
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: it.hot ? AppColors.redSoft : AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              if (rank != null)
                SizedBox(
                  width: 22,
                  child: Text('$rank', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: rank! <= 3 ? AppColors.ink : AppColors.faint)),
                ),
              if (rank != null) const SizedBox(width: 4),
              Container(
                width: 42, height: 42, alignment: Alignment.center,
                decoration: BoxDecoration(color: sea ? AppColors.purpleSoft : AppColors.page, borderRadius: BorderRadius.circular(12)),
                child: Text(sea ? countryOf(it.cc).flag : catOf(it.cat).icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (it.hot) ...[const Tag(label: '🔥', c: AppColors.red, bg: AppColors.redSoft), const SizedBox(width: 5)],
                      if (sea) ...[const Tag(label: '해외', c: AppColors.purple, bg: AppColors.purpleSoft), const SizedBox(width: 5)],
                      Expanded(child: Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink))),
                    ]),
                    const SizedBox(height: 2),
                    Text(sea ? (it.country ?? '') : '${distLabel(it)} · 약 ${it.mins}분', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(paid ? won(it.price) : '무료', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  if (done) const Padding(padding: EdgeInsets.only(top: 2), child: Text('지원함', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green))),
                ],
              ),
            ]),
            if (rich)
              Container(
                margin: const EdgeInsets.only(top: 11),
                padding: const EdgeInsets.only(top: 9),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 11.5, color: AppColors.sub),
                          children: [
                            TextSpan(text: '★ ${it.rating.toStringAsFixed(1)}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                            TextSpan(text: ' · 거래 ${it.deals}회'),
                            if (it.verified) const TextSpan(text: ' · ✓ 본인인증', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('🤝 ${it.helpCnt} · 🙋 ${it.reqCnt}', style: const TextStyle(fontSize: 11, color: AppColors.faint)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
