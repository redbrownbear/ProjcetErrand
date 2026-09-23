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

  // ── '가볍게 모으기' 데일리 미션 단가 ─────────────────────────────────
  //
  // 단가는 감이 아니라 **재원에서 역산한다.** 제휴사에서 들어오는 돈이 얼마인지
  // 먼저 잡고, 그중 몇 퍼센트를 넘길지 정한 다음, 그 결과를 여기 적는다.
  // 그래서 각 상수 위에 '얼마가 들어오는지'를 같이 적어 둔다 — 나중에 요율이
  // 바뀌었을 때 숫자만 보고 고치면 다시 적자가 된다.
  //
  // 지급률은 오퍼월 업계 관행(유저 50~80%, 70/30이 일반적)을 기준으로 잡되,
  // 재원이 불확실할수록 낮춘다.

  /// 리워드 영상 1회 노출 수익의 **하단** 추정치(원).
  /// eCPM $8 · 환율 1,400원 기준. 밴드 상단($15)은 21원쯤 된다.
  /// 단가는 항상 이 하단을 기준으로 잡는다 — 상단으로 잡으면 실측이 나쁘게
  /// 나왔을 때 곧바로 역마진이다.
  static const adRevenueLow = 11;

  /// 광고 수익 중 사용자에게 넘기는 비율
  static const adShare = 0.5;

  /// 리워드 광고 1회 시청. 하루 [adWatchCap]회까지.
  ///
  /// `adRevenueLow × adShare`를 내린 값이다. 최악의 eCPM에서도 45%,
  /// 밴드 상단이면 24% 지급이라 어느 쪽에서도 남는다.
  ///
  /// **낮게 시작하는 게 의도다.** 실측 후 올리는 건 쉽지만 내리는 건 약관 근거가
  /// 있어도 불만이 남는다. 3개월 실측 뒤 이 식으로 다시 뽑는다.
  static const adWatch = 5;
  static const adWatchCap = 3;

  /// 쿠팡 구매 확정 시 **주문액**에 곱하는 비율.
  ///
  /// 재원: 파트너스 수수료가 카테고리별 1~3%다. 정액으로 주면 1만원짜리를 산
  /// 사람에게도 8만원어치 판 만큼 줘야 해서 건당 적자가 난다. 반드시 정률로 간다.
  /// 수수료를 낮게 잡아(2%) 그중 절반을 넘기는 셈이라 어느 카테고리에서도 남는다.
  static const coupangRate = 0.01;

  /// 오퍼월·CPA에서 제휴사 단가 중 사용자에게 넘기는 비율.
  /// 건당 재원이 확정돼 있어 업계 표준을 그대로 쓴다. 남는 35%가 결제·운영·어뷰징
  /// 손실을 흡수한다.
  static const offerwallShare = 0.65;

  /// 제휴사가 알려준 캠페인 단가([partnerPayout]원)에서 사용자에게 줄 포인트.
  ///
  /// 오퍼월 콜백이 들어왔을 때 서버가 쓸 식이다. [DailyMission.pointsFor]와 같은
  /// 이유로 내림한다 — 재원보다 더 주는 방향으로 반올림되면 건마다 적자가 난다.
  static int offerwallPoints(int partnerPayout) =>
      partnerPayout <= 0 ? 0 : (partnerPayout * offerwallShare).floor();
}

const walkRules = [
  WalkRule(1000, 5),
  WalkRule(3000, 10),
  WalkRule(5000, 15),
  WalkRule(10000, 30),
];
const walkGoal = 10000;

/// 걷기 적립 원장 키. 홈·혜택 탭·걷기 화면 세 곳에 버튼이 있어서, 같은 키를 써야
/// 어느 화면에서 눌렀든 하루에 한 번만 지급된다.
const walkRewardKey = 'walk';
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
