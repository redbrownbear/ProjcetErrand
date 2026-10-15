import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../errand/models/comment.dart';

/// 커뮤니티 이야기 글 (시안 v42~v44 '커뮤니티는 이야기가 중심').
///
/// 세 갈래로 나뉜다.
/// - local  : 국내 · 우리 동네 (질문 · 모임 · 소식)
/// - travel : 국내 · 여행 (후기 · 동행 · 정보 · 맛집) — [place]는 지역 이름
/// - abroad : 해외 (질문 · 동행 · 후기 · 정보 · 맛집) — [place]는 나라 코드
class ComPost {
  final int id;
  final String scope;
  final String kind;
  final String place;
  final String title;
  final String body;
  final int likes;
  final List<Comment> comments;
  final String author;
  final String ago;
  final bool mine;

  /// 후기 글이 이어진 제안 (제안을 받은 뒤 '후기 남기기'로 쓴 글)
  final int? proposalId;

  const ComPost({
    required this.id,
    required this.scope,
    required this.kind,
    this.place = '',
    required this.title,
    required this.body,
    this.likes = 0,
    this.comments = const [],
    required this.author,
    this.ago = '방금',
    this.mine = false,
    this.proposalId,
  });

  ComPost copyWith({List<Comment>? comments, int? likes}) => ComPost(
        id: id, scope: scope, kind: kind, place: place, title: title, body: body,
        likes: likes ?? this.likes, comments: comments ?? this.comments, author: author, ago: ago, mine: mine,
        proposalId: proposalId,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'scope': scope, 'kind': kind, 'place': place, 'title': title, 'body': body,
        'author': author, 'proposalId': proposalId,
        'comments': [for (final c in comments) {'who': c.who, 'text': c.text}],
      };

  static ComPost? fromJson(dynamic j) {
    if (j is! Map || j['id'] is! int || j['title'] is! String) return null;
    return ComPost(
      id: j['id'] as int,
      scope: '${j['scope'] ?? 'local'}',
      kind: '${j['kind'] ?? '질문'}',
      place: '${j['place'] ?? ''}',
      title: j['title'] as String,
      body: '${j['body'] ?? ''}',
      author: '${j['author'] ?? '나'}',
      proposalId: j['proposalId'] is int ? j['proposalId'] as int : null,
      comments: [
        for (final c in (j['comments'] is List ? j['comments'] as List : const []))
          if (c is Map) Comment('${c['who']}', '${c['text']}'),
      ],
      mine: true,
    );
  }
}

/// 글 종류별 배지 색
({Color bg, Color fg}) kindTone(String kind) => switch (kind) {
      '질문' => (bg: const Color(0xFFEAF0FE), fg: const Color(0xFF2F63E8)),
      '모임' || '동행' => (bg: AppColors.purpleSoft, fg: AppColors.purple),
      '소식' || '맛집' => (bg: const Color(0xFFFFF1DC), fg: const Color(0xFFD27700)),
      '후기' => (bg: AppColors.greenSoft, fg: AppColors.greenDeep),
      '정보' => (bg: const Color(0xFFE8F4FB), fg: const Color(0xFF1C7FB5)),
      '제안' => (bg: AppColors.yellowSoft, fg: AppColors.yellowInk),
      _ => (bg: AppColors.page, fg: AppColors.sub),
    };

const localKinds = ['질문', '모임', '소식'];
const travelKinds = ['후기', '동행', '정보', '맛집'];
const abroadKinds = ['질문', '동행', '후기', '정보', '맛집'];
