// lib/services/auth_service.dart (Sửa lỗi undefined Colors: Thêm import material)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';  // Thêm dòng này để dùng Colors

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Đăng ký user mới
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      Fluttertoast.showToast(msg: 'Đăng ký thành công!');
      return result.user;
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Lỗi đăng ký');
      return null;
    }
  }

  // Đăng nhập
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Fluttertoast.showToast(msg: 'Đăng nhập thành công!');
      return result.user;
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Lỗi đăng nhập');
      return null;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
    Fluttertoast.showToast(msg: 'Đăng xuất thành công!');
  }

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream theo dõi auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}