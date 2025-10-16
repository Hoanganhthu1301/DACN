// lib/services/auth_service.dart (Sửa lỗi undefined Colors: Thêm import material)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';  // Thêm dòng này để dùng Colors
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
//import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Đăng ký user mới
 Future<User?> register(String email, String password) async {
  try {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;

    if (user != null) {
      // BƯỚC MỚI: Thêm thông tin người dùng vào Firestore
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': 'user', // Gán vai trò mặc định
        'isLocked': false,
        'displayName': email.split('@')[0],
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
// Lấy vai trò (role) của người dùng hiện tại từ Firestore
Future<String> getCurrentUserRole() async {
  final user = _auth.currentUser;
  
  if (user == null) {
    return 'guest'; // Chưa đăng nhập
  }

  try {
    DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
    
    if (doc.exists && doc.data() is Map<String, dynamic>) {
      // Trả về vai trò được lưu trong Firestore
      return (doc.data() as Map<String, dynamic>)['role'] ?? 'user';
    }
    
    return 'user'; // Nếu document không tồn tại (lỗi) hoặc không có trường 'role'
  } catch (e) {
    debugPrint("Error getting user role: $e");
    return 'user'; // Xảy ra lỗi, gán vai trò an toàn
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


  // Lấy tất cả người dùng và vai trò (Dùng cho màn hình Admin)
  Stream<List<AppUser>> getUsers() {
    // 1. Lấy Stream các snapshot từ collection 'users'
    return _db.collection('users')
        .snapshots()
        .map((snapshot) {
      // 2. Chuyển đổi mỗi document thành đối tượng AppUser (dùng AppUser.fromFirestore)
      return snapshot.docs.map((doc) {
        return AppUser.fromFirestore(doc.data());
      }).toList(); // 3. Trả về danh sách List<AppUser>
    });
  }

  // Cập nhật vai trò (role) của người dùng khác (Dành cho Admin)
  Future<String?> updateUserRole(String uid, String newRole) async {
    try {
      // Dùng hàm update để chỉ thay đổi trường 'role'
      await _db.collection('users').doc(uid).update({
        'role': newRole,
      });
      return null; // Trả về null nếu thành công (không có lỗi)
    } catch (e) {
      debugPrint("Error updating user role: $e");
      return "Không thể cập nhật vai trò: $e"; // Trả về thông báo lỗi
    }
  }
  Future<String?> updateUserLockStatus(String uid, bool lockStatus) async {
  try {
    // Gọi Firestore để cập nhật trường 'isLocked'
    await _db.collection('users').doc(uid).update({
      'isLocked': lockStatus,
    });
    return null; // Thành công
  } catch (e) {
    debugPrint("Error updating lock status: $e");
    return "Không thể cập nhật trạng thái khóa: $e"; // Trả về thông báo lỗi
  }
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