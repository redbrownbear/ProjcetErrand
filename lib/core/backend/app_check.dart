import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Firebase App Check (개발 To-do A35). 서버 함수 · Firestore가 "진짜 우리 앱"에서 온 요청인지 확인하게 한다.
///
/// - 출시 빌드: Android Play Integrity · iOS App Attest
/// - 디버그 빌드: 디버그 제공자. 처음 실행하면 logcat(Xcode 콘솔)에 **디버그 토큰**이 찍힌다 →
///   Firebase 콘솔 › App Check › 앱 › 디버그 토큰 관리에 넣어야 강제(enforce)를 켠 뒤에도 개발 폰이 막히지 않는다.
/// - 웹 · 데스크톱은 건너뛴다(웹은 reCAPTCHA 키가 따로 필요하고 지금은 브라우저 확인용이라).
///
/// 여기서는 토큰만 붙인다. **강제는 서버 쪽 스위치**다 — 함수는 `functions/.env.<프로젝트>`의 `ENFORCE_APP_CHECK=true`,
/// Firestore는 콘솔 › App Check › Firestore '적용'. 지표에서 정상 요청 비율을 확인한 뒤 출시 직전에 켠다.
Future<void> activateAppCheck() async {
  if (kIsWeb) return;
  final mobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  if (!mobile) return;
  try {
    await FirebaseAppCheck.instance.activate(
      // ignore: deprecated_member_use
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      // ignore: deprecated_member_use
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (e) {
    // App Check가 실패해도 앱은 뜬다. 강제를 켜기 전까지는 요청도 그대로 통과한다
    debugPrint('App Check 시작 실패: $e');
  }
}
