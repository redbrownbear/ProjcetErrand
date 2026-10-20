import 'package:cloud_firestore/cloud_firestore.dart';

/// 부탁에 낸 지원 하나 (`requests/{requestId}/applications/{helperUid}`).
///
/// 서버 함수만 쓰고, 지원자와 그 부탁의 요청자만 읽는다.
/// 상태: pending(대기) · accepted(수락 → 거래 시작) · rejected(거절) · withdrawn(지원자가 철회) · cancelled(수락 뒤 시작 전 취소)
class Application {
  final String requestId;
  final String helperUid;
  final String requesterUid;
  final String helperName;
  final String requestTitle;
  final String status;
  final int? offerPrice;
  final String? msg;
  final String? tradeId;
  final DateTime updatedAt;

  const Application({
    required this.requestId,
    required this.helperUid,
    required this.requesterUid,
    required this.helperName,
    required this.requestTitle,
    required this.status,
    required this.updatedAt,
    this.offerPrice,
    this.msg,
    this.tradeId,
  });

  bool get isPending => status == 'pending';

  /// 앱의 부탁 id는 밀리초 int다. 서버 문서 id가 숫자가 아니면 null.
  int? get requestIdInt => int.tryParse(requestId);

  static Application? fromDoc(String requestId, String helperUid, Map<String, dynamic> m) {
    final status = m['status'];
    if (status is! String) return null;
    final at = m['updatedAt'];
    final offer = m['offerPrice'];
    String text(String k, String fallback) => m[k] is String && (m[k] as String).isNotEmpty ? m[k] as String : fallback;
    return Application(
      requestId: requestId,
      helperUid: helperUid,
      requesterUid: text('requesterUid', ''),
      helperName: text('helperName', '이웃'),
      requestTitle: text('requestTitle', '부탁'),
      status: status,
      offerPrice: offer is int ? offer : null,
      msg: m['msg'] is String ? m['msg'] as String : null,
      tradeId: m['tradeId'] is String ? m['tradeId'] as String : null,
      updatedAt: at is Timestamp ? at.toDate() : DateTime.now(),
    );
  }
}

/// 서버의 거래 문서 (`trades/{tradeId}`). 요청자와 수행자만 읽고, 서버 함수만 쓴다.
class ServerTrade {
  final String id;
  final String requestId;
  final String requesterUid;
  final String helperUid;
  final String title;
  final int price;
  final String status; // matched | working | confirmation | completed | cancelled
  final DateTime updatedAt;

  /// 마지막 채팅 한 줄(서버가 메시지를 받을 때 남긴다)
  final String? lastMessage;
  final DateTime? lastMessageAt;

  /// 사람별 안 읽은 메시지 수 (uid → 개수)
  final Map<String, int> unread;

  const ServerTrade({
    required this.id,
    required this.requestId,
    required this.requesterUid,
    required this.helperUid,
    required this.title,
    required this.price,
    required this.status,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageAt,
    this.unread = const {},
  });

  bool get isOpenForChat => status != 'cancelled';
  int unreadFor(String uid) => unread[uid] ?? 0;

  static ServerTrade? fromDoc(String id, Map<String, dynamic> m) {
    final status = m['status'], rid = m['requestId'];
    if (status is! String || rid is! String) return null;
    final at = m['updatedAt'];
    final last = m['lastMessage'];
    return ServerTrade(
      id: id,
      requestId: rid,
      requesterUid: m['requesterUid'] is String ? m['requesterUid'] as String : '',
      helperUid: m['helperUid'] is String ? m['helperUid'] as String : '',
      title: m['title'] is String ? m['title'] as String : '',
      price: m['price'] is int ? m['price'] as int : 0,
      status: status,
      updatedAt: at is Timestamp ? at.toDate() : DateTime.now(),
      lastMessage: last is Map && last['text'] is String ? last['text'] as String : null,
      lastMessageAt: last is Map && last['at'] is Timestamp ? (last['at'] as Timestamp).toDate() : null,
      unread: {
        if (m['unread'] is Map)
          for (final e in (m['unread'] as Map).entries)
            if (e.value is int) '${e.key}': e.value as int,
      },
    );
  }
}
