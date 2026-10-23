import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeomsa/features/auth/screens/login_screen.dart';
import 'package:gyeomsa/features/auth/services/social_login.dart';
import 'package:gyeomsa/features/auth/widgets/auth_widgets.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

void main() {
  test('키가 없으면(테스트 · 웹) 카카오 · 네이버 로그인을 감춘다', () {
    expect(SocialLogin.kakaoReady, isFalse);
    expect(SocialLogin.naverReady, isFalse);
  });

  test('로그인 창을 닫은 것만 취소로 본다', () {
    expect(SocialLogin.isCancel(PlatformException(code: 'CANCELED')), isTrue);
    expect(SocialLogin.isCancel(KakaoClientException(ClientErrorCause.cancelled, 'User Cancelled')), isTrue);
    expect(SocialLogin.isCancel(const SocialCancelled()), isTrue);
    expect(SocialLogin.isCancel(PlatformException(code: 'NotSupportError')), isFalse);
    expect(SocialLogin.isCancel(Exception('x')), isFalse);
  });

  testWidgets('키가 없으면 로그인 화면은 이메일(테스트 계정) 로그인 그대로', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.byType(SocialLoginButton), findsNothing);
    expect(find.text('테스트 계정(이메일)'), findsNothing);
    expect(find.text('로그인'), findsOneWidget);
  });

  testWidgets('카카오 · 네이버 버튼', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SocialLoginButton.kakao(onPressed: () => tapped++),
              SocialLoginButton.naver(onPressed: null),
              const AuthDivider('테스트 계정(이메일)'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('네이버로 시작하기'), findsOneWidget);
    await tester.tap(find.text('카카오로 시작하기'));
    await tester.tap(find.text('네이버로 시작하기'));
    expect(tapped, 1);
  });
}
