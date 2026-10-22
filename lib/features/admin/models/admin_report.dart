import 'package:cloud_firestore/cloud_firestore.dart';

/// 처리 결과 — 서버 `REPORT_RESOLUTIONS`(functions/src/admin/core.ts)와 같은 값
enum ReportResolution {
  dismissed('문제 없음'),
  warned('경고'),
  suspended('이용 정지');

  final String label;
  const ReportResolution(this.label);

  static ReportResolution? parse(Object? v) => values.where((r) => r.name == v).firstOrNull;
}

/// 신고 한 건 (`reports/{id}`). 앱이 접수하고(report_sheet), 운영자만 읽는다(보안 규칙).
/// 처리 전에는 status가 없다 — 처리하면 서버가 status 'resolved' · resolution · memo를 쓴다.
class AdminReport {
  final String id;
  final String reporterUid;
  final String targetUid;
  final String? requestId;
  final String reason;
  final String? detail;
  final DateTime createdAt;
  final ReportResolution? resolution;
  final String? memo;
  final DateTime? resolvedAt;

  const AdminReport({
    required this.id,
    required this.reporterUid,
    required this.targetUid,
    required this.reason,
    required this.createdAt,
    this.requestId,
    this.detail,
    this.resolution,
    this.memo,
    this.resolvedAt,
  });

  bool get resolved => resolution != null;

  static AdminReport? fromDoc(String id, Map<String, dynamic> m) {
    final reason = m['reason'], target = m['targetUid'];
    if (reason is! String || target is! String) return null;
    final at = m['createdAt'], done = m['resolvedAt'];
    return AdminReport(
      id: id,
      reporterUid: m['reporterUid'] is String ? m['reporterUid'] as String : '',
      targetUid: target,
      requestId: m['requestId'] is String ? m['requestId'] as String : null,
      reason: reason,
      detail: m['detail'] is String ? m['detail'] as String : null,
      createdAt: at is Timestamp ? at.toDate() : DateTime.fromMillisecondsSinceEpoch(0),
      resolution: m['status'] == 'resolved' ? ReportResolution.parse(m['resolution']) : null,
      memo: m['memo'] is String ? m['memo'] as String : null,
      resolvedAt: done is Timestamp ? done.toDate() : null,
    );
  }
}

/// 신고에 나온 사용자 (`users/{uid}` — 운영자는 읽을 수 있다)
class AdminUser {
  final String uid;
  final String nickname;
  final bool suspended;
  final String? suspendReason;
  const AdminUser({required this.uid, required this.nickname, this.suspended = false, this.suspendReason});

  static AdminUser fromDoc(String uid, Map<String, dynamic>? m) => AdminUser(
    uid: uid,
    nickname: m?['nickname'] is String ? m!['nickname'] as String : '(이름 없음)',
    suspended: m?['suspended'] == true,
    suspendReason: m?['suspendReason'] is String ? m!['suspendReason'] as String : null,
  );
}

/// 신고된 부탁 글 (`requests/{id}`)
class AdminRequest {
  final String id;
  final String title;
  final String status;
  final String who;

  /// 운영자가 내린 글만 'admin' — 금지 품목 검사로 내려간 글은 되돌릴 수 없다
  final String? hiddenBy;
  final String? hiddenReason;
  const AdminRequest({
    required this.id,
    required this.title,
    required this.status,
    required this.who,
    this.hiddenBy,
    this.hiddenReason,
  });

  bool get hidden => status == 'hidden';
  bool get canUnhide => hidden && hiddenBy == 'admin';

  String get statusLabel => switch (status) {
    'open' => '모집 중',
    'matched' => '진행 중',
    'done' => '완료',
    'cancelled' => '취소',
    'expired' => '마감',
    'hidden' => hiddenBy == 'admin' ? '운영자가 내림' : '자동으로 내려감',
    _ => status,
  };

  static AdminRequest fromDoc(String id, Map<String, dynamic> m) => AdminRequest(
    id: id,
    title: m['title'] is String ? m['title'] as String : '(제목 없음)',
    status: m['status'] is String ? m['status'] as String : '',
    who: m['who'] is String ? m['who'] as String : '',
    hiddenBy: m['hiddenBy'] is String ? m['hiddenBy'] as String : null,
    hiddenReason: m['hiddenReason'] is String ? m['hiddenReason'] as String : null,
  );
}
