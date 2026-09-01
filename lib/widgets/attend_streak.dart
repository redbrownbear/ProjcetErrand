import 'package:flutter/material.dart';

import '../data/attend_streak.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';

class AttendStreak extends StatefulWidget {
  final void Function(int amt, String label) earn;
  const AttendStreak({super.key, required this.earn});
  @override
  State<AttendStreak> createState() => _AttendStreakState();
}

class _AttendStreakState extends State<AttendStreak> {
  bool claimed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(children: [
          for (int i = 0; i < attendStreak.length; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == attendStreak.length - 1 ? 0 : 7),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: i == 0 ? AppColors.yellowSoft : AppColors.page,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: i == 0 ? AppColors.yellow : AppColors.line),
                ),
                child: Column(children: [
                  Text('${attendStreak[i].day}일', style: const TextStyle(fontSize: 11, color: AppColors.sub, fontWeight: FontWeight.w700)),
                  Padding(padding: const EdgeInsets.only(top: 3), child: Text('+${nf(attendStreak[i].won)}원', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: i == 0 ? AppColors.yellowDeep : AppColors.ink))),
                ]),
              ),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [
            Expanded(
              child: Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: AppColors.sub), children: [
                const TextSpan(text: '오래 이어질수록 커지는 '),
                TextSpan(text: '현금 적립', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                const TextSpan(text: ' · 정말 원으로 받아요'),
              ])),
            ),
            InkWell(
              onTap: () {
                if (!claimed) {
                  widget.earn(attendStreak[0].won, '출석 적립');
                  setState(() => claimed = true);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(color: claimed ? AppColors.page : AppColors.yellow, borderRadius: BorderRadius.circular(10)),
                child: Text(claimed ? '오늘 출석 완료' : '오늘 출석 +${nf(attendStreak[0].won)}원', style: TextStyle(color: claimed ? AppColors.sub : AppColors.ink, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
