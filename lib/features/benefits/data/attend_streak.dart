class AttendTier {
  final int day, won;
  const AttendTier(this.day, this.won);
}

const attendStreak = [
  AttendTier(1, 100),
  AttendTier(3, 300),
  AttendTier(7, 1000),
  AttendTier(30, 5000),
];
