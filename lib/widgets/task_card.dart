import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/task_item.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';

class TaskCard extends StatelessWidget {
  final TaskItem it;
  final VoidCallback onOpen, onApply;
  final String? st;
  const TaskCard({super.key, required this.it, required this.onOpen, required this.onApply, this.st});
  @override
  Widget build(BuildContext context) {
    final paid = it.mode == 'ask';
    final free = it.mode == 'together';
    final share = it.mode == 'share';
    final c = catOf(it.cat);
    return InkWell(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 11),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: it.hot ? AppColors.hot : Colors.transparent, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 46, height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: free ? AppColors.gray : share ? AppColors.greenSoft : AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(c?.icon ?? '🙌', style: const TextStyle(fontSize: 23)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (it.hot)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.hot, borderRadius: BorderRadius.circular(6)),
                          child: const Text('🔥 HOT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      Expanded(child: Text(it.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                    ]),
                    const SizedBox(height: 4),
                    Text('${km(it.dist)}${paid ? ' · 약 ${it.mins}분' : ''} · ${it.place} · ${it.who}', style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
                    if ((free || share) && it.extra != null)
                      Padding(padding: const EdgeInsets.only(top: 3), child: Text(it.extra!, style: const TextStyle(fontSize: 11.5, color: AppColors.blue, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  share ? '무료 나눔' : paid ? won(it.price) : '사례 없음',
                  style: TextStyle(fontSize: paid ? 18 : 14, fontWeight: FontWeight.w900, color: share ? AppColors.green : AppColors.ink),
                ),
                StatusBtn(st: st, paid: paid, onApply: onApply),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBtn extends StatelessWidget {
  final String? st;
  final bool paid;
  final VoidCallback onApply;
  const StatusBtn({super.key, this.st, required this.paid, required this.onApply});
  @override
  Widget build(BuildContext context) {
    if (st == 'pending') {
      return _pill('매칭 중…', AppColors.yellowSoft, const Color(0xFFB8860B));
    }
    if (st == 'matched') {
      return _pill('매칭 완료 ✓', AppColors.greenSoft, const Color(0xFF1B8A5A));
    }
    return ElevatedButton(
      onPressed: onApply,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        elevation: 0,
      ),
      child: Text(paid ? '신청하기' : '같이 신청', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  Widget _pill(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
        child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12.5)),
      );
}
