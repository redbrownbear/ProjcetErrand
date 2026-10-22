import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/stable_sort.dart';

/// 공지 · 업데이트 한 건 (`notices/{id}`, A33). 운영자가 콘솔 · 스크립트로 올린다(앱은 읽기만).
class Notice {
  static const kinds = {'notice': '공지', 'update': '업데이트', 'event': '이벤트'};

  final String id;
  final String kind;
  final String title;
  final String body;
  final bool pinned;
  final DateTime publishedAt;
  const Notice({required this.id, this.kind = 'notice', required this.title, this.body = '', this.pinned = false, required this.publishedAt});

  String get kindLabel => kinds[kind] ?? '공지';

  /// 숨긴 글 · 제목 없는 글 · 시각 없는 글은 버린다
  static Notice? fromDoc(String id, Map<String, dynamic> m) {
    final at = m['publishedAt'], title = m['title'];
    if (m['hidden'] == true || title is! String || title.trim().isEmpty || at is! Timestamp) return null;
    return Notice(
      id: id,
      kind: kinds.containsKey(m['kind']) ? m['kind'] as String : 'notice',
      title: title.trim(),
      body: m['body'] is String ? m['body'] as String : '',
      pinned: m['pinned'] == true,
      publishedAt: at.toDate(),
    );
  }

  /// 보일 차례가 된 것만(예약 공지는 그 시각부터), 고정 먼저 · 그다음 최신 순
  static List<Notice> visible(List<Notice> all, DateTime now) {
    final out = [for (final n in all) if (!n.publishedAt.isAfter(now)) n];
    out.sortStable((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return out;
  }

  /// 마지막으로 목록을 연 뒤에 올라온 글 수
  static int unseen(List<Notice> visible, DateTime? seenAt) =>
      seenAt == null ? visible.length : visible.where((n) => n.publishedAt.isAfter(seenAt)).length;
}
