import '../../../core/backend/backend.dart';
import '../../../core/backend/live_query.dart';
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
        .live((d) => Notice.fromDoc(d.id, d.data()!), label: '공지');
  }

  static DateTime? get seenAt {
    final ms = LocalStore.read<int>('noticeSeenAt', 0);
    return ms == 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static void markSeen(DateTime at) => LocalStore.write('noticeSeenAt', at.millisecondsSinceEpoch);
}
