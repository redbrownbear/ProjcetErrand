import 'package:cloud_firestore/cloud_firestore.dart';

/// 알림함 한 줄 (`users/{uid}/notifications/{id}`). 서버가 만들고, 앱은 읽음 표시만 한다.
class AppNotice {
  final String id;
  final String kind;
  final String title;
  final String body;
  final String? requestId;

  /// '가는 김에' 댓글 알림이면 그 글 id
  final String? tripId;
  final DateTime createdAt;
  final bool read;

  const AppNotice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.requestId,
    this.tripId,
  });

  static AppNotice? fromDoc(String id, Map<String, dynamic> m) {
    final title = m['title'], at = m['createdAt'];
    if (title is! String) return null;
    return AppNotice(
      id: id,
      kind: m['kind'] is String ? m['kind'] as String : '',
      title: title,
      body: m['body'] is String ? m['body'] as String : '',
      requestId: m['requestId'] is String ? m['requestId'] as String : null,
      tripId: m['tripId'] is String ? m['tripId'] as String : null,
      createdAt: at is Timestamp ? at.toDate() : DateTime.now(),
      read: m['readAt'] != null,
    );
  }
}
