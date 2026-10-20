import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'backend.dart';

/// 거래 알림(FCM) — 이 기기의 토큰을 계정에 등록·해제하고, 앱이 켜져 있을 때 온 알림을 화면에 넘긴다.
///
/// 토큰은 `users/{uid}/fcmTokens/{token}`에 둔다. 서버(functions/src/notify)가 이 토큰으로 보낸다.
/// 로그아웃할 때는 **로그아웃 전에** [detach]로 지워야 한다. 안 지우면 다음 사람이 이 기기에서
/// 앞사람의 알림을 받는다([AuthService.beforeSignOut]).
class PushService {
  String? _uid;
  String? _token;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  /// 지원하는 환경: 서버 연결 + Android·iOS
  bool get _supported =>
      Backend.ready && !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  CollectionReference<Map<String, dynamic>> _tokens(String uid) => Backend.users.doc(uid).collection('fcmTokens');

  Future<void> attach(String uid, {required void Function(String title, String body) onForeground}) async {
    if (!_supported || _uid == uid) return;
    await detach();
    _uid = uid;
    try {
      final messaging = FirebaseMessaging.instance;
      final perm = await messaging.requestPermission();
      if (perm.authorizationStatus == AuthorizationStatus.denied) return; // 알림 거부 — 앱 안 알림함으로만 본다
      final token = await messaging.getToken();
      if (_uid != uid) return; // 기다리는 사이 다른 계정으로 바뀜
      if (token != null) await _save(uid, token);
      _refreshSub = messaging.onTokenRefresh.listen((t) => _save(uid, t));
      _foregroundSub = FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        if (n != null) onForeground(n.title ?? '알림', n.body ?? '');
      });
    } catch (e) {
      debugPrint('알림 등록 실패: $e');
    }
  }

  Future<void> detach() async {
    await _refreshSub?.cancel();
    await _foregroundSub?.cancel();
    _refreshSub = null;
    _foregroundSub = null;
    final uid = _uid, token = _token;
    _uid = null;
    _token = null;
    if (uid != null && token != null) await Backend.push(() => _tokens(uid).doc(token).delete());
  }

  Future<void> _save(String uid, String token) async {
    final old = _token;
    _token = token;
    await Backend.push(() async {
      if (old != null && old != token) await _tokens(uid).doc(old).delete();
      await _tokens(uid).doc(token).set({
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
