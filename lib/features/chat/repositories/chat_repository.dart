import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/live_query.dart';
import '../../../core/backend/server_api.dart';
import '../../errand/repositories/photo_repository.dart';
import '../models/chat_message.dart';

/// 최소 채팅 (결정 5). 읽기는 구독, 보내기는 서버 함수(연락처·계좌·링크를 가린 뒤 저장).
/// 사진은 거래 사진과 같은 Storage 폴더에 올리고 경로만 보낸다(A38).
class ChatRepository {
  final String tradeId;
  const ChatRepository(this.tradeId);

  Stream<List<ChatMessage>> watch({int limit = 200}) => Backend.db
      .collection('trades')
      .doc(tradeId)
      .collection('messages')
      .orderBy('createdAt')
      .limitToLast(limit)
      .live((d) => ChatMessage.fromDoc(d.id, d.data()!), label: '채팅');

  /// 가려진 부분이 있었으면 true
  Future<bool> send(String text) async {
    final r = await ServerApi.call('sendMessage', {'tradeId': tradeId, 'text': text});
    return r['masked'] == true;
  }

  /// 사진 한 장 보내기. 실패하면 [ServerException]
  Future<void> sendPhoto({required String uid, required Uint8List bytes, String contentType = 'image/jpeg'}) async {
    final path = await PhotoRepository.put(tradeId: tradeId, uid: uid, bytes: bytes, contentType: contentType, prefix: 'chat_');
    await ServerApi.call('sendMessage', {'tradeId': tradeId, 'photoPath': path});
  }

  Future<void> markRead() async {
    try {
      await ServerApi.call('markChatRead', {'tradeId': tradeId});
    } on ServerException catch (e) {
      debugPrint('읽음 표시 실패: $e');
    }
  }
}
