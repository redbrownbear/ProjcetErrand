/// '가는 김에' 글 — 사람들은 지금 어디로 가고 있을까요?
///
/// 두 방향이 있다.
/// - going : "내일 오사카 가요" — 가는 사람이 알린다. 보는 사람은 '부탁하기'.
/// - asking: "오늘 성수 가시는 분 있나요?" — 필요한 사람이 묻는다. 보는 사람은 '도와주기'.
class TripPost {
  final int id;
  final String type; // going | asking
  final String author;
  final String area;
  final String ago;

  /// 해외면 나라 코드(대문자 표시), 국내면 null
  final String? cc;
  final String title;
  final String when;
  final String quote;
  final int comments;
  final bool mine;

  const TripPost({
    required this.id,
    required this.type,
    required this.author,
    required this.area,
    this.ago = '방금',
    this.cc,
    required this.title,
    required this.when,
    required this.quote,
    this.comments = 0,
    this.mine = false,
  });

  bool get going => type == 'going';

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'author': author,
    'area': area,
    'cc': cc,
    'title': title,
    'when': when,
    'quote': quote,
  };

  static TripPost? fromJson(dynamic j) {
    if (j is! Map || j['id'] is! int || j['title'] is! String) return null;
    return TripPost(
      id: j['id'] as int,
      type: j['type'] == 'asking' ? 'asking' : 'going',
      author: '${j['author'] ?? '나'}',
      area: '${j['area'] ?? ''}',
      cc: j['cc'] is String ? j['cc'] as String : null,
      title: j['title'] as String,
      when: '${j['when'] ?? ''}',
      quote: '${j['quote'] ?? ''}',
      mine: true,
    );
  }
}

const seedTripPosts = [
  TripPost(
    id: 8001,
    type: 'going',
    author: '민지',
    area: '반포동',
    ago: '12분 전',
    cc: 'jp',
    title: '내일 오사카 가요',
    when: '출국 · 3박',
    quote: '돈키호테 들를 예정인데 필요한 거 있으면 부탁 주세요.',
    comments: 2,
  ),
  TripPost(
    id: 8002,
    type: 'asking',
    author: '준호',
    area: '서초동',
    ago: '방금',
    title: '오늘 성수 가시는 분 있나요?',
    when: '오늘 오후 · 성수동',
    quote: '팝업 굿즈 하나만 부탁드리고 싶어요.',
    comments: 1,
  ),
  TripPost(
    id: 8003,
    type: 'going',
    author: '수아',
    area: '잠원동',
    ago: '1시간 전',
    title: '토요일에 코스트코 양재점 가요',
    when: '토요일 오전 · 양재동',
    quote: '대용량 나눠 사실 분이나 필요한 거 있으면 말씀 주세요.',
    comments: 3,
  ),
  TripPost(
    id: 8004,
    type: 'asking',
    author: '하람',
    area: '방배동',
    ago: '2시간 전',
    title: '이번 주 대전 가시는 분?',
    when: '이번 주 · 대전',
    quote: '성심당 튀김소보로 부탁하고 싶어요.',
    comments: 0,
  ),
];
