import '../models/partner_mission.dart';

/// 미션 목록 안에서 쓰는 3차 필터. (1·2차 메뉴는 [EarnTrack] 참고)
const missionCats = [
  ['all', '전체'], ['signup', '가입'], ['blog', '콘텐츠'], ['survey', '의견'],
  ['visit', '방문'], ['research', '연구·임상'], ['consult', '상담'],
];

const partnerMissions = [
  // ── 간단 미션 (§15: 오퍼월 · 브랜드 미션) ───────────────────────────────
  PartnerMission(id: 'm1', cat: 'signup', group: 'mission', brand: 'OO 앱', icon: '📱', title: 'OO 앱 처음 가입', desc: '신규 가입 후 로그인까지 완료하면 지급돼요.', points: 1500, time: '3분', cond: '신규 가입자 대상', reason: '첫 가입 대상'),
  PartnerMission(id: 'm2', cat: 'signup', group: 'mission', brand: 'OTT', icon: '🎬', title: 'OTT 1개월 무료체험 신청', desc: '무료체험 신청을 완료하면 지급돼요. 기간 내 해지 가능.', points: 3000, time: '5분', cond: '기존 미이용자', reason: '포인트 높은 순'),
  PartnerMission(id: 'm3', cat: 'signup', group: 'mission', brand: '통신', icon: '📶', title: '통신 요금 비교 신청', desc: '요금 비교 상담을 신청하면 지급돼요.', points: 4000, time: '5분', cond: '만 19세 이상', reason: '이번 주 인기'),
  PartnerMission(id: 'm4', cat: 'signup', group: 'mission', brand: '여행', icon: '🧳', title: '여행 서비스 신규가입', desc: '신규 회원가입을 완료하면 지급돼요.', points: 2000, time: '3분', cond: '신규 가입자', reason: '오늘 인기'),
  PartnerMission(id: 'm5', cat: 'shopping', group: 'mission', brand: '쇼핑몰', icon: '🛒', title: '쇼핑몰 첫 구매', desc: '첫 주문을 완료하면 지급돼요.', points: 2500, time: '10분', cond: '첫 구매 한정', reason: '포인트 높은 순'),
  PartnerMission(id: 'm6', cat: 'signup', group: 'mission', brand: '멤버십', icon: '🎫', title: '멤버십 신규가입', desc: '무료 멤버십에 가입하면 지급돼요.', points: 1000, time: '2분', cond: '신규 가입자', reason: '3분이면 끝나요'),
  // 금융은 제휴사 준법감시를 거친 승인 프로모션만 노출한다 (§12)
  PartnerMission(
    id: 'm7', cat: 'signup', group: 'mission', brand: '금융(제휴 프로모션)', icon: '🏦',
    title: '금융 서비스 상담 신청', desc: '제휴사가 승인한 프로모션 페이지에서 상담을 신청하면 지급돼요.',
    points: 3500, time: '5분', cond: '만 19세 이상',
    reason: '포인트 높은 순', verify: '제휴사 신청 완료 확인', payout: '제휴사 검수 후 정산', disclosureKey: 'finance',
  ),
  PartnerMission(id: 'm8', cat: 'experience', group: 'mission', brand: '신규 앱', icon: '✨', title: '새로 나온 앱 3분 사용', desc: '앱 설치 후 3분 이상 사용하면 지급돼요.', points: 300, time: '3분', cond: '누구나', reason: '3분이면 끝나요'),

  // ── 참여·리워드 (§15: 설문 · 현장 서비스 점검 · 모델하우스 · 임상/연구) ──
  PartnerMission(id: 'm9', cat: 'survey', group: 'reward', brand: '리서치', icon: '📝', title: '설문 참여', desc: '3분 설문에 응답하면 지급돼요.', points: 500, time: '3분', cond: '누구나', reason: '오늘 인기'),
  PartnerMission(id: 'm10', cat: 'experience', group: 'mission', brand: '신규 서비스', icon: '🧪', title: '신규 서비스 체험', desc: '체험 후 간단 피드백을 남기면 지급돼요.', points: 1000, time: '7분', cond: '누구나', reason: '포인트 높은 순'),
  PartnerMission(id: 'm11', cat: 'experience', group: 'mission', brand: '리뷰', icon: '⭐', title: '리뷰 남기기', desc: '이용 후기를 작성하면 지급돼요.', points: 300, time: '3분', cond: '이용 경험자', reason: '3분이면 끝나요'),
  PartnerMission(id: 'm12', cat: 'visit', group: 'reward', brand: '성수 팝업', icon: '🏬', title: '성수 OO 팝업 방문', desc: '현장 방문 후 QR 체크인하면 지급돼요.', points: 500, time: '방문', cond: '현장 방문', reason: '근처에서 가능', verify: '현장 QR 체크인'),
  PartnerMission(id: 'm13', cat: 'visit', group: 'reward', brand: '매장', icon: '📍', title: '매장 QR 체크인', desc: '제휴 매장에서 QR을 스캔하면 지급돼요.', points: 300, time: '방문', cond: '현장 방문', reason: '근처에서 가능', verify: '현장 QR 체크인'),
  PartnerMission(id: 'm14', cat: 'visit', group: 'reward', brand: '신규 매장', icon: '🎉', title: '신규 매장 방문 미션', desc: '오픈 매장을 방문 인증하면 지급돼요.', points: 700, time: '방문', cond: '현장 방문', reason: '이번 주 마감', verify: '현장 QR 체크인'),
  PartnerMission(id: 'm15', cat: 'blog', group: 'reward', brand: '맛집 체험단', icon: '✍️', title: '동네 맛집 방문 후기 작성', desc: '제공된 메뉴를 체험하고 블로그·SNS에 후기를 올리면 지급돼요. 사진 3장 이상 권장.', points: 5000, time: '방문+후기', cond: '블로그/SNS 보유', reason: '포인트 높은 순', verify: '게시물 URL 제출', payout: '제휴사 검수 후 7일 내'),
  PartnerMission(id: 'm16', cat: 'blog', group: 'reward', brand: '뷰티 체험단', icon: '💄', title: '신제품 체험 후기 작성', desc: '제품을 사용해보고 솔직한 사용 후기를 블로그에 올리면 지급돼요.', points: 4000, time: '체험+후기', cond: '블로그 보유', reason: '오늘 인기', verify: '게시물 URL 제출', payout: '제휴사 검수 후 7일 내'),
  PartnerMission(id: 'm17', cat: 'blog', group: 'reward', brand: '카페 체험단', icon: '☕', title: '신규 카페 방문 후기', desc: '제공 메뉴를 즐기고 방문 후기를 사진과 함께 올리면 지급돼요.', points: 3000, time: '방문+후기', cond: '블로그/SNS 보유', reason: '근처에서 가능', verify: '게시물 URL 제출', payout: '제휴사 검수 후 7일 내'),
  PartnerMission(id: 'm18', cat: 'survey', group: 'reward', brand: '소비자 인터뷰', icon: '🎤', title: '소비자 인터뷰(온라인)', desc: '정해진 시간에 온라인 인터뷰에 참여하면 지급돼요.', points: 20000, time: '30분', cond: '대상 조건', reason: '고단가', verify: '진행자 완료 처리'),
  PartnerMission(id: 'm19', cat: 'survey', group: 'reward', brand: '좌담회(FGI)', icon: '🗣️', title: '오프라인 좌담회 참여', desc: '지정 장소에서 진행되는 좌담회에 참여하면 지급돼요.', points: 50000, time: '1~2시간', cond: '대상 조건 · 지역', reason: '포인트 높은 순', verify: '현장 참석 확인'),
  PartnerMission(id: 'm20', cat: 'survey', group: 'reward', brand: 'UX 테스트', icon: '🧭', title: '앱 UX 테스트', desc: '지정 앱을 사용하며 피드백을 남기면 지급돼요.', points: 8000, time: '20분', cond: '누구나', reason: '오늘 인기'),

  // 모델하우스 (§3) — 방문 완료형. 분양 계약 성사와는 분리해서 설계한다.
  PartnerMission(
    id: 'm21', cat: 'visit', group: 'reward', brand: '분양대행사', icon: '🏗️',
    title: '모델하우스 방문 · 상담 참여',
    desc: '예약 후 현장을 방문해 안내를 받으면 지급돼요. 참여 조건과 필수 고지사항을 먼저 확인해 주세요.',
    points: 30000, time: '예약+방문', cond: '사전 예약 · 1인 1회',
    reason: '고단가', verify: '현장 QR 또는 담당자 확인', payout: '방문 인증 후 제휴사 정산 주기',
    disclosureKey: 'realEstate',
  ),
  // 임상시험 (§5) — '임상 알바'가 아니라 '참여정보'로 중립 표기한다.
  PartnerMission(
    id: 'm22', cat: 'research', group: 'reward', brand: 'CRO·SMO 제휴', icon: '🩺',
    title: '임상시험 참여정보 확인 · 신청',
    desc: '제휴 기관이 승인한 모집 공고를 확인하고 공식 모집처로 신청하면 돼요. 시험 목적·조건·위험·보상은 승인본 안내를 그대로 따라요.',
    points: 10000, time: '확인 5분', cond: '공고별 참여 조건',
    reason: '고단가', verify: '공식 모집처 접수 확인', payout: '기관 안내 기준',
    disclosureKey: 'clinical',
  ),
  // 대학 연구실 (§14) — 초기 콘텐츠로 가장 확보하기 쉬운 참여 기회.
  PartnerMission(
    id: 'm23', cat: 'research', group: 'reward', brand: '대학 연구실', icon: '🎓',
    title: '연구 참여 기회 (실험·설문)',
    desc: '연구책임자가 승인한 모집 문구 그대로 안내돼요. 참여보상과 소요 시간은 공고 기준이에요.',
    points: 15000, time: '40분', cond: '연구별 참여 조건',
    reason: '이번 주 인기', verify: '연구 담당자 참여 확인', payout: '연구실 정산 기준',
    disclosureKey: 'research',
  ),
  // 보험 (§4) — 가입이 아니라 '적법한 범위의 설명·상담 완료'만 리워드 대상.
  PartnerMission(
    id: 'm24', cat: 'consult', group: 'reward', brand: 'GA 제휴', icon: '🛡️',
    title: '보험 설명·상담 완료 참여',
    desc: '제휴사 준법부서가 승인한 범위의 상담을 끝까지 들으면 지급돼요. 가입 여부는 지급 조건이 아니에요.',
    points: 25000, time: '20분', cond: '만 19세 이상 · 제휴사 대상 기준',
    reason: '고단가', verify: '상담사 완료 처리 + 확인코드', payout: '제휴사 검수 후 익월 정산',
    disclosureKey: 'insurance',
  ),
  // 현장 서비스 점검 (§8 프랜차이즈 CX/QA 제휴)
  PartnerMission(
    id: 'm25', cat: 'visit', group: 'reward', brand: '프랜차이즈 본사', icon: '🔍',
    title: '매장 서비스 점검 리포트',
    desc: '지정 매장을 방문해 체크리스트와 사진을 제출하면 지급돼요.',
    points: 12000, time: '방문+리포트', cond: '지정 매장 · 지역 한정',
    reason: '근처에서 가능', verify: '체크리스트 + 사진 제출', payout: '본사 검수 후 7일 내',
  ),
];

List<PartnerMission> missionsByCat(String cat) {
  if (cat == 'all') return partnerMissions;
  return partnerMissions.where((m) => m.cat == cat).toList();
}

/// §15의 2차 메뉴(참여·리워드 / 간단 미션)로 나눠 본다.
List<PartnerMission> missionsByGroup(String group, {String cat = 'all'}) {
  return partnerMissions.where((m) => m.group == group && (cat == 'all' || m.cat == cat)).toList();
}
