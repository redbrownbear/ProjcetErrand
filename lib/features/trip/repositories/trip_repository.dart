import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/server_api.dart';
import '../models/trip_post.dart';

/// '가는 김에' 글(`tripPosts`)과 댓글. 글은 앱이 직접 쓰고, 댓글은 서버 함수(연락처 가리기·글쓴이 알림)로 단다.
class TripRepository {
  const TripRepository();

  static const _col = 'tripPosts';

  Stream<List<TripPost>> watch({int limit = 50}) {
    if (!Backend.ready) return Stream<List<TripPost>>.value(const []);
    return Backend.db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs)
                if (TripPost.fromDoc(d.id, d.data()) case final t?) t,
            ])
        .handleError((Object e) => debugPrint('가는 김에 구독 실패: $e'));
  }

  /// 올리기. 실패하면 예외를 그대로 던진다(화면이 알려 준다)
  Future<void> add(TripPost t, String uid) =>
      Backend.db.collection(_col).doc('${t.id}').set(t.toDoc(uid)).timeout(Backend.timeout);

  Future<void> delete(int id) => Backend.db.collection(_col).doc('$id').delete().timeout(Backend.timeout);

  Stream<List<TripComment>> watchComments(int id) => Backend.db
      .collection(_col)
      .doc('$id')
      .collection('comments')
      .orderBy('createdAt')
      .limitToLast(200)
      .snapshots()
      .map((snap) => [
            for (final d in snap.docs)
              if (TripComment.fromDoc(d.id, d.data()) case final c?) c,
          ])
      .handleError((Object e) => debugPrint('댓글 구독 실패: $e'));

  /// 가려진 부분이 있었으면 true
  Future<bool> comment(int id, String text) async {
    final r = await ServerApi.call('addTripComment', {'postId': '$id', 'text': text});
    return r['masked'] == true;
  }
}
