// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart'; // Bắt buộc để dùng Colors và debugPrint
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart'; // Bắt buộc cho getUsers()
//import 'package:flutter/foundation.dart'; // Để dùng debugPrint

// ignore_for_file: library_private_types_in_public_api, depend_on_referenced_packages

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hàm tiện ích hiển thị lỗi
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

  // =================================================================
  // ĐĂNG KÝ VÀ PHÂN QUYỀN BAN ĐẦU
  // =================================================================
  // Cập nhật để nhận displayName và lưu tất cả vào Firestore
  Future<User?> register(
    String email, 
    String password, [
    String? displayName,
  ]) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      final String finalDisplayName = displayName ?? email.split('@')[0];

      if (user != null) {
        // Cập nhật displayName trong Firebase Auth
        if (displayName != null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
        }
        
        // LƯU THÔNG TIN VÀ VAI TRÒ VÀO FIRESTORE
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'role': 'user', // Gán vai trò mặc định
          'isLocked': false, // Mặc định không khóa
          'displayName': finalDisplayName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Fluttertoast.showToast(msg: 'Đăng ký thành công!');
      return user;
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Lỗi đăng ký');
      return null;
    }
  }

  // =================================================================
  // ĐĂNG NHẬP (BAO GỒM KIỂM TRA KHÓA TÀI KHOẢN)
  // =================================================================
  // Tên hàm được giữ là 'login' để khớp với LoginScreen
  Future<User?> login(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;

      if (user != null) {
        // KIỂM TRA TRẠNG THÁI KHÓA TỪ FIRESTORE
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();

        if (doc.exists && doc.data() is Map<String, dynamic>) {
          if ((doc.data() as Map<String, dynamic>)['isLocked'] == true) {
            // Nếu bị khóa, đăng xuất ngay và báo lỗi
            await _auth.signOut(); 
            _showError('Tài khoản của bạn đã bị khóa bởi quản trị viên.');
            return null; // Trả về null báo hiệu đăng nhập thất bại
          }
        }
      }
      
      Fluttertoast.showToast(msg: 'Đăng nhập thành công!');
      return user;
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Lỗi đăng nhập');
      return null;
    } catch (e) {
      _showError('Lỗi không xác định: $e');
      return null;
    }
  }

  // =================================================================
  // CHỨC NĂNG PHÂN QUYỀN
  // =================================================================
  
  // Lấy vai trò (role) của người dùng hiện tại từ Firestore
  Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'guest';
    }
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() is Map<String, dynamic>) {
        return (doc.data() as Map<String, dynamic>)['role'] ?? 'user';
      }
      return 'user';
    } catch (e) {
      debugPrint("Error getting user role: $e");
      return 'user';
    }
  }

  // Lấy tất cả người dùng và vai trò (Dùng cho màn hình Admin)
  Stream<List<AppUser>> getUsers() {
    return _db.collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppUser.fromFirestore(doc.data());
      }).toList();
    });
  }

  // Cập nhật trạng thái Khóa/Mở khóa tài khoản (Dành cho Admin)
  Future<String?> updateUserLockStatus(String uid, bool lockStatus) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isLocked': lockStatus,
      });
      return null;
    } catch (e) {
      debugPrint("Error updating lock status: $e");
      return "Không thể cập nhật trạng thái khóa: $e";
    }
  }

  // Cập nhật vai trò (role) của người dùng khác (Dành cho Admin, chỉ dùng khi cần)
  Future<String?> updateUserRole(String uid, String newRole) async {
    try {
      await _db.collection('users').doc(uid).update({
        'role': newRole,
      });
      return null;
    } catch (e) {
      debugPrint("Error updating user role: $e");
      return "Không thể cập nhật vai trò: $e";
    }
  }

  // =================================================================
  // CÁC HÀM CƠ BẢN KHÁC
  // =================================================================
  
  Future<void> logout() async {
    await _auth.signOut();
    Fluttertoast.showToast(msg: 'Đăng xuất thành công!');
  }

  // Streams:
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // User hiện tại
  User? get currentUser => _auth.currentUser;
}