import 'package:firebase_auth/firebase_auth.dart';
import 'fcm_token_service.dart'; // THÊM import

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<User?> get userChanges => _auth.userChanges();
  Stream<User?> get idTokenChanges => _auth.idTokenChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> login(String email, String password) async {
    try {
      // Nếu đang đăng nhập 1 user khác → gỡ và xoá token trước khi chuyển
      if (_auth.currentUser != null) {
        try {
          await FcmTokenService().unlinkAndDeleteToken();
        } catch (_) {}
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<User?> register(
    String email,
    String password, [
    String? displayName,
  ]) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user != null && (displayName != null && displayName.isNotEmpty)) {
        await user.updateDisplayName(displayName);
      }
      return _auth.currentUser;
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
