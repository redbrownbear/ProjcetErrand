import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = '이메일과 비밀번호를 입력해주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signIn(email: email, password: password);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.messageFor(e));
    } catch (_) {
      setState(() => _error = '문제가 발생했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 회원가입은 성공하면 그대로 로그인된 상태가 되므로,
  /// 가입 후 로그인 화면을 다시 보여주지 않고 같이 닫는다.
  Future<void> _openSignup() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
    if (!mounted || _auth.currentUser == null) return;
    Navigator.of(context).pop();
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true, fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Stack(children: [
          Positioned(
            left: 8, top: 4,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: AppColors.ink),
            ),
          ),
          Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icon/app_icon.png', width: 64, height: 64),
                const SizedBox(height: 16),
                const Text('겸사겸사', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const Padding(padding: EdgeInsets.only(top: 4), child: Text('동네에서 겸사겸사 벌어요', style: TextStyle(fontSize: 13, color: AppColors.sub))),
                const SizedBox(height: 32),
                TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: _dec('이메일')),
                const SizedBox(height: 10),
                TextField(controller: _passwordCtrl, obscureText: true, onSubmitted: (_) => _submit(), decoration: _dec('비밀번호')),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12.5)),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      disabledBackgroundColor: AppColors.yellowSoft,
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                        : const Text('로그인', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading ? null : _openSignup,
                  child: const Text.rich(TextSpan(children: [
                    TextSpan(text: '계정이 없으신가요? ', style: TextStyle(color: AppColors.sub, fontSize: 13)),
                    TextSpan(text: '회원가입', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 13)),
                  ])),
                ),
              ],
            ),
          ),
          ),
        ]),
      ),
    );
  }
}
