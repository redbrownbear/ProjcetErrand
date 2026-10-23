import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/live_query.dart';
import '../models/app_notice.dart';

/// 알림함 · 차단 · 신고 (W4·W5). 모두 로그인한 본인 문서만 다룬다(보안 규칙 v2).
class SafetyRepository {
  final String uid;
  const SafetyRepository(this.uid);

  DocumentReference<Map<String, dynamic>> get _me => Backend.users.doc(uid);

  // ── 알림함 ──────────────────────────────────────────────────────────────

  Stream<List<AppNotice>> watchNotices({int limit = 30}) => _me
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .live((d) => AppNotice.fromDoc(d.id, d.data()!), label: '알림함');

  Future<void> markRead(Iterable<String> ids) => Backend.push(() async {
    final batch = Backend.db.batch();
    for (final id in ids) {
      batch.update(_me.collection('notifications').doc(id), {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  });

  // ── 차단 ────────────────────────────────────────────────────────────────

  Stream<Set<String>> watchBlocked() => _me.collection('blocks').live((d) => d.id, label: '차단 목록').map((ids) => ids.toSet());

  /// 차단·해제. 서버 함수가 지원·수락 때 양쪽 차단을 확인한다.
  Future<void> setBlocked(String target, bool on) => Backend.push(() async {
    final doc = _me.collection('blocks').doc(target);
    if (on) {
      await doc.set({'createdAt': FieldValue.serverTimestamp()});
    } else {
      await doc.delete();
    }
  });

  // ── 신고 ────────────────────────────────────────────────────────────────

  /// 신고 접수. 실패하면 false — 사용자에게 다시 시도하라고 알려야 해서 실패를 삼키지 않는다.
  Future<bool> report({required String targetUid, String? requestId, required String reason, String? detail}) =>
      Backend.guard<bool>(() async {
        await Backend.db.collection('reports').add({
          'reporterUid': uid,
          'targetUid': targetUid,
          'requestId': ?requestId,
          'reason': reason,
          if (detail != null && detail.trim().isNotEmpty) 'detail': detail.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }, false);
}
