import '../../errand/models/comment.dart';
import '../models/com_post.dart';

/// 체험용 커뮤니티 글. 시안(v77)에 걸린 글을 옮겼다.
const seedComPosts = [
  // 오늘의 질문 (피드에는 안 나오고 질문 카드로만 열린다)
  ComPost(id: 7000, scope: 'today-local', kind: '질문', title: '우리 동네에서 제일 좋아하는 가게는?', body: '오늘의 질문이에요. 답글을 달면 응모권 +1장을 드려요.', likes: 35, author: '겸사겸사', ago: '오늘', comments: [Comment('서초이웃', '서초역 앞 작은 빵집이요!')]),
  ComPost(id: 7200, scope: 'today-abroad', kind: '질문', title: '해외 나가면 이것만은 꼭 챙긴다 하는 거 뭐예요?', body: '오늘의 질문이에요. 답글을 달면 응모권 +1장을 드려요.', likes: 48, author: '겸사겸사', ago: '오늘', comments: [Comment('여행러', '멀티어댑터요'), Comment('출장러', '보조배터리!')]),
  // 국내 · 우리 동네
  ComPost(id: 7001, scope: 'local', kind: '질문', title: '서초역 근처 세탁소 추천해 주세요', body: '이불 빨래도 맡길 수 있는 곳이면 좋겠어요.', likes: 4, author: '서초이웃', ago: '12분 전', comments: [Comment('반포주민', '서초역 2번 출구 크린토피아 이불 돼요!')]),
  ComPost(id: 7002, scope: 'local', kind: '모임', title: '토요일 아침 반포 한강 러닝 같이해요', body: '7시 반포 한강공원 출발, 5km 천천히 달려요.', likes: 11, author: '아침러너', ago: '1시간 전', comments: [Comment('초보러너', '처음인데 가도 될까요?')]),
  ComPost(id: 7003, scope: 'local', kind: '소식', title: '서초동 새로 생긴 빵집 오픈 이벤트', body: '오픈 기념으로 식빵 10% 할인 중이에요. 이번 주까지예요.', likes: 19, author: '동네소식', ago: '3시간 전'),
  ComPost(id: 7004, scope: 'local', kind: '질문', title: '이사 갈 때 쓸 박스 나눔 받아요', body: '이사 후 남는 박스가 있는 분은 알려주세요. 가지러 갈게요.', likes: 3, author: '이사준비', ago: '어제'),
  // 국내 · 여행
  ComPost(id: 7101, scope: 'travel', kind: '후기', place: '제주', title: '제주 동쪽 2박 3일 후기, 렌터카 없이 가능했어요', body: '버스 노선을 미리 정리해 두면 충분해요. 성산 쪽은 택시를 한 번 섞었어요.', likes: 26, author: '뚜벅이', ago: '1시간 전', comments: [Comment('제주가요', '버스 노선 공유 부탁드려요!')]),
  ComPost(id: 7102, scope: 'travel', kind: '동행', place: '제주', title: '이번 주말 제주 올레길 같이 걸어요', body: '토요일 아침 7길 걷기. 걷기 좋아하시는 분 환영해요.', likes: 8, author: '올레꾼', ago: '4시간 전'),
  ComPost(id: 7103, scope: 'travel', kind: '맛집', place: '부산', title: '부산 돼지국밥 vs 밀면, 현지인 추천', body: '아침엔 국밥, 더운 날 점심엔 밀면이 좋았어요. 가게 이름은 본문에!', likes: 33, author: '부산사람', ago: '2시간 전', comments: [Comment('국밥러', '국밥 승!')]),
  ComPost(id: 7104, scope: 'travel', kind: '후기', place: '강릉', title: '강릉 당일치기, 기차로 다녀온 후기', body: 'KTX 타고 가서 버스로 시내를 돌았어요. 안목해변 일정이 좋았어요.', likes: 14, author: '당일러', ago: '어제'),
  ComPost(id: 7105, scope: 'travel', kind: '동행', place: '여수', title: '여수 밤바다 같이 보실 분 (금요일)', body: '금요일 저녁 낭만포차 거리 구경하실 분 구해요.', likes: 5, author: '밤바다', ago: '어제'),
  ComPost(id: 7106, scope: 'travel', kind: '정보', place: '경주', title: '황리단길 주차 정보 정리', body: '공영주차장은 이른 시간에 만차예요. 근처 외곽 주차장 이용을 추천해요.', likes: 18, author: '경주러', ago: '2일 전'),
  ComPost(id: 7107, scope: 'travel', kind: '맛집', place: '전주', title: '전주 한옥마을 간식 지도', body: '약과, 초코파이, 꼬치까지 먹은 순서대로 정리했어요.', likes: 29, author: '간식왕', ago: '3일 전'),
  // 해외
  ComPost(id: 7201, scope: 'abroad', kind: '질문', place: 'jp', title: '오사카 3박 4일, 간사이 패스 필요할까요?', body: '교토랑 나라도 하루씩 갈 예정이에요. 패스를 사는 게 이득인지 궁금해요.', likes: 12, author: '오사카가는중', ago: '18분 전', comments: [Comment('간사이러', '교토·나라 다 가시면 이득이에요'), Comment('JR덕후', '하루카 포함이면 더 좋아요')]),
  ComPost(id: 7202, scope: 'abroad', kind: '동행', place: 'jp', title: '다음 주 도쿄 혼자 가는데 저녁 같이 드실 분', body: '도쿄 4일 있어요. 이자카야 한 번 같이 가요. 20~30대 환영!', likes: 7, author: '도쿄행', ago: '1시간 전', comments: [Comment('혼여족', '저도 그 주에 있어요!')]),
  ComPost(id: 7203, scope: 'abroad', kind: '후기', place: 'jp', title: '시부야 스카이 일몰 시간대 후기', body: '일몰 30분 전에 올라가면 줄 없이 자리 잡을 수 있었어요. 주말은 예약 필수예요.', likes: 31, author: '사진러', ago: '3시간 전', comments: [Comment('도쿄초보', '예약 팁 감사해요')]),
  ComPost(id: 7204, scope: 'abroad', kind: '질문', place: 'us', title: 'LA 렌터카 보험 꼭 필요할까요?', body: '카드 자동차 보험이 있는데 현지 보험을 추가로 들어야 하는지 궁금해요.', likes: 9, author: '서부여행', ago: '2시간 전', comments: [Comment('LA거주', '대인 보험은 꼭 추가하세요')]),
  ComPost(id: 7205, scope: 'abroad', kind: '정보', place: 'us', title: 'ESTA 신청할 때 주의할 점 정리', body: '출국 72시간 전에는 신청을 마치는 걸 권해요. 공식 사이트만 이용하세요.', likes: 44, author: '정보통', ago: '어제'),
  ComPost(id: 7206, scope: 'abroad', kind: '정보', place: 'gb', title: '런던 지하철 컨택리스 결제 꿀팁', body: '교통카드 대신 컨택리스 카드를 쓰면 일일 상한까지만 청구돼요.', likes: 27, author: '런던댁', ago: '어제', comments: [Comment('유럽여행', '해외결제 수수료 없는 카드 추천!')]),
  ComPost(id: 7207, scope: 'abroad', kind: '맛집', place: 'vn', title: '다낭 로컬 쌀국수 3곳 후기', body: '한국인 많은 곳 말고 현지 분들이 줄 서는 곳 위주로 정리했어요.', likes: 38, author: '다낭파', ago: '2일 전', comments: [Comment('쌀국수', '저장해요')]),
  ComPost(id: 7208, scope: 'abroad', kind: '맛집', place: 'tw', title: '타이베이 야시장 추천 순위', body: '스린, 라오허제, 닝샤 순으로 갔어요. 간식은 닝샤가 제일 좋았어요.', likes: 21, author: '대만러버', ago: '3일 전'),
  ComPost(id: 7209, scope: 'abroad', kind: '후기', place: 'tw', title: '펑리수 매장별 맛 비교 후기', body: '세 군데를 사 와서 비교했어요. 단맛이 덜한 곳을 찾는 분께 추천해요.', likes: 15, author: '단짠', ago: '3일 전', comments: [Comment('펑리수', '써니힐이 최고')]),
];

/// 오늘의 질문 글 id (답글 달면 응모권 +1)
const todayQuestionIds = {'local': 7000, 'abroad': 7200};

/// 국내 여행 지역 칩
const travelPlaces = [
  (place: '제주', emoji: '🍊'),
  (place: '부산', emoji: '🌊'),
  (place: '강릉', emoji: '☕'),
  (place: '여수', emoji: '🌙'),
  (place: '경주', emoji: '🏯'),
  (place: '전주', emoji: '🍚'),
];

/// 해외 나라 칩
const abroadPlaces = [
  (cc: 'jp', name: '일본'),
  (cc: 'us', name: '미국'),
  (cc: 'gb', name: '영국'),
  (cc: 'vn', name: '베트남'),
  (cc: 'tw', name: '대만'),
];
