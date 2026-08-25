import '../models/task_item.dart';

const items = [
  TaskItem(id: 1, mode: 'ask', cat: 'buy', title: '성심당 빵 대신 사다주기', place: '역삼동', dist: 0.42, mins: 25, price: 12000, who: '복숭아언니', gender: '여', age: 30, temp: 41.2, hot: false, x: 34, y: 30, desc: '성심당 튀김소보로 6개, 판당고 2개 사서 역삼동 카페 앞으로 전달 부탁드려요. 빵값은 앱에서 같이 결제돼요.'),
  TaskItem(id: 2, mode: 'ask', cat: 'line', title: '성수 팝업 줄 40분만 대신 서주기', place: '성수동', dist: 1.1, mins: 40, price: 18000, who: '지금바로', gender: '남', age: 27, temp: 38.5, hot: true, x: 66, y: 22, desc: '디올 팝업 오픈런 줄서기예요. 제가 도착하면 교대해요. 지금 바로 가능한 분! 급해서 HOT 걸었어요.'),
  TaskItem(id: 3, mode: 'ask', cat: 'photo', title: '매장 재고 사진 찍어 보내주기', place: '서초동', dist: 0.3, mins: 10, price: 5000, who: '재고확인', gender: '여', age: 34, temp: 40.0, hot: false, x: 48, y: 46, desc: '나이키 서초점에 특정 신발 재고 있는지 사진으로 확인 부탁해요. 사이즈 270.'),
  TaskItem(id: 4, mode: 'ask', cat: 'pickup', title: '카페 픽업해서 사무실 전달', place: '강남역', dist: 0.55, mins: 15, price: 7000, who: '3층직장인', gender: '남', age: 41, temp: 39.1, hot: false, x: 40, y: 62, desc: '블루보틀 커피 4잔 픽업 후 강남역 오피스 3층으로 전달해주세요.'),
  TaskItem(id: 5, mode: 'ask', cat: 'carpool', title: '내일 아침 판교까지 카풀 (1인)', place: '양재 → 판교', dist: 0.8, mins: 30, price: 6000, who: '출근메이트', gender: '여', age: 33, temp: 42.0, hot: false, x: 72, y: 58, desc: '평일 매일 아침 8시 양재역 출발, 판교 도착. 정기로도 가능해요. 커피값 정도만 받아요.'),
  TaskItem(id: 6, mode: 'ask', cat: 'rent', title: '캠핑 테이블 하루 빌려드려요', place: '반포동', dist: 0.5, mins: 0, price: 8000, who: '장비수집가', gender: '남', age: 38, temp: 43.5, hot: false, x: 30, y: 40, desc: '코베아 롤테이블, 상태 좋아요. 보증금 별도, 앱에서 안전하게 처리돼요.'),
  TaskItem(id: 7, mode: 'share', cat: 'share', title: '이사 정리 중 · 책장 무료 나눔', place: '서초동', dist: 0.35, mins: 0, price: 0, who: '이사2일차', gender: '여', age: 29, temp: 40.8, hot: false, x: 54, y: 36, desc: '3단 책장 상태 양호. 직접 가지러 오실 분! 먼저 오케이한 분께 드려요.'),
  TaskItem(id: 8, mode: 'together', cat: 'movie', title: '오늘 9시 영화 같이 볼 사람?', place: '메가박스 강남', dist: 0, mins: 0, price: 0, who: '혼영탈출', gender: '여', age: 26, temp: 44.1, hot: false, x: 26, y: 74, desc: 'F1 영화 예매했는데 같이 볼 분 구해요. 20대 인증 우대, 끝나고 가볍게 커피도 좋아요.', extra: '관심 8명 · 2자리 남음'),
  TaskItem(id: 9, mode: 'together', cat: 'meal', title: '혼밥 말고 같이 저녁 (부담 X)', place: '서초 골목', dist: 0, mins: 0, price: 0, who: '저녁친구', gender: '남', age: 31, temp: 39.4, hot: false, x: 58, y: 78, desc: '서초동 국밥집 같이 가실 분. 그냥 밥만 먹고 헤어져도 됩니다.', extra: '관심 3명'),
];
