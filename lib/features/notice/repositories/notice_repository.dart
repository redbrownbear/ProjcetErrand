import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/storage/local_store.dart';
import '../models/notice.dart';

/// 공지 읽기(누구나 — 보안 규칙). 마지막으로 목록을 본 시각은 이 기기에만 둔다(새 글 표시용).
class NoticeRepository {
  const NoticeRepository();

  Stream<List<Notice>> watch({int limit = 50}) {
    if (!Backend.ready) return Stream<List<Notice>>.value(const []);
    return Backend.db
        .collection('notices')
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs)
                if (Notice.fromDoc(d.id, d.data()) case final n?) n,
            ])
        .handleError((Object e) => debugPrint('공지 구독 실패: $e'));
  }

  static DateTime? get seenAt {
    final ms = LocalStore.read<int>('noticeSeenAt', 0);
    return ms == 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static void markSeen(DateTime at) => LocalStore.write('noticeSeenAt', at.millisecondsSinceEpoch);
}
