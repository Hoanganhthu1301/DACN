import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Streams: dùng cho StreamBuilder để nghe trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<User?> get userChanges => _auth.userChanges();
  Stream<User?> get idTokenChanges => _auth.idTokenChanges();

  // User hiện tại (nếu cần)
  User? get currentUser => _auth.currentUser;

  Future<User?> login(String email, String password) async {
    try {
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

  // displayName là tùy chọn; nếu có sẽ set vào FirebaseAuth user
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
