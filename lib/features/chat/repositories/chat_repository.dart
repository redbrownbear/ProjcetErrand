import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/server_api.dart';
import '../models/chat_message.dart';

/// 최소 채팅 (결정 5). 읽기는 구독, 보내기는 서버 함수(연락처·계좌·링크를 가린 뒤 저장).
class ChatRepository {
  final String tradeId;
  const ChatRepository(this.tradeId);

  Stream<List<ChatMessage>> watch({int limit = 200}) => Backend.db
      .collection('trades')
      .doc(tradeId)
      .collection('messages')
      .orderBy('createdAt')
      .limitToLast(limit)
      .snapshots()
      .map((snap) => [
            for (final d in snap.docs)
              if (ChatMessage.fromDoc(d.id, d.data()) case final m?) m,
          ])
      .handleError((Object e) => debugPrint('채팅 구독 실패: $e'));

  /// 가려진 부분이 있었으면 true
  Future<bool> send(String text) async {
    final r = await ServerApi.call('sendMessage', {'tradeId': tradeId, 'text': text});
    return r['masked'] == true;
  }

  Future<void> markRead() async {
    try {
      await ServerApi.call('markChatRead', {'tradeId': tradeId});
    } on ServerException catch (e) {
      debugPrint('읽음 표시 실패: $e');
    }
  }
}
