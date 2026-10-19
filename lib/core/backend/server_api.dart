import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'backend.dart';

/// 서버 함수(Cloud Functions, 서울 리전) 호출 창구.
///
/// 지원·수락·거래 단계처럼 **서버가 확정하는 일**은 [Backend.push]처럼 실패를 삼키지 않는다.
/// 실패하면 [ServerException]을 던지고, 화면은 그 메시지를 그대로 보여 준다.
/// 서버 함수가 보내는 오류 문구는 한국어로 쓰여 있다(functions/src/errand/core.ts).
class ServerApi {
  ServerApi._();

  static const region = 'asia-northeast3';

  static Future<Map<String, Object?>> call(String name, Map<String, Object?> data) async {
    if (!Backend.ready) throw const ServerException('서버에 연결되지 않아 지금은 할 수 없어요.');
    try {
      final result = await FirebaseFunctions.instanceFor(
        region: region,
      ).httpsCallable(name).call<Object?>(data).timeout(Backend.timeout * 2);
      final out = result.data;
      return out is Map ? out.map((k, v) => MapEntry('$k', v)) : const {};
    } on FirebaseFunctionsException catch (e) {
      debugPrint('서버 함수 $name 실패: ${e.code} ${e.message}');
      throw ServerException(_message(e));
    } on TimeoutException {
      throw const ServerException('서버 응답이 늦어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  static String _message(FirebaseFunctionsException e) {
    final m = e.message;
    // 서버가 일부러 보낸 안내(한국어)는 그대로, 그 밖의 내부 오류는 일반 문구로
    if (m != null && m.isNotEmpty && e.code != 'internal' && e.code != 'unknown') return m;
    return switch (e.code) {
      'unauthenticated' => '로그인이 필요해요.',
      'unavailable' => '서버에 연결할 수 없어요. 네트워크를 확인해 주세요.',
      _ => '처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
    };
  }
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
  @override
  String toString() => message;
}
