import '../models/partner_mission.dart';

const missionCats = [
  ['all', '전체'], ['signup', '가입'], ['blog', '콘텐츠'], ['survey', '의견'], ['visit', '방문'],
];

const partnerMissions = [
  PartnerMission(id: 'm1', cat: 'signup', brand: 'OO 앱', icon: '📱', title: 'OO 앱 처음 가입', desc: '신규 가입 후 로그인까지 완료하면 지급돼요.', points: 1500, time: '3분', cond: '신규 가입자 대상', reason: '첫 가입 대상'),
  PartnerMission(id: 'm2', cat: 'signup', brand: 'OTT', icon: '🎬', title: 'OTT 1개월 무료체험 신청', desc: '무료체험 신청을 완료하면 지급돼요. 기간 내 해지 가능.', points: 3000, time: '5분', cond: '기존 미이용자', reason: '포인트 높은 순'),
  PartnerMission(id: 'm3', cat: 'signup', brand: '통신', icon: '📶', title: '통신 요금 비교 신청', desc: '요금 비교 상담을 신청하면 지급돼요.', points: 4000, time: '5분', cond: '만 19세 이상', reason: '이번 주 인기'),
  PartnerMission(id: 'm4', cat: 'signup', brand: '여행', icon: '🧳', title: '여행 서비스 신규가입', desc: '신규 회원가입을 완료하면 지급돼요.', points: 2000, time: '3분', cond: '신규 가입자', reason: '오늘 인기'),
  PartnerMission(id: 'm5', cat: 'shopping', brand: '쇼핑몰', icon: '🛒', title: '쇼핑몰 첫 구매', desc: '첫 주문을 완료하면 지급돼요.', points: 2500, time: '10분', cond: '첫 구매 한정', reason: '포인트 높은 순'),
  PartnerMission(id: 'm6', cat: 'signup', brand: '멤버십', icon: '🎫', title: '멤버십 신규가입', desc: '무료 멤버십에 가입하면 지급돼요.', points: 1000, time: '2분', cond: '신규 가입자', reason: '3분이면 끝나요'),
  PartnerMission(id: 'm7', cat: 'signup', brand: '금융', icon: '🏦', title: '금융 서비스 상담 신청', desc: '상담 신청서를 작성하면 지급돼요.', points: 3500, time: '5분', cond: '만 19세 이상', reason: '포인트 높은 순'),
  PartnerMission(id: 'm8', cat: 'experience', brand: '신규 앱', icon: '✨', title: '새로 나온 앱 3분 사용', desc: '앱 설치 후 3분 이상 사용하면 지급돼요.', points: 300, time: '3분', cond: '누구나', reason: '3분이면 끝나요'),
  PartnerMission(id: 'm9', cat: 'survey', brand: '리서치', icon: '📝', title: '설문 참여', desc: '3분 설문에 응답하면 지급돼요.', points: 500, time: '3분', cond: '누구나', reason: '오늘 인기'),
  PartnerMission(id: 'm10', cat: 'experience', brand: '신규 서비스', icon: '🧪', title: '신규 서비스 체험', desc: '체험 후 간단 피드백을 남기면 지급돼요.', points: 1000, time: '7분', cond: '누구나', reason: '포인트 높은 순'),
  PartnerMission(id: 'm11', cat: 'experience', brand: '리뷰', icon: '⭐', title: '리뷰 남기기', desc: '이용 후기를 작성하면 지급돼요.', points: 300, time: '3분', cond: '이용 경험자', reason: '3분이면 끝나요'),
  PartnerMission(id: 'm12', cat: 'visit', brand: '성수 팝업', icon: '🏬', title: '성수 OO 팝업 방문', desc: '현장 방문 후 QR 체크인하면 지급돼요.', points: 500, time: '방문', cond: '현장 방문', reason: '근처에서 가능'),
  PartnerMission(id: 'm13', cat: 'visit', brand: '매장', icon: '📍', title: '매장 QR 체크인', desc: '제휴 매장에서 QR을 스캔하면 지급돼요.', points: 300, time: '방문', cond: '현장 방문', reason: '근처에서 가능'),
  PartnerMission(id: 'm14', cat: 'visit', brand: '신규 매장', icon: '🎉', title: '신규 매장 방문 미션', desc: '오픈 매장을 방문 인증하면 지급돼요.', points: 700, time: '방문', cond: '현장 방문', reason: '이번 주 마감'),
  PartnerMission(id: 'm15', cat: 'blog', brand: '맛집 체험단', icon: '✍️', title: '동네 맛집 방문 후기 작성', desc: '제공된 메뉴를 체험하고 블로그·SNS에 후기를 올리면 지급돼요. 사진 3장 이상 권장.', points: 5000, time: '방문+후기', cond: '블로그/SNS 보유', reason: '포인트 높은 순'),
  PartnerMission(id: 'm16', cat: 'blog', brand: '뷰티 체험단', icon: '💄', title: '신제품 체험 후기 작성', desc: '제품을 사용해보고 솔직한 사용 후기를 블로그에 올리면 지급돼요.', points: 4000, time: '체험+후기', cond: '블로그 보유', reason: '오늘 인기'),
  PartnerMission(id: 'm17', cat: 'blog', brand: '카페 체험단', icon: '☕', title: '신규 카페 방문 후기', desc: '제공 메뉴를 즐기고 방문 후기를 사진과 함께 올리면 지급돼요.', points: 3000, time: '방문+후기', cond: '블로그/SNS 보유', reason: '근처에서 가능'),
  PartnerMission(id: 'm18', cat: 'survey', brand: '소비자 인터뷰', icon: '🎤', title: '소비자 인터뷰(온라인)', desc: '정해진 시간에 온라인 인터뷰에 참여하면 지급돼요.', points: 20000, time: '30분', cond: '대상 조건', reason: '고단가'),
  PartnerMission(id: 'm19', cat: 'survey', brand: '좌담회(FGI)', icon: '🗣️', title: '오프라인 좌담회 참여', desc: '지정 장소에서 진행되는 좌담회에 참여하면 지급돼요.', points: 50000, time: '1~2시간', cond: '대상 조건 · 지역', reason: '포인트 높은 순'),
  PartnerMission(id: 'm20', cat: 'survey', brand: 'UX 테스트', icon: '🧭', title: '앱 UX 테스트', desc: '지정 앱을 사용하며 피드백을 남기면 지급돼요.', points: 8000, time: '20분', cond: '누구나', reason: '오늘 인기'),
];

List<PartnerMission> missionsByCat(String cat) {
  if (cat == 'all') return partnerMissions;
  return partnerMissions.where((m) => m.cat == cat).toList();
}
