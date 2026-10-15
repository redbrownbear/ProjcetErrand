/// 중고장터 · 나눔 물건.
///
/// [price]가 0이면 나눔이다. 판매·나눔 모두 같은 글쓰기에서 올린다(시안 v42).
class UsedItem {
  final int id;
  final String title;
  final String area;
  final int distM;
  final String ago;
  final int price;
  final int chats;
  final int likes;

  /// 사진 대신 그리는 그림 (bike · washer · lamp · chair · shoes · clothes · book · etc)
  final String art;
  final String desc;
  final String seller;
  final bool mine;

  const UsedItem({
    required this.id,
    required this.title,
    required this.area,
    required this.distM,
    required this.ago,
    required this.price,
    this.chats = 0,
    this.likes = 0,
    this.art = 'etc',
    this.desc = '',
    this.seller = '이웃',
    this.mine = false,
  });

  bool get share => price == 0;

  String get distLabel => distM >= 1000 ? '${(distM / 100).round() / 10}km' : '${distM}m';

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'area': area, 'price': price, 'art': art, 'desc': desc, 'seller': seller,
      };

  static UsedItem? fromJson(dynamic j) {
    if (j is! Map || j['id'] is! int || j['title'] is! String) return null;
    return UsedItem(
      id: j['id'] as int,
      title: j['title'] as String,
      area: '${j['area'] ?? ''}',
      distM: 0,
      ago: '방금',
      price: j['price'] is int ? j['price'] as int : 0,
      art: '${j['art'] ?? 'etc'}',
      desc: '${j['desc'] ?? ''}',
      seller: '${j['seller'] ?? '나'}',
      mine: true,
    );
  }
}

const seedUsedItems = [
  UsedItem(id: 6001, title: '아이 자전거 16인치 보조바퀴 포함', area: '서초동', distM: 200, ago: '12분 전', price: 45000, chats: 1, likes: 4, art: 'bike', seller: '서초맘', desc: '2년 탔어요. 보조바퀴 포함, 체인 상태 좋아요. 직거래 선호해요.'),
  UsedItem(id: 6002, title: 'LG 식기세척기 6인용 DTC2NE 화이트', area: '서초2동', distM: 500, ago: '8시간 전', price: 300000, chats: 1, likes: 2, art: 'washer', seller: '이사가요', desc: '이사로 내놓아요. 설치 기사님 연결 가능해요.'),
  UsedItem(id: 6003, title: '책상 스탠드 LED 밝기 3단계', area: '서초2동', distM: 500, ago: '1시간 전', price: 22000, likes: 3, art: 'lamp', seller: '공부중', desc: '6개월 사용했어요. 박스 있어요.'),
  UsedItem(id: 6004, title: '원목 의자 상태 좋아요', area: '방배동', distM: 900, ago: '3시간 전', price: 45000, chats: 2, likes: 5, art: 'chair', seller: '목공방', desc: '원목 의자 1개예요. 흔들림 없어요.'),
  UsedItem(id: 6005, title: '나이키 러닝화 270 두 번 신음', area: '반포동', distM: 1600, ago: '2일 전', price: 28000, likes: 1, art: 'shoes', seller: '러너', desc: '사이즈가 안 맞아서 두 번 신었어요.'),
  // 나눔
  UsedItem(id: 6101, title: '아이 옷 한 상자 나눔해요', area: '서초동', distM: 300, ago: '30분 전', price: 0, chats: 6, likes: 11, art: 'clothes', seller: '서초맘', desc: '90~100 사이즈 아이 옷 한 상자예요. 필요한 분 가져가세요.'),
  UsedItem(id: 6102, title: '요리책 8권 나눔', area: '방배동', distM: 900, ago: '5시간 전', price: 0, chats: 3, likes: 9, art: 'book', seller: '책정리', desc: '요리책 8권 한 번에 가져가실 분.'),
  UsedItem(id: 6103, title: '운동화 나눔 (사이즈 250)', area: '반포동', distM: 1800, ago: '3일 전', price: 0, chats: 2, likes: 6, art: 'shoes', seller: '신발장정리', desc: '몇 번 안 신은 운동화예요.'),
];
