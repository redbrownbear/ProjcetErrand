import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/server_api.dart';

/// 부탁 글 댓글 한 줄 (`requests/{id}/comments`). 서버 함수만 쓴다.
class RequestComment {
  final String id;
  final String uid;
  final String author;
  final String text;
  final DateTime createdAt;
  const RequestComment({required this.id, required this.uid, required this.author, required this.text, required this.createdAt});

  static RequestComment? fromDoc(String id, Map<String, dynamic> m) {
    final text = m['text'], at = m['createdAt'];
    if (text is! String) return null;
    return RequestComment(
      id: id,
      uid: m['uid'] is String ? m['uid'] as String : '',
      author: m['author'] is String ? m['author'] as String : '이웃',
      text: text,
      createdAt: at is Timestamp ? at.toDate() : DateTime.now(),
    );
  }
}

/// 공개 댓글. 읽기는 구독, 쓰기는 서버 함수 addComment(연락처 가리기 · 글쓴이·댓글 단 사람에게 알림).
class CommentRepository {
  final int requestId;
  const CommentRepository(this.requestId);

  Stream<List<RequestComment>> watch() {
    if (!Backend.ready) return Stream<List<RequestComment>>.value(const []);
    return Backend.requests
        .doc('$requestId')
        .collection('comments')
        .orderBy('createdAt')
        .limitToLast(200)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs)
                if (RequestComment.fromDoc(d.id, d.data()) case final c?) c,
            ])
        .handleError((Object e) => debugPrint('댓글 구독 실패: $e'));
  }

  /// 가려진 부분이 있었으면 true. 실패하면 [ServerException]
  Future<bool> add(String text) async {
    final r = await ServerApi.call('addComment', {'requestId': '$requestId', 'text': text});
    return r['masked'] == true;
  }
}
