import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/server_api.dart';
import '../models/admin_report.dart';

/// 운영자 신고 처리(A36). 읽기는 Firestore(규칙: 신고 · 사용자 문서는 운영자만), 처리는 운영자 서버 함수.
/// 서버 함수는 실패하면 [ServerException]을 던진다 — 화면이 문구를 보여 준다.
class AdminRepository {
  const AdminRepository();

  /// 최근 신고. 처리 전 신고는 status가 없어 서버에서 거를 수 없으니 최근 것을 받아 화면에서 나눈다.
  Stream<List<AdminReport>> watchReports({int limit = 200}) => Backend.db
      .collection('reports')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => [
            for (final d in snap.docs)
              if (AdminReport.fromDoc(d.id, d.data()) case final r?) r,
          ])
      .handleError((Object e) => debugPrint('신고 목록 구독 실패: $e'));

  Stream<AdminUser> watchUser(String uid) =>
      Backend.users.doc(uid).snapshots().map((d) => AdminUser.fromDoc(uid, d.data())).handleError((Object e) => debugPrint('사용자 읽기 실패: $e'));

  Stream<AdminRequest?> watchRequest(String id) => Backend.db
      .collection('requests')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? AdminRequest.fromDoc(d.id, d.data()!) : null)
      .handleError((Object e) => debugPrint('부탁 읽기 실패: $e'));

  Future<void> resolve(String reportId, ReportResolution resolution, String memo) => ServerApi.call('adminResolveReport', {
    'reportId': reportId,
    'resolution': resolution.name,
    if (memo.trim().isNotEmpty) 'memo': memo.trim(),
  });

  Future<void> setSuspended(String uid, bool suspended, {String? reason}) =>
      ServerApi.call('adminSetSuspended', {'uid': uid, 'suspended': suspended, 'reason': ?reason});

  Future<void> setRequestHidden(String requestId, bool hidden, {String? reason}) =>
      ServerApi.call('adminSetRequestHidden', {'requestId': requestId, 'hidden': hidden, 'reason': ?reason});
}
