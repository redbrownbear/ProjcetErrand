import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/home_shell.dart';
import '../../../core/theme/colors.dart';
import '../services/auth_service.dart';

/// Firebase 인증 상태 확인이 끝날 때까지만 스플래시를 보여주고 홈으로 진입시킴.
/// 콘텐츠 열람은 로그인 여부와 무관하게 항상 허용 — 로그인은 실제 참여 행동 시점에
/// HomeShell이 오버레이로 띄움 (HomeShell.requireLogin 참고).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.page,
            body: Center(child: CircularProgressIndicator(color: AppColors.ink)),
          );
        }
        return const HomeShell();
      },
    );
  }
}
