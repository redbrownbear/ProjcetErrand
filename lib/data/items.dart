import '../models/task_item.dart';

const seedItems = [
  TaskItem(
    id: 1, mode: 'ask', cat: 'buy', title: '성심당 빵 대신 사다주기',
    region: '대전 유성구', place: '성심당 본점', distM: 420, mins: 25, price: 12000,
    who: '복숭아언니', rating: 4.9, reviews: 23, deals: 46, resp: 97, verified: true,
    helpCnt: 12, reqCnt: 34, x: 34, y: 30,
    desc: '튀김소보로 6개, 판당고 2개 사서 전달 부탁드려요. 빵값은 앱에서 같이 결제돼요.',
  ),
  TaskItem(
    id: 2, mode: 'ask', cat: 'line', title: '팝업 줄 40분만 대신 서주기',
    region: '서울 성동구', place: '성수동', distM: 700, mins: 40, price: 18000,
    who: '지금바로', rating: 4.8, reviews: 15, deals: 31, resp: 99, verified: true,
    helpCnt: 3, reqCnt: 21, hot: true, x: 66, y: 22,
    desc: '디올 팝업 오픈런 줄서기예요. 제가 도착하면 교대해요.',
  ),
  TaskItem(
    id: 3, mode: 'ask', cat: 'photo', title: '매장 재고 사진 찍어 보내주기',
    region: '서울 서초구', place: '서초동', distM: 300, mins: 10, price: 5000,
    who: '재고확인', rating: 4.7, reviews: 8, deals: 12, resp: 92, verified: true,
    helpCnt: 0, reqCnt: 8, x: 48, y: 46,
    desc: '나이키 서초점에 신발 재고 있는지 사진으로 확인 부탁해요. 사이즈 270.',
  ),
  TaskItem(
    id: 4, mode: 'ask', cat: 'buy', title: '광안리 어묵 사서 택배로 보내주기',
    region: '부산 수영구', place: '광안리', distM: 320000, mins: 30, price: 15000,
    who: '부산댁', rating: 5.0, reviews: 11, deals: 19, resp: 88, verified: true,
    helpCnt: 9, reqCnt: 4, x: 40, y: 62,
    desc: '삼진어묵 매장에서 몇 가지 사서 택배로 보내주실 분 (택배비 별도).',
  ),
  TaskItem(
    id: 5, mode: 'ask', cat: 'pickup', title: '세탁소 옷 찾아서 문 앞에 두기',
    region: '서울 서초구', place: '방배동', distM: 550, mins: 15, price: 6000,
    who: '야근중', rating: 4.9, reviews: 6, deals: 9, resp: 95, verified: true,
    helpCnt: 1, reqCnt: 5, x: 55, y: 54,
    desc: '방배동 크린토피아에서 코트 3벌 찾아서 저희 집 문 앞에 놔주세요.',
  ),

  // 해외 대행구매
  TaskItem(
    id: 10, mode: 'sea', cat: 'buy', title: '돈키호테에서 곤약젤리·연고 사다주기',
    country: '🇯🇵 일본 도쿄', place: '시부야 돈키호테', distM: 9e9, mins: 0, price: 20000,
    who: '도쿄여행중', rating: 4.9, reviews: 18, deals: 27, resp: 96, verified: true,
    helpCnt: 2, reqCnt: 6, x: 30, y: 30,
    desc: '곤약젤리 6개, 동전파스, 사카무케아 연고 부탁해요. 물건값은 영수증 보고 정산, 사례비 2만원. 다음 주 귀국편에 전달 가능해요.',
  ),
  TaskItem(
    id: 11, mode: 'sea', cat: 'buy', title: '오사카 이치란 컵라면 3개',
    country: '🇯🇵 일본 오사카', place: '돈키호테 도톤보리', distM: 9e9, mins: 0, price: 12000,
    who: '관서출장', rating: 4.6, reviews: 4, deals: 5, resp: 90, verified: true,
    helpCnt: 0, reqCnt: 1, x: 60, y: 40,
    desc: '이치란 컵라면 한정판 3개만요. 캐리어 공간 있으신 분!',
  ),
  TaskItem(
    id: 12, mode: 'sea', cat: 'buy', title: '다이소 재팬 한정 문구 대행',
    country: '🇯🇵 일본 도쿄', place: '신주쿠', distM: 9e9, mins: 0, price: 8000,
    who: '문구덕후', rating: 4.8, reviews: 9, deals: 14, resp: 94, verified: true,
    helpCnt: 5, reqCnt: 3, x: 45, y: 60,
    desc: '일본 다이소 한정 스티커·펜 몇 개요. 목록 드릴게요.',
  ),
  TaskItem(
    id: 13, mode: 'sea', cat: 'buy', title: '코스트코 영양제 대행 (미국 LA)',
    country: '🇺🇸 미국 LA', place: '코스트코', distM: 9e9, mins: 0, price: 30000,
    who: 'LA사는중', rating: 5.0, reviews: 22, deals: 38, resp: 98, verified: true,
    helpCnt: 14, reqCnt: 2, x: 70, y: 62,
    desc: '커클랜드 오메가3, 비타민D 부탁해요. 부피 있어서 사례비 넉넉히 드려요.',
  ),

  // 같이해요 (무료 동행)
  TaskItem(
    id: 6, mode: 'together', cat: 'etc', title: '오늘 9시 영화 같이 볼 사람',
    region: '서울 강남구', place: '메가박스 강남', distM: 800, mins: 0, price: 0,
    who: '혼영탈출', rating: 4.9, reviews: 7, deals: 0, resp: 90, verified: true,
    helpCnt: 5, reqCnt: 9, extra: '관심 8명 · 2자리 남음', x: 26, y: 74,
    desc: 'F1 영화 예매했는데 같이 볼 분 구해요.',
  ),
  TaskItem(
    id: 7, mode: 'together', cat: 'etc', title: '주말 아침 반포천 러닝 같이해요',
    region: '서울 서초구', place: '반포한강공원', distM: 1200, mins: 0, price: 0,
    who: '아침러너', rating: 4.8, reviews: 3, deals: 0, resp: 85, verified: true,
    helpCnt: 2, reqCnt: 4, extra: '관심 5명', x: 52, y: 68,
    desc: '토요일 7시, 5km 가볍게 뛰실 분. 페이스 6분대예요.',
  ),
];

const regions = ['전국', '서울 서초구', '서울 강남구', '서울 성동구', '부산 수영구', '대전 유성구'];
