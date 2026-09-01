import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../home_shell.dart';
import 'login_screen.dart';

/// 로그인 상태에 따라 로그인 화면 또는 홈 화면을 보여줌.
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
        if (snapshot.hasData) return const HomeShell();
        return const LoginScreen();
      },
    );
  }
}
