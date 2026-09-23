import '../models/daily_mission.dart';
import 'point_rules.dart';

/// '가볍게 모으기'에 실제로 올라가는 미션.
///
/// **재원이 있는 것만 둔다.** 출석·퀴즈·걷기처럼 제휴사가 돈을 대지 않는 미션은
/// 전액 우리 마케팅비로 나가서, 사람이 늘수록 손실이 정비례로 커진다.
/// 초기에 감당할 수 있는 구조가 아니라 [parkedMissions]로 내려 두고,
/// 재원이 생기면(제휴 매장이 방문 비용을 내는 등) 그때 이 목록으로 올린다.
///
/// 남은 세 개는 성격이 다르다.
/// - 광고: 노출이 곧 수익이라 **그 자리에서** 지급할 수 있다
/// - 쿠팡·오퍼월: 구매 확정·제휴사 콜백을 **서버가 확인한 뒤**에 지급된다
///
/// 이 차이를 [DailyMission.instant]로 들고 있다. 구분하지 않으면 눌러도
/// 포인트가 안 들어오는 미션이 생기고, 사용자는 고장으로 받아들인다.
const dailyMissions = <DailyMission>[
  DailyMission(
    id: 'ad',
    icon: '🎬',
    title: '광고 영상 보고 적립',
    sub: '30초 영상 한 편 · 하루 ${PointRules.adWatchCap}번까지',
    points: PointRules.adWatch,
    providerId: 'admob',
    action: MissionAction.rewardAd,
    cap: PointRules.adWatchCap,
    verify: '영상 끝까지 시청(리워드 콜백)',
  ),

  // 정액으로 주면 1만원짜리를 산 사람에게도 8만원어치 판 만큼 줘야 해서 건당
  // 적자가 난다. 주문액에 비례해서만 준다 ([PointRules.coupangRate] 참고).
  DailyMission(
    id: 'coupang',
    icon: '🛒',
    title: '오늘의 특가로 주문하기',
    sub: '쿠팡 골드박스에서 주문하면 확정 후 적립',
    points: 0,
    providerId: 'coupang',
    action: MissionAction.deal,
    payout: PayoutKind.rate,
    rate: PointRules.coupangRate,
    instant: false,
    verify: '파트너스 구매 확정 (익월 25일 리포트 · 다다음달 15일 입금)',
  ),

  // 캠페인 목록·단가·노출 대상을 전부 제휴사가 정한다. 우리 화면은 '열기' 버튼
  // 하나뿐이고 안쪽은 제휴사 SDK가 그린다. 그래서 여기 적을 수 있는 건 단가가
  // 아니라 '캠페인마다 다름'뿐이다.
  DailyMission(
    id: 'offerwall',
    icon: '🎁',
    title: '오퍼월에서 골라 하기',
    sub: '앱 설치·가입·구독 캠페인을 한 화면에서',
    points: 0,
    providerId: 'adpopcorn',
    action: MissionAction.offerwall,
    payout: PayoutKind.partner,
    instant: false,
    verify: '제휴사 서버 콜백(postback) 수신',
  ),
];

/// 재원이 없어 지금은 내려 둔 미션.
///
/// 지우지 않는 이유는 둘이다. 실행부([MissionRunner])와 검증 코드가 이미 다
/// 붙어 있어서 재원만 생기면 한 줄 옮겨 되살릴 수 있고, "왜 출석 미션이 없지"라는
/// 질문에 대한 답이 코드에 남아 있어야 하기 때문이다.
///
/// 포인트 값은 재원이 생겼을 때 다시 역산할 자리라 옛 값을 그대로 뒀다.
/// **되살릴 때 반드시 [PointRules]처럼 재원에서 다시 계산한다.**
///
/// | 미션 | 되살릴 조건 |
/// | --- | --- |
/// | 매장 체크인 | 제휴 매장이 방문 1건당 비용을 부담할 때 |
/// | 출석·퀴즈·열람·저장·걷기 | 신규 유입 예산이 잡혀서 상한을 정할 수 있을 때 |
/// | 프로필·첫 부탁·초대 | 위와 같음. 1회성이라 부담은 가장 작다 |
const parkedMissions = <DailyMission>[
  DailyMission(
    id: 'attend', icon: '📅', title: '출석 체크', sub: '하루 한 번 눌러서 연속 출석 이어가기',
    points: 10, providerId: 'inapp', action: MissionAction.attend,
    keyOverride: 'benefit:attend', verify: '버튼 한 번',
  ),
  DailyMission(
    id: 'quiz', icon: '🧠', title: '오늘의 퀴즈', sub: '문제 하나 맞히면 적립',
    points: 20, providerId: 'inapp', action: MissionAction.quiz, verify: '정답 선택',
  ),
  DailyMission(
    id: 'browse', icon: '👀', title: '근처 부탁 3개 열어보기', sub: '오늘 올라온 부탁을 훑어보면 적립',
    points: 10, providerId: 'inapp', action: MissionAction.browse, target: 3, verify: '부탁 상세 3개 열람',
  ),
  DailyMission(
    id: 'bookmark', icon: '🔖', title: '관심 부탁 저장하기', sub: '나중에 할 만한 부탁 하나 담아두기',
    points: 5, providerId: 'inapp', action: MissionAction.bookmark, verify: '관심 저장 1개',
  ),
  DailyMission(
    id: 'walk', icon: '🚶', title: '오늘 3,000보 걷기', sub: '걷는 김에 적립까지',
    points: 10, providerId: 'inapp', action: MissionAction.walk,
    keyOverride: walkRewardKey, verify: '걷기 화면에서 수령',
  ),
  DailyMission(
    id: 'checkin', icon: '📍', title: '동네 매장 체크인', sub: '지금 있는 자리 500m 안 매장에서 체크인',
    points: 30, providerId: 'kakao_local', action: MissionAction.checkIn,
    verify: 'GPS 좌표 + 카카오 로컬 반경 확인',
  ),
  DailyMission(
    id: 'profile', icon: '🙋', title: '프로필 완성하기', sub: '한 번만 채우면 매칭이 빨라져요',
    points: 50, providerId: 'inapp', action: MissionAction.profile, daily: false, verify: '필수 항목 입력 완료',
  ),
  DailyMission(
    id: 'firstpost', icon: '✏️', title: '첫 부탁 올리기', sub: '처음 올린 부탁 하나에 적립',
    points: 100, providerId: 'inapp', action: MissionAction.post, daily: false, verify: '부탁 등록 완료',
  ),
  DailyMission(
    id: 'invite', icon: '💌', title: '친구 초대하기', sub: '초대 링크로 친구가 가입하면 적립',
    points: 100, providerId: 'inapp', action: MissionAction.invite, daily: false, verify: '초대 코드로 가입 확인',
  ),
];

/// 지금 도는 것과 내려 둔 것 전부. id로 찾을 때는 양쪽을 다 본다.
const allMissions = [...dailyMissions, ...parkedMissions];

DailyMission? dailyMissionById(String id) {
  for (final m in allMissions) {
    if (m.id == id) return m;
  }
  return null;
}
