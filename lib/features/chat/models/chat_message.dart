import 'package:cloud_firestore/cloud_firestore.dart';

/// 채팅 메시지 한 줄 (`trades/{tradeId}/messages/{id}`). 서버가 연락처를 가린 뒤 쓴다.
class ChatMessage {
  final String id;
  final String senderUid;
  final String text;
  final bool masked;
  final DateTime createdAt;

  const ChatMessage({required this.id, required this.senderUid, required this.text, required this.masked, required this.createdAt});

  static ChatMessage? fromDoc(String id, Map<String, dynamic> m) {
    final sender = m['senderUid'], text = m['text'], at = m['createdAt'];
    if (sender is! String || text is! String) return null;
    return ChatMessage(
      id: id,
      senderUid: sender,
      text: text,
      masked: m['masked'] == true,
      createdAt: at is Timestamp ? at.toDate() : DateTime.now(),
    );
  }
}
