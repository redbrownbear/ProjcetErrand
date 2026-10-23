import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// 로그인·회원가입 입력 칸 모양
InputDecoration authFieldDecoration(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: AppColors.card,
  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.line),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.line),
  ),
);

/// 로그인·회원가입의 노란 큰 버튼. 처리 중에는 눌리지 않고 돌아가는 표시가 뜬다.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const AuthSubmitButton({super.key, required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          disabledBackgroundColor: AppColors.yellowSoft,
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}

/// 입력 아래 빨간 안내
class AuthError extends StatelessWidget {
  final String message;
  const AuthError(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(message, style: const TextStyle(color: AppColors.red, fontSize: 12.5)),
  );
}

/// 카카오 · 네이버 로그인 버튼. 색은 각 회사 버튼 안내(카카오 #FEE500 · 네이버 #03C75A)를 따른다
class SocialLoginButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Widget mark;
  final VoidCallback? onPressed;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.mark,
    required this.onPressed,
  });

  const SocialLoginButton.kakao({super.key, required this.onPressed})
    : label = '카카오로 시작하기',
      background = const Color(0xFFFEE500),
      foreground = const Color(0xD9000000),
      mark = const Icon(Icons.chat_bubble, size: 18, color: Color(0xFF000000));

  const SocialLoginButton.naver({super.key, required this.onPressed})
    : label = '네이버로 시작하기',
      background = const Color(0xFF03C75A),
      foreground = const Color(0xFFFFFFFF),
      mark = const Text(
        'N',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFFFFFFF), height: 1),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.5),
          disabledForegroundColor: foreground.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: mark)),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

/// 가운데 글자가 있는 가로줄
class AuthDivider extends StatelessWidget {
  final String label;
  const AuthDivider(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22),
    child: Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ],
    ),
  );
}
