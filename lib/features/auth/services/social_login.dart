import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/server_api.dart';
import '../../../core/config/api_keys.dart';
import 'auth_service.dart';

/// 카카오 · 네이버 로그인.
///
/// 각 회사 SDK로 로그인해 액세스 토큰을 받고 → 서버 함수 `socialSignIn`이 그 회사 API로 토큰을 확인해
/// Firebase 커스텀 토큰을 돌려주면 → `signInWithCustomToken`. 그 뒤로는 이메일 로그인과 같은 계정이다
/// (uid `kakao:…` · `naver:…`, functions/src/auth/core.ts). 약관 동의는 로그인 뒤 동의 화면이 받는다.
///
/// 키는 secrets.json(`--dart-define-from-file`)에 넣는다. 안드로이드 매니페스트도 같은 값을 쓴다(android/app/build.gradle.kts).
/// 키가 없거나 웹이면 버튼을 그리지 않는다.
class SocialLogin {
  SocialLogin._();

  static bool get _mobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static bool get kakaoReady => _mobile && ApiKeys.kakaoNative.isNotEmpty;
  static bool get naverReady => _mobile && ApiKeys.naverLoginId.isNotEmpty;
  static bool get anyReady => kakaoReady || naverReady;

  /// `main()`에서 runApp 전에 한 번. 실패해도 앱은 뜬다(카카오 버튼만 실패 안내).
  static Future<void> init() async {
    if (!kakaoReady) return;
    try {
      await KakaoSdk.init(nativeAppKey: ApiKeys.kakaoNative);
    } catch (e) {
      debugPrint('카카오 SDK 초기화 실패: $e');
    }
  }

  /// 카카오톡이 깔려 있으면 카카오톡으로, 아니면(또는 카카오톡 로그인이 안 되면) 카카오계정 웹 로그인으로.
  /// 사용자가 닫으면 [SocialCancelled].
  static Future<void> signInWithKakao() async {
    _requireServer();
    OAuthToken token;
    try {
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          if (_isCancel(e)) rethrow;
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } catch (e) {
      if (_isCancel(e)) throw const SocialCancelled();
      debugPrint('카카오 로그인 실패: $e');
      throw const ServerException('카카오 로그인에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
    await _finish('kakao', token.accessToken);
  }

  static Future<void> signInWithNaver() async {
    _requireServer();
    String accessToken;
    try {
      final res = await FlutterNaverLogin.logIn();
      if (res.status == NaverLoginStatus.loggedOut) throw const SocialCancelled();
      if (res.status != NaverLoginStatus.loggedIn) {
        debugPrint('네이버 로그인 실패: ${res.errorMessage}');
        throw const ServerException('네이버 로그인에 실패했어요. 잠시 후 다시 시도해 주세요.');
      }
      accessToken = res.accessToken?.accessToken ?? '';
      if (accessToken.isEmpty) accessToken = (await FlutterNaverLogin.getCurrentAccessToken()).accessToken;
    } on SocialCancelled {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('네이버 로그인 실패: $e');
      throw const ServerException('네이버 로그인에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
    await _finish('naver', accessToken);
  }

  /// 로그아웃할 때 SDK 쪽 로그인도 끊는다 — 안 끊으면 다음에 누를 때 다른 계정을 고를 수 없다
  static Future<void> signOutProvider(String? uid) async {
    try {
      if (uid?.startsWith('kakao:') == true && kakaoReady) await UserApi.instance.logout();
      if (uid?.startsWith('naver:') == true && naverReady) await FlutterNaverLogin.logOut();
    } catch (e) {
      debugPrint('소셜 로그아웃 실패: $e');
    }
  }

  static void _requireServer() {
    if (!Backend.ready) throw const ServerUnavailable();
  }

  static Future<void> _finish(String provider, String accessToken) async {
    if (accessToken.isEmpty) throw const ServerException('로그인 정보를 받지 못했어요. 다시 시도해 주세요.');
    final out = await ServerApi.call('socialSignIn', {'provider': provider, 'accessToken': accessToken});
    final token = out['token'];
    if (token is! String || token.isEmpty) throw const ServerException('로그인하지 못했어요. 잠시 후 다시 시도해 주세요.');
    await FirebaseAuth.instance.signInWithCustomToken(token);
  }

  /// 사용자가 로그인 창을 닫은 것인지(카카오 SDK는 PlatformException 'CANCELED' 또는 cancelled 원인으로 알린다)
  @visibleForTesting
  static bool isCancel(Object e) => _isCancel(e);

  static bool _isCancel(Object e) =>
      (e is PlatformException && e.code == 'CANCELED') ||
      (e is KakaoClientException && e.reason == ClientErrorCause.cancelled) ||
      e is SocialCancelled;
}

/// 사용자가 로그인 창을 닫음 — 화면은 아무 안내도 띄우지 않는다
class SocialCancelled implements Exception {
  const SocialCancelled();
}
