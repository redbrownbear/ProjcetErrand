import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/backend/backend.dart';

/// 로그인·가입. Firebase가 초기화되지 않은 환경(데스크톱·오프라인)에서도
/// **인스턴스를 만드는 것만으로 예외가 나면 안 된다.** 그래서 플러그인 객체를
/// 필드로 붙잡지 않고, 쓸 때마다 [Backend.ready]를 보고 가져온다.
class AuthService {
  FirebaseAuth? get _auth => Backend.ready ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _db => Backend.ready ? FirebaseFirestore.instance : null;

  /// 서버가 없으면 아무것도 흐르지 않는 스트림. 화면은 '로그아웃 상태'로 그린다.
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? Stream<User?>.value(null);

  User? get currentUser => _auth?.currentUser;

  /// 로그인·가입을 시도할 수 있는 상태인지. false면 화면에서 안내만 띄운다.
  bool get available => Backend.ready;

  /// 로그인 상태를 어디까지 기억할지 정한다. `main()`에서 한 번 부른다.
  ///
  /// **Android·iOS**는 네이티브 SDK가 알아서 기기에 토큰을 보관한다. 한 번 로그인하면
  /// 앱을 껐다 켜도 로그인 상태로 시작하고, `setPersistence`는 지원조차 하지 않는다.
  /// (부르면 UnimplementedError가 난다 — 그래서 웹에서만 부른다)
  ///
  /// **웹**은 명시해 준다. LOCAL이면 브라우저 저장소에 남아서 탭을 닫아도 유지된다.
  /// 다만 `flutter run -d chrome`은 매번 **새 임시 프로필**로 브라우저를 띄우기 때문에,
  /// 저장한 곳이 통째로 새것이라 디버그 중에는 계속 로그아웃 상태로 시작한다.
  /// 이건 설정으로 못 고친다 — 웹에서 유지되는 걸 확인하려면 빌드한 결과물을
  /// 평소 쓰는 브라우저에서 열어야 한다.
  Future<void> configurePersistence() async {
    if (!kIsWeb || !Backend.ready) return;
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } catch (e) {
      debugPrint('로그인 유지 설정 실패: $e');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final auth = _auth;
    if (auth == null) throw const ServerUnavailable();
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password, required String nickname}) async {
    final auth = _auth;
    if (auth == null) throw const ServerUnavailable();
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(nickname);
    try {
      // 프로필 문서 저장은 부가 기능 — Firestore가 아직 준비 안 됐거나 느려도
      // 계정 생성(로그인) 자체는 막지 않도록 타임아웃을 두고 실패를 삼킴.
      // (실패해도 다음 로그인 때 UserRepository.ensureProfile이 다시 만든다)
      await _db?.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'nickname': nickname,
        'points': 0,
        'verified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    } catch (_) {
      // ignore
    }
  }

  /// 계정 쪽 표시 이름을 바꾼다. 프로필 문서(`users/{uid}.nickname`)는
  /// [UserRepository.saveProfileFields]가 따로 맡는다 — 둘 다 맞춰야
  /// 다음 로그인 때 예전 이름으로 되돌아가지 않는다.
  Future<void> updateDisplayName(String nickname) async {
    final user = _auth?.currentUser;
    if (user == null) return;
    await user.updateDisplayName(nickname);
    await user.reload();
  }

  Future<void> signOut() async => _auth?.signOut();

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
      case 'operation-not-allowed':
        return 'Firebase 콘솔에서 이메일/비밀번호 로그인을 켜주세요.';
      default:
        return '문제가 발생했어요. 잠시 후 다시 시도해주세요.';
    }
  }
}

/// 서버에 아예 연결되지 않은 상태에서 로그인을 시도했을 때.
class ServerUnavailable implements Exception {
  const ServerUnavailable();
  @override
  String toString() => '서버에 연결되지 않아 로그인할 수 없어요.';
}
