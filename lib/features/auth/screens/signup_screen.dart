import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordCheckCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordCheckCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nickname = _nicknameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (nickname.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = '모든 항목을 입력해주세요.');
      return;
    }
    if (password != _passwordCheckCtrl.text) {
      setState(() => _error = '비밀번호가 일치하지 않아요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signUp(email: email, password: password, nickname: nickname);
      // AuthGate가 홈으로 전환해줄 수 있도록, 로그인 화면 위에 쌓인 이 화면을 닫아줌.
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = AuthService.messageFor(e));
    } on ServerUnavailable catch (e) {
      if (mounted) setState(() => _error = '$e');
    } catch (_) {
      if (mounted) setState(() => _error = '문제가 발생했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 14),
    child: Text(
      t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: AppColors.page,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text(
          '회원가입',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('닉네임'),
              TextField(controller: _nicknameCtrl, maxLength: 12, decoration: authFieldDecoration('겸사겸사에서 쓸 닉네임')),
              _label('이메일'),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: authFieldDecoration('you@example.com'),
              ),
              _label('비밀번호'),
              TextField(controller: _passwordCtrl, obscureText: true, decoration: authFieldDecoration('6자 이상')),
              _label('비밀번호 확인'),
              TextField(
                controller: _passwordCheckCtrl,
                obscureText: true,
                onSubmitted: (_) => _submit(),
                decoration: authFieldDecoration('비밀번호를 한번 더 입력해주세요'),
              ),
              if (_error != null) AuthError(_error!),
              const SizedBox(height: 22),
              AuthSubmitButton(label: '가입하고 시작하기', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
