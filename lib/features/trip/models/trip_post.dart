import 'package:cloud_firestore/cloud_firestore.dart';

/// '가는 김에' 글 — 사람들은 지금 어디로 가고 있을까요?
///
/// 두 방향이 있다.
/// - going : "내일 오사카 가요" — 가는 사람이 알린다. 보는 사람은 댓글로 '부탁'.
/// - asking: "오늘 성수 가시는 분 있나요?" — 필요한 사람이 묻는다. 보는 사람은 댓글로 '도와주기'.
///
/// 서버(`tripPosts/{id}`)에 올라간 글은 모든 계정이 보고 댓글을 단다. 서버가 없을 때만 이 기기에 남는다.
class TripPost {
  final int id;
  final String type; // going | asking
  final String author;
  final String area;
  final String ago;

  /// 해외면 나라 코드(대문자 표시), 국내면 null
  final String? cc;
  final String where;
  final String title;
  final String when;
  final String quote;
  final int comments;

  /// 글쓴이. 예시 글·서버 연결 전 이 기기 글은 null
  final String? ownerUid;
  final DateTime? createdAt;

  /// 서버에 올라간 글인가(댓글을 달 수 있는가)
  final bool server;

  /// 이 기기에만 있는 내 글(서버 연결 전). 서버 글의 '내 글' 여부는 [isMine]으로 본다
  final bool mine;

  const TripPost({
    required this.id,
    required this.type,
    required this.author,
    required this.area,
    this.ago = '방금',
    this.cc,
    this.where = '',
    required this.title,
    required this.when,
    required this.quote,
    this.comments = 0,
    this.ownerUid,
    this.createdAt,
    this.server = false,
    this.mine = false,
  });

  bool get going => type == 'going';

  bool isMine(String? uid) => server ? (uid != null && ownerUid == uid) : mine;

  /// 목록에 보일 시각. 서버 글은 올린 시각에서 계산한다
  String agoAt(DateTime now) {
    final at = createdAt;
    if (at == null) return ago;
    final d = now.difference(at);
    if (d.inMinutes < 1) return '방금';
    if (d.inHours < 1) return '${d.inMinutes}분 전';
    if (d.inDays < 1) return '${d.inHours}시간 전';
    if (d.inDays < 7) return '${d.inDays}일 전';
    return '${at.month}.${at.day}';
  }

  /// '어디로'에서 제목 제안. 사용자가 고칠 수 있다(글쓰기 화면)
  static String suggestTitle(String type, String where) {
    final w = where.trim();
    if (w.isEmpty) return '';
    return type == 'going' ? '$w 가요' : '$w 가시는 분 있나요?';
  }

  /// 서버 문서. 보안 규칙(`tripPosts` 화이트리스트)과 필드를 맞춘다
  Map<String, Object?> toDoc(String uid) => {
    'ownerUid': uid,
    'author': author.length > 20 ? author.substring(0, 20) : author,
    'area': area.length > 40 ? area.substring(0, 40) : area,
    'type': type,
    'cc': cc,
    'where': where,
    'title': title,
    'when': when,
    'quote': quote,
    'commentCount': 0,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static TripPost? fromDoc(String docId, Map<String, dynamic> m) {
    final id = int.tryParse(docId);
    final title = m['title'], quote = m['quote'];
    if (id == null || title is! String || quote is! String) return null;
    String s(String k) => m[k] is String ? m[k] as String : '';
    final at = m['createdAt'];
    return TripPost(
      id: id,
      type: m['type'] == 'asking' ? 'asking' : 'going',
      author: s('author').isEmpty ? '이웃' : s('author'),
      area: s('area'),
      cc: s('cc').isEmpty ? null : s('cc'),
      where: s('where'),
      title: title,
      when: s('when'),
      quote: quote,
      comments: m['commentCount'] is int ? m['commentCount'] as int : 0,
      ownerUid: s('ownerUid').isEmpty ? null : s('ownerUid'),
      // 방금 올린 글은 서버 시각이 채워지기 전에 null로 한 번 온다
      createdAt: at is Timestamp ? at.toDate() : DateTime.now(),
      server: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'author': author,
    'area': area,
    'cc': cc,
    'where': where,
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
      where: '${j['where'] ?? ''}',
      title: j['title'] as String,
      when: '${j['when'] ?? ''}',
      quote: '${j['quote'] ?? ''}',
      mine: true,
    );
  }
}

/// 댓글 한 줄 (`tripPosts/{id}/comments`). 서버 함수만 쓴다
class TripComment {
  final String id;
  final String uid;
  final String author;
  final String text;
  final DateTime createdAt;
  const TripComment({required this.id, required this.uid, required this.author, required this.text, required this.createdAt});

  static TripComment? fromDoc(String id, Map<String, dynamic> m) {
    final text = m['text'], at = m['createdAt'];
    if (text is! String) return null;
    return TripComment(
      id: id,
      uid: m['uid'] is String ? m['uid'] as String : '',
      author: m['author'] is String ? m['author'] as String : '이웃',
      text: text,
      createdAt: at is Timestamp ? at.toDate() : DateTime.now(),
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
