import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/live_query.dart';
import '../../../core/backend/server_api.dart';

/// 거래 사진 한 장 (`trades/{id}/photos`). 서버 함수 addTradePhoto만 만든다(A37).
class TradePhoto {
  final String id;
  final String uid;

  /// requester | helper
  final String role;

  /// proof(완료 인증) | receipt(영수증)
  final String kind;
  final String path;
  final int? amount;
  final String note;
  final DateTime createdAt;
  const TradePhoto({
    required this.id,
    required this.uid,
    required this.role,
    required this.kind,
    required this.path,
    this.amount,
    this.note = '',
    required this.createdAt,
  });

  bool get isReceipt => kind == 'receipt';

  static TradePhoto? fromDoc(String id, Map<String, dynamic> m) {
    final path = m['path'], kind = m['kind'];
    if (path is! String || (kind != 'proof' && kind != 'receipt')) return null;
    final at = m['createdAt'];
    return TradePhoto(
      id: id,
      uid: m['uid'] is String ? m['uid'] as String : '',
      role: m['role'] == 'requester' ? 'requester' : 'helper',
      kind: kind as String,
      path: path,
      amount: m['amount'] is int ? m['amount'] as int : null,
      note: m['note'] is String ? m['note'] as String : '',
      createdAt: at is Timestamp ? at.toDate() : DateTime.now(),
    );
  }
}

/// 거래 사진 올리기 · 보기. 파일은 Storage `trades/{tradeId}/{uid}/…`(당사자만 읽기 — storage.rules),
/// 목록은 Firestore 구독. 사진은 다운로드 링크(누구나 열 수 있음) 대신 규칙을 거치는 [load]로 읽는다.
class PhotoRepository {
  final String tradeId;
  const PhotoRepository(this.tradeId);

  /// 사진 한 장 상한(storage.rules와 같다)
  static const maxBytes = 5 * 1024 * 1024;

  Stream<List<TradePhoto>> watch() {
    if (!Backend.ready) return Stream<List<TradePhoto>>.value(const []);
    return Backend.db
        .collection('trades')
        .doc(tradeId)
        .collection('photos')
        .orderBy('createdAt')
        .live((d) => TradePhoto.fromDoc(d.id, d.data()!), label: '거래 사진');
  }

  /// 올리고 거래에 붙인다. 실패하면 [ServerException]
  Future<void> upload({
    required String uid,
    required Uint8List bytes,
    required String kind,
    String contentType = 'image/jpeg',
    int? amount,
    String note = '',
  }) async {
    final path = await put(tradeId: tradeId, uid: uid, bytes: bytes, contentType: contentType);
    await ServerApi.call('addTradePhoto', {
      'tradeId': tradeId,
      'kind': kind,
      'path': path,
      'amount': ?amount,
      if (note.isNotEmpty) 'note': note,
    });
  }

  /// Storage `trades/{tradeId}/{uid}/`에 파일만 올리고 경로를 돌려준다(거래 사진 · 채팅 사진 공용). 실패하면 [ServerException]
  static Future<String> put({
    required String tradeId,
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String prefix = '',
  }) async {
    if (!Backend.ready) throw const ServerException('서버에 연결되지 않아 지금은 올릴 수 없어요.');
    if (bytes.length >= maxBytes) throw const ServerException('사진이 너무 커요(5MB까지).');
    final ext = contentType.split('/').last;
    final path = 'trades/$tradeId/$uid/$prefix${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await FirebaseStorage.instance.ref(path).putData(bytes, SettableMetadata(contentType: contentType));
    } on FirebaseException catch (e) {
      debugPrint('사진 올리기 실패: ${e.code} ${e.message}');
      throw const ServerException('사진을 올리지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
    return path;
  }

  /// 사진 내용. 못 읽으면 null
  static Future<Uint8List?> load(String path) async {
    if (!Backend.ready) return null;
    try {
      return await FirebaseStorage.instance.ref(path).getData(maxBytes);
    } catch (e) {
      debugPrint('사진 읽기 실패: $e');
      return null;
    }
  }
}
