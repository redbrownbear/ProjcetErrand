import 'package:flutter/material.dart';

import '../data/items.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import 'task_card.dart';

class EarnView extends StatelessWidget {
  final void Function(TaskItem) onOpenDetail;
  final void Function(TaskItem) onApply;
  final Map<int, String> status;
  const EarnView({super.key, required this.onOpenDetail, required this.onApply, required this.status});
  @override
  Widget build(BuildContext context) {
    final bundle = [items[1], items[3], items[2]];
    final total = bundle.fold<int>(0, (s, i) => s + i.price);
    final mins = bundle.fold<int>(0, (s, i) => s + i.mins);
    final asks = items.where((i) => i.mode == 'ask').toList()..sort((a, b) => (b.hot ? 1 : 0) - (a.hot ? 1 : 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('오늘 내 주변 예상 수익', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              const SizedBox(height: 4),
              const Text('68,000원', style: TextStyle(color: AppColors.yellow, fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('🔥 HOT 1건 포함 · 지금 잡을 수 있는 일 기준', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('🔗 이 동선으로 묶어봤어요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink))),
        const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 10), child: Text('가까운 일을 한 번에 돌면 이동시간이 줄어요', style: TextStyle(fontSize: 12, color: AppColors.sub))),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.blueSoft, width: 1.5)),
          child: Column(
            children: [
              for (int i = 0; i < bundle.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i < bundle.length - 1 ? 12 : 0),
                  child: Row(children: [
                    Column(children: [
                      Container(
                        width: 26, height: 26, alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                        child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                      if (i < bundle.length - 1) Container(width: 2, height: 22, color: AppColors.blueSoft, margin: const EdgeInsets.only(top: 2)),
                    ]),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bundle[i].title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text('${bundle[i].place} · ${km(bundle[i].dist)} · ${bundle[i].mins}분', style: const TextStyle(fontSize: 11, color: AppColors.sub)),
                        ],
                      ),
                    ),
                    Text(won(bundle[i].price), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ]),
                ),
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line, width: 1))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('총 ${mins ~/ 60}시간 ${mins % 60}분 예상', style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                    Text(won(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => bundle.forEach(onApply),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    elevation: 0,
                  ),
                  child: const Text('이 동선 한 번에 신청', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                ),
              ),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 8), child: Text('낱개로 잡기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink))),
        ...asks.map((it) => TaskCard(it: it, onOpen: () => onOpenDetail(it), onApply: () => onApply(it), st: status[it.id])),
      ],
    );
  }
}
