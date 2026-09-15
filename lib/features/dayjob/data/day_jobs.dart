import '../models/day_job.dart';

/// 체험용 일감 데이터. 실제 공고는 행사대행사·공연기획사·전시/컨벤션사(PCO)와의
/// 제휴 또는 기존 단기인력 사업자의 공고 연동으로 채운다. (가이드 §6·§11)
const dayJobs = [
  DayJob(
    id: 'd1', icon: '🎪', org: '○○이벤트(행사대행)', cat: '행사',
    title: '주말 페스티벌 현장 안내 스태프',
    desc: '관람객 동선 안내와 입장 확인을 맡아요. 현장 교육 30분 후 바로 투입돼요.',
    pay: 110000, payKind: '일당', hours: '8시간 · 10:00~18:00',
    place: '서울 서초구 양재시민의숲', region: '서초구',
    payDate: '근무 익일 지급', level: '보통', gear: '검정 상하의 · 운동화',
    idCheck: '본인인증 + 신분증 확인', source: '직접 제휴', closing: '2일 전 마감',
  ),
  DayJob(
    id: 'd2', icon: '🎤', org: '○○공연기획', cat: '공연',
    title: '콘서트 티켓 확인·좌석 안내',
    desc: '입장 게이트에서 티켓을 확인하고 좌석을 안내해요. 서서 하는 업무예요.',
    pay: 95000, payKind: '일당', hours: '6시간 · 16:00~22:00',
    place: '서울 송파구 공연장', region: '송파구',
    payDate: '익월 10일 지급', level: '쉬움', gear: '흰 셔츠 · 검정 바지',
    idCheck: '본인인증', source: '직접 제휴', closing: '선착순 마감',
  ),
  DayJob(
    id: 'd3', icon: '🏢', org: '○○컨벤션(PCO)', cat: '전시',
    title: '전시 부스 등록데스크 운영',
    desc: '방문객 등록을 돕고 명찰을 발급해요. 앉아서 하는 업무가 많아요.',
    pay: 100000, payKind: '일당', hours: '7시간 · 09:00~16:00',
    place: '서울 강남구 코엑스', region: '강남구',
    payDate: '근무 익일 지급', level: '쉬움', gear: '단정한 복장',
    idCheck: '본인인증 + 신분증 확인', source: '직접 제휴', closing: '3일 전 마감',
  ),
  DayJob(
    id: 'd4', icon: '📦', org: '○○물류센터', cat: '단기',
    title: '오전 단기 상품 분류',
    desc: '컨베이어에서 상품을 분류해요. 서서 움직이는 업무예요.',
    pay: 78000, payKind: '일급', hours: '5시간 · 06:00~11:00',
    place: '경기 성남시 물류센터', region: '성남시',
    payDate: '당일 지급', level: '힘듦', gear: '편한 복장 · 장갑 지급',
    idCheck: '신분증 확인', source: '공고 연동', closing: '당일 마감',
  ),
  DayJob(
    id: 'd5', icon: '💒', org: '○○웨딩운영', cat: '행사',
    title: '주말 예식 진행 보조',
    desc: '하객 안내와 예식 진행을 보조해요. 식사 제공돼요.',
    pay: 90000, payKind: '일당', hours: '6시간 · 10:00~16:00',
    place: '서울 강남구 웨딩홀', region: '강남구',
    payDate: '근무 당일 지급', level: '보통', gear: '검정 정장',
    idCheck: '본인인증', source: '직접 제휴', closing: '금요일 마감',
  ),
  DayJob(
    id: 'd6', icon: '🧾', org: '○○리서치', cat: '프로젝트',
    title: '매장 서비스 점검(미스터리 쇼퍼) 3일',
    desc: '지정 매장을 방문해 체크리스트를 작성해요. 3일에 나눠 진행해요.',
    pay: 150000, payKind: '건당', hours: '3일 · 회당 약 1시간',
    place: '서초·강남 제휴매장', region: '서초구',
    payDate: '리포트 검수 후 7일 내', level: '보통', gear: '스마트폰(사진 촬영)',
    idCheck: '본인인증', source: '직접 제휴', closing: '모집 인원 충족 시 마감',
  ),
];

List<DayJob> dayJobsByCat(String cat) {
  if (cat == 'all') return dayJobs;
  return dayJobs.where((j) => j.cat == cat).toList();
}
