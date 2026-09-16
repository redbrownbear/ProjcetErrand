import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 서버(Firebase) 연결 상태를 한곳에서 판단한다.
///
/// 이 앱은 **서버가 없어도 떠야 한다.** Windows 데스크톱처럼 플러그인이 덜 붙는
/// 환경이나 네트워크가 끊긴 상태에서도 화면은 보여야 하므로, `main()`이
/// 초기화 결과를 여기 기록하고 저장소 계층이 이 값을 보고 갈라진다.
///
/// - [ready]가 true  → Firestore 읽기·쓰기를 시도한다 (실패하면 각 저장소가 로컬로 되돌린다)
/// - [ready]가 false → 이 기기의 [LocalStore]만 쓴다
class Backend {
  Backend._();

  static bool _ready = false;
  static String? _error;

  /// Firebase 초기화가 끝났고 Firestore를 쓸 수 있는가.
  static bool get ready => _ready;

  /// 초기화가 실패했을 때의 사유. 내 정보 화면의 연결 상태 줄에 그대로 보여준다.
  static String? get error => _error;

  static void markReady() {
    _ready = true;
    _error = null;
  }

  static void markFailed(Object e) {
    _ready = false;
    _error = e.toString();
    debugPrint('Firebase 초기화 실패 — 이 기기 저장소로만 동작합니다: $e');
  }

  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get users => db.collection('users');

  /// 공개 부탁글. 문서 id는 [TaskItem.id]를 문자열로 쓴다.
  static CollectionReference<Map<String, dynamic>> get requests => db.collection('requests');

  /// 서버 호출이 매달리지 않도록 공통으로 씌우는 제한 시간.
  /// 실패하면 호출부가 로컬 값으로 이어서 동작한다.
  static const timeout = Duration(seconds: 10);

  /// 서버 호출을 감싼다. 실패·시간 초과는 [fallback]으로 조용히 되돌린다.
  static Future<T> guard<T>(Future<T> Function() run, T fallback) async {
    if (!_ready) return fallback;
    try {
      return await run().timeout(timeout);
    } catch (e) {
      debugPrint('Firestore 호출 실패 (로컬 값으로 대체): $e');
      return fallback;
    }
  }

  /// 쓰기 전용. 실패해도 화면 흐름을 막지 않는다.
  static Future<void> push(Future<void> Function() run) => guard<void>(run, null);
}
