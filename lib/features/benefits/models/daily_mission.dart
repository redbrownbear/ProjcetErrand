/// 미션 하나를 눌렀을 때 실제로 일어나는 일.
///
/// 화면이 아니라 '행동'을 기준으로 나눴다. 같은 행동이면 검증 방식과 적립 처리가
/// 같아서, 제휴처가 바뀌어도([DailyMission.providerId]) 코드는 그대로 쓴다.
enum MissionAction {
  /// 버튼 한 번 — 출석
  attend,

  /// 오늘의 퀴즈 정답 맞히기
  quiz,

  /// GPS + 카카오 로컬로 반경 안 매장을 확인한 뒤 체크인
  checkIn,

  /// 쿠팡 파트너스 골드박스 특가 열람
  deal,

  /// 리워드 광고 영상 시청
  rewardAd,

  /// 걷기 화면으로 이동
  walk,

  /// 앱 안에서 부탁 상세를 [DailyMission.target]개 열어보기
  browse,

  /// 관심 저장 [DailyMission.target]개
  bookmark,

  /// 부탁 올리기
  post,

  /// 친구 초대 링크 공유
  invite,

  /// 프로필 채우기
  profile,

  /// 오퍼월 열기
  offerwall,

  /// 외부 캠페인 링크 열기
  external,
}

/// 지급액이 어떻게 정해지는가.
///
/// 처음에는 미션마다 포인트가 정해진 숫자 하나라고 봤는데, 재원을 기준으로 다시
/// 보니 그게 성립하는 건 광고뿐이었다. 쿠팡은 얼마짜리를 샀는지에 따라 달라지고,
/// 오퍼월은 캠페인마다 제휴사가 단가를 내려 준다. 화면에 '+2,500P'라고 못 박으면
/// 실제로 들어오는 값과 어긋나므로, 정해진 값이 없다는 사실 자체를 들고 있는다.
enum PayoutKind {
  /// [DailyMission.points]가 그대로 지급된다
  fixed,

  /// 거래 금액에 [DailyMission.rate]를 곱해 정해진다 (쿠팡 구매 확정)
  rate,

  /// 제휴사가 캠페인마다 단가를 내려 준다 (오퍼월)
  partner,
}

/// '가볍게 모으기'에 실제로 올라가는 미션.
///
/// [PartnerMission]이 제휴사가 집행하는 캠페인(설문·방문·상담)이라면, 이쪽은
/// 오늘 앱을 켠 사람이 몇 분 안에 끝낼 수 있는 일이다. 그래서 무엇으로 완료를
/// 인정하는지를 사람 말이 아니라 [action]이라는 코드로 들고 있다.
class DailyMission {
  final String id, icon, title, sub;

  /// 1회 적립 포인트. [payout]이 [PayoutKind.fixed]일 때만 쓴다.
  final int points;

  /// [missionProviders]의 id — 포인트 재원과 연동 상태를 여기서 읽는다
  final String providerId;
  final MissionAction action;

  /// 하루에 받을 수 있는 횟수. 1보다 크면 적립 원장 키에 회차를 붙인다.
  final int cap;

  /// true면 매일 초기화, false면 계정당 한 번
  final bool daily;

  /// 카운터형 미션의 목표 횟수 (상세 3개 열람 등). 아니면 1.
  final int target;

  /// 완료 인정 방식 한 줄 — 미션 상세와 목록에 그대로 쓴다
  final String verify;

  /// [MissionAction.external]에서 열 주소
  final String url;

  /// 이미 다른 화면이 쓰고 있는 적립 원장 키. 비어 있으면 `daily:{id}`를 쓴다.
  /// 출석·걷기는 홈과 걷기 화면에도 버튼이 있어서, 그쪽과 같은 키를 써야
  /// 어느 화면에서 눌렀든 하루에 한 번만 지급된다.
  final String keyOverride;

  /// 지급액이 정해지는 방식
  final PayoutKind payout;

  /// [PayoutKind.rate]일 때 거래 금액에 곱하는 비율 (0.01 = 1%)
  final double rate;

  /// 앱에서 버튼을 눌러 그 자리에서 적립되는 미션인지.
  ///
  /// false면 **눌러도 포인트가 즉시 들어오지 않는다.** 구매 확정이나 제휴사
  /// 콜백처럼 우리 서버가 나중에 확인해야 지급되는 미션이다. 이걸 구분하지 않으면
  /// 목록만 보고 "눌렀는데 왜 안 들어오지"가 된다.
  final bool instant;

  const DailyMission({
    required this.id,
    required this.icon,
    required this.title,
    required this.sub,
    required this.points,
    required this.providerId,
    required this.action,
    required this.verify,
    this.cap = 1,
    this.daily = true,
    this.target = 1,
    this.url = '',
    this.keyOverride = '',
    this.payout = PayoutKind.fixed,
    this.rate = 0,
    this.instant = true,
  });

  /// 거래 금액([amount]원)에서 실제로 적립될 포인트.
  ///
  /// 화면에 '이거 사면 몇 P'를 보여줄 때와, 나중에 서버가 실제 지급할 때 같은 식을
  /// 써야 한다. 위젯 안에 계산을 묻어 두면 두 곳이 어긋나므로 여기 한 곳에 둔다.
  ///
  /// **올림하지 않는다.** 재원보다 더 주는 방향으로 반올림되면 건마다 조금씩
  /// 손해가 나고, 거래가 쌓이면 그 차이가 그대로 적자가 된다.
  int pointsFor(int amount) => switch (payout) {
        // 금액과 무관하게 정해진 값 (광고 시청)
        PayoutKind.fixed => points,
        // 주문액 비례 (쿠팡 구매 확정)
        PayoutKind.rate => amount <= 0 ? 0 : (amount * rate).floor(),
        // 제휴사가 캠페인마다 단가를 정한다. 앱은 알 수 없고 콜백으로 들어온다.
        PayoutKind.partner => 0,
      };

  /// 목록에서 포인트 자리에 넣을 말. 정해진 값이 없으면 숫자 대신 기준을 보여 준다.
  String get payoutLabel => switch (payout) {
        PayoutKind.fixed => '+$points P',
        PayoutKind.rate => '주문액의 ${_percent(rate)}',
        PayoutKind.partner => '캠페인마다 다름',
      };

  static String _percent(double v) {
    final p = v * 100;
    return p == p.roundToDouble() ? '${p.round()}%' : '$p%';
  }

  /// 적립 원장 키. 회차가 있는 미션은 `#n`을 붙여 같은 날 여러 번 받게 한다.
  /// ([RewardLedger]는 키 하나당 하루 한 번만 지급하므로 회차를 키로 만든다)
  String ledgerKey([int nth = 0]) {
    if (keyOverride.isNotEmpty) return keyOverride;
    return cap > 1 ? 'daily:$id#$nth' : 'daily:$id';
  }

  /// 걸린 시간을 사용자에게 보여줄 때 쓰는 대략값
  String get takes => switch (action) {
        MissionAction.rewardAd => '30초',
        MissionAction.quiz => '1분',
        MissionAction.checkIn => '방문',
        MissionAction.walk => '하루',
        MissionAction.browse || MissionAction.bookmark => '2분',
        MissionAction.post => '5분',
        _ => '10초',
      };
}
