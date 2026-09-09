/// 연속 출석 보상. 지급 단위는 원이 아니라 포인트(P)다.
class AttendTier {
  final int day, points;
  const AttendTier(this.day, this.points);
}

const attendStreak = [
  AttendTier(1, 100),
  AttendTier(3, 300),
  AttendTier(7, 1000),
  AttendTier(30, 5000),
];
