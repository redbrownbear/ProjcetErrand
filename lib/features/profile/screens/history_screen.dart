import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/kit.dart';
import '../../benefits/models/attendance.dart';
import '../../benefits/widgets/attendance_card.dart';
import '../../pay/models/pay_entry.dart';

/// 마이 › 내 지갑 › 내역·출석
///
/// 출석 달력(매일 1P · 응모권 +1)과 겸사페이 원장 내역을 한 화면에 둔다.
class HistoryScreen extends StatelessWidget {
  final Attendance attendance;
  final VoidCallback onCheckIn;
  final List<PayEntry> entries;
  final int points;
  const HistoryScreen({super.key, required this.attendance, required this.onCheckIn, required this.entries, required this.points});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: '내역·출석',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
            child: AttendanceCard(attendance: attendance, onCheckIn: onCheckIn),
          ),
          Sec(
            title: '포인트 · 겸사페이 내역',
            titleTrailing: Text('${nf(points)}P', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.yellowInk)),
            child: entries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Text('아직 정산된 내역이 없어요. 부탁을 완료하면 여기에 쌓여요.', style: TextStyle(fontSize: 13, color: AppColors.sub, height: 1.5)),
                  )
                : Column(children: [
                    for (final e in entries)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                              Text('${e.kind.label} · ${e.at.month}.${e.at.day}', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                            ]),
                          ),
                          Text(
                            '${e.amount > 0 ? '+' : ''}${won(e.amount)}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: e.amount > 0 ? AppColors.ink : AppColors.sub),
                          ),
                        ]),
                      ),
                  ]),
          ),
        ],
      ),
    );
  }
}
