import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password, required String nickname}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(nickname);
    try {
      // 프로필 문서 저장은 부가 기능 — Firestore가 아직 준비 안 됐거나 느려도
      // 계정 생성(로그인) 자체는 막지 않도록 타임아웃을 두고 실패를 삼킴.
      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'nickname': nickname,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    } catch (_) {
      // ignore: 다음 로그인 때 다시 시도하거나, 이후 단계에서 채워도 됨.
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Firebase가 내려주는 영어 에러 코드를 화면에 보여줄 한국어 메시지로 변환.
  static String messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return '이메일 형식이 올바르지 않아요.';
      case 'user-disabled':
        return '사용이 제한된 계정이에요.';
      case 'user-not-found':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 일치하지 않아요.';
      case 'wrong-password':
        return '이메일 또는 비밀번호가 일치하지 않아요.';
      case 'email-already-in-use':
        return '이미 가입된 이메일이에요.';
      case 'weak-password':
        return '비밀번호는 6자 이상으로 입력해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      case 'too-many-requests':
        return '잠시 후 다시 시도해주세요.';
      default:
        return '문제가 발생했어요. 잠시 후 다시 시도해주세요.';
    }
  }
}
