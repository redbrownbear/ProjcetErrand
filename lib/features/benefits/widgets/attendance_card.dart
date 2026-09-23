import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/attendance.dart';

/// 출석 달력 카드. 시안 `gyumsa-refined`의 `.g3-attendance`를 옮겼다.
///
/// 개편 전 홈의 출석은 "오늘 받기" 한 줄이라 지난 출석이 보이지 않았다.
/// 시안은 이번 달 달력을 항상 펼쳐 두고, 그 아래에 월 누적·연속 두 게이지를
/// 나란히 둔다. 보상 규칙은 [AttendRules]에 있다.
class AttendanceCard extends StatelessWidget {
  final Attendance attendance;

  /// 출석 도장을 찍는다. 받을 포인트는 [Attendance.todayReward]가 계산한다.
  final VoidCallback onCheckIn;

  const AttendanceCard({super.key, required this.attendance, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    final done = attendance.attendedToday;
    // 시안은 달력 칸을 고정폭으로 두고 왼쪽 글을 줄인다. (≤359px에서 한 단계 더 좁게)
    final calWidth = MediaQuery.sizeOf(context).width < 360 ? 148.0 : 164.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [BoxShadow(color: Color(0x0F2C583D), blurRadius: 24, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: _copy(done)),
          const SizedBox(width: 12),
          SizedBox(width: calWidth, child: _calendar()),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: _Goal(
              name: '월 누적 ${AttendRules.monthTarget}일',
              desc: '하루 쉬어도 괜찮아요',
              reward: AttendRules.monthBonus,
              value: attendance.monthCount,
              max: AttendRules.monthTarget,
              tone: _GoalTone.mint,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _Goal(
              name: '${AttendRules.streakEvery}일 연속',
              desc: '연속 ${AttendRules.streakEvery}일마다 보너스',
              reward: AttendRules.streakBonus,
              value: attendance.streakInWeek,
              max: AttendRules.streakEvery,
              tone: _GoalTone.peach,
            ),
          ),
        ]),
        _rules(),
      ]),
    );
  }

  /// 왼쪽 — 인사말과 출석 버튼 (.g3-att-copy)
  Widget _copy(bool done) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('하루 한 번, 작은 보너스', style: AppType.caption.copyWith(fontSize: 11, color: AppColors.attendEyebrow)),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Text(
          done ? '오늘도\n출석했어요' : '오늘도\n반가워요!',
          style: AppType.section.copyWith(fontSize: 24, height: 1.3, color: AppColors.attendTitle),
        ),
      ),
      Text.rich(
        TextSpan(style: AppType.caption.copyWith(fontSize: 11, color: AppColors.attendMeta), children: [
          const TextSpan(text: '이번 달 '),
          TextSpan(
            text: '${attendance.monthCount}일',
            style: TextStyle(color: AppColors.attendPoint, fontWeight: AppType.w600),
          ),
          const TextSpan(text: '째 출석'),
        ]),
      ),
      const SizedBox(height: 12),
      _CheckInButton(done: done, reward: attendance.todayReward, onTap: onCheckIn),
    ]);
  }

  /// 오른쪽 — 이번 달 달력 (.g3-calendar)
  Widget _calendar() {
    final month = int.parse(attendance.today.substring(5, 7));
    final cells = attendance.firstWeekday + attendance.daysInMonth;
    final rows = (cells / 7).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      decoration: BoxDecoration(color: AppColors.calBg, borderRadius: BorderRadius.circular(19)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 7),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$month월', style: AppType.sectionSmall.copyWith(fontSize: 14, color: AppColors.calTitle)),
            Text('○ 출석', style: AppType.caption.copyWith(fontSize: 9, color: AppColors.calHead)),
          ]),
        ),
        Row(
          children: [
            for (final w in const ['일', '월', '화', '수', '목', '금', '토'])
              Expanded(
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: AppType.caption.copyWith(fontSize: 8, fontWeight: AppType.w500, color: AppColors.calHead),
                ),
              ),
          ],
        ),
        for (int row = 0; row < rows; row++)
          Row(
            children: [
              for (int col = 0; col < 7; col++)
                Expanded(child: _day(row * 7 + col - attendance.firstWeekday + 1)),
            ],
          ),
      ]),
    );
  }

  Widget _day(int day) {
    if (day < 1 || day > attendance.daysInMonth) return const SizedBox(height: 24);

    final attended = attendance.attendedOn(day);
    final today = day == attendance.todayDay;
    final future = day > attendance.todayDay;

    Color ink = AppColors.calDay;
    Color? bg;
    Border? border;
    if (future) ink = AppColors.calFuture;
    if (today) {
      bg = AppColors.calTodayBg;
      ink = AppColors.calTodayInk;
    }
    if (attended) {
      bg = AppColors.calDoneBg;
      ink = AppColors.calDoneInk;
      border = Border.all(color: AppColors.calDoneLine, width: 2);
    }

    return SizedBox(
      height: 24,
      child: Center(
        child: Container(
          width: 21,
          height: 21,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, border: border, shape: BoxShape.circle),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0,
              color: ink,
              fontWeight: attended || today ? AppType.w700 : AppType.w400,
            ),
          ),
        ),
      ),
    );
  }

  /// 아래 — 보상 기준 펼침 (.g3-att-rules)
  Widget _rules() {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent, fontFamily: AppType.family),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        minTileHeight: 40,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: AppColors.attendRule,
        collapsedIconColor: AppColors.attendRule,
        title: Text(
          '출석 보상 기준',
          textAlign: TextAlign.center,
          style: AppType.caption.copyWith(fontSize: 10, color: AppColors.attendRule),
        ),
        children: [
          Text(
            AttendRules.guide,
            style: AppType.caption.copyWith(fontSize: 10, height: 1.7, color: AppColors.attendRule),
          ),
        ],
      ),
    );
  }
}

class _CheckInButton extends StatelessWidget {
  final bool done;
  final int reward;
  final VoidCallback onTap;
  const _CheckInButton({required this.done, required this.reward, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: done ? null : onTap,
      style: TextButton.styleFrom(
        backgroundColor: done ? AppColors.page : AppColors.yellow,
        disabledBackgroundColor: AppColors.page,
        foregroundColor: AppColors.calTodayInk,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
      ),
      child: Text(
        done ? '✓ 출석 완료' : '+${nf(reward)}P 받기',
        style: AppType.button.copyWith(fontSize: 12.5, fontWeight: AppType.w700, color: done ? AppColors.sub : AppColors.calTodayInk),
      ),
    );
  }
}

enum _GoalTone { mint, peach }

/// 월 누적 · 연속 게이지 한 칸 (.g3-att-missions > div)
class _Goal extends StatelessWidget {
  final String name;
  final String desc;
  final int reward;
  final int value;
  final int max;
  final _GoalTone tone;

  const _Goal({
    required this.name,
    required this.desc,
    required this.reward,
    required this.value,
    required this.max,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final mint = tone == _GoalTone.mint;
    final bg = mint ? AppColors.goalMintBg : AppColors.goalPeachBg;
    final bar = mint ? AppColors.goalMintBar : AppColors.goalPeachBar;
    final track = mint ? AppColors.goalMintTrack : AppColors.goalPeachTrack;
    final point = mint ? AppColors.goalMintInk : AppColors.goalPeachInk;
    final sub = mint ? AppColors.goalMintSub : AppColors.goalPeachSub;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.emblem)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(name, style: AppType.caption.copyWith(fontSize: 11, fontWeight: AppType.w600, color: AppColors.ink))),
          Text('+${nf(reward)}P', style: AppType.caption.copyWith(fontSize: 10, fontWeight: AppType.w600, color: point)),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : (value / max).clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation(bar),
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(desc, style: AppType.caption.copyWith(fontSize: 9, height: 1.4, color: sub))),
          Text('$value/$max', style: AppType.caption.copyWith(fontSize: 9, fontWeight: AppType.w600, color: sub)),
        ]),
      ]),
    );
  }
}
