import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/screen_frame.dart';
import '../models/attendance.dart';
import '../widgets/attendance_card.dart';

/// 마이 › 지갑 카드의 '내역·출석'. 출석 달력과 겸사페이 내역으로 가는 길을 둔다.
class AttendanceScreen extends StatelessWidget {
  final Attendance attendance;
  final VoidCallback onCheckIn;
  final VoidCallback onOpenPay;
  const AttendanceScreen({super.key, required this.attendance, required this.onCheckIn, required this.onOpenPay});

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: '내역 · 출석',
      onBack: () => Navigator.of(context).pop(),
      child: ColoredBox(
        color: AppColors.page,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            AttendanceCard(attendance: attendance, onCheckIn: onCheckIn),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: OutlinedButton(onPressed: onOpenPay, child: const Text('겸사페이 내역 보기')),
            ),
          ],
        ),
      ),
    );
  }
}
