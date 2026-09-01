class WalkRule {
  final int steps, p;
  const WalkRule(this.steps, this.p);
}

class PointRules {
  static const kakaoFriend = 50;
  static const referral = 100;
  static const invite = 20;
  static const adView = 5;
  static const attendance = 10;
  static const attendance7 = 100;
  static const profile = 50;
  static const firstRequest = 100;
  static const firstHelp = 200;
  static const review = 30;
}

const walkRules = [
  WalkRule(1000, 5),
  WalkRule(3000, 10),
  WalkRule(5000, 15),
  WalkRule(10000, 30),
];
const walkGoal = 10000;
const seaMin = 20000; // 해외 대행 최소 사례비
const pointValue = 1; // 1P ≈ N원

const feeRate = 0.02; // 수수료 기본 2%
const freeTrades = 3; // 신규 첫 3회 수수료 0%

int walkClaimable(int steps) {
  var sum = 0;
  for (final w in walkRules) {
    if (steps >= w.steps) sum += w.p;
  }
  return sum;
}
