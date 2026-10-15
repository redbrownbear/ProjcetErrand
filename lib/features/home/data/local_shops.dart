/// 우리 동네 제휴 가게 (시안 v77 광고 배너 · '우리 동네 제휴 가게').
///
/// 체험용 예시다. 제휴가 체결된 가게가 아니므로 화면에 '광고' 표시와 함께
/// '제휴 확정 전'이라는 안내를 같이 둔다.
class LocalShop {
  final String name;
  final String short;
  final String icon;
  final String benefit;
  final String cat;
  final String area;
  final int distM;
  final String? extra;
  const LocalShop({
    required this.name,
    required this.short,
    required this.icon,
    required this.benefit,
    required this.cat,
    required this.area,
    required this.distM,
    this.extra,
  });

  String get dist => distM >= 1000 ? '${(distM / 100).round() / 10}km' : '${distM}m';
  String get shortBenefit => switch (short) {
        '카페 오후세시' => '아메리카노 1+1',
        '브레드랩' => '식빵 10%',
        '크린토피아' => '첫 세탁 20%',
        '플로라' => '5% 적립',
        '이마트24' => '+300P',
        _ => benefit,
      };
}

const localShops = [
  LocalShop(name: '카페 오후세시', short: '카페 오후세시', icon: 'coffee', benefit: '평일 오후 아메리카노 1+1', cat: '카페', area: '서초동', distM: 500, extra: '겸사겸사 이웃 전용'),
  LocalShop(name: '브레드랩 서초', short: '브레드랩', icon: 'bread', benefit: '방문 인증하면 식빵 10% 할인 +500P', cat: '베이커리', area: '반포동', distM: 350),
  LocalShop(name: '크린토피아 반포점', short: '크린토피아', icon: 'laundry', benefit: '첫 세탁 20% · 세탁물 찾기 부탁도 OK', cat: '세탁', area: '반포동', distM: 700),
  LocalShop(name: '꽃집 플로라', short: '플로라', icon: 'flower', benefit: '꽃다발 픽업 부탁 시 5% 적립', cat: '꽃집', area: '잠원동', distM: 1100),
  LocalShop(name: '이마트24 서초역점', short: '이마트24', icon: 'store', benefit: '편의점 픽업 미션 참여하고 +300P', cat: '편의점', area: '서초동', distM: 280),
  LocalShop(name: '디저트 모먼트', short: '디저트 모먼트', icon: 'cake', benefit: '케이크 픽업 할인', cat: '디저트', area: '반포동', distM: 1100),
  LocalShop(name: '반포 국수집', short: '반포 국수집', icon: 'noodle', benefit: '포장 10%', cat: '식당', area: '반포동', distM: 600),
];

/// '이런 것도 부탁해도 돼요' 예시
const askIdeas = [
  (icon: 'pet', text: '강아지 잠깐 봐주기'),
  (icon: 'cart', text: '코스트코 가는 사람에게 장보기 부탁'),
  (icon: 'truck', text: '먼 곳 맛집 음식 배달해주기'),
  (icon: 'globe', text: '일본에서 굿즈 사다주기'),
  (icon: 'laundry', text: '세탁물 찾아 문 앞에 두기'),
  (icon: 'queue', text: '병원 접수 줄 대신 서기'),
];
