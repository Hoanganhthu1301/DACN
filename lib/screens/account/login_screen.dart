// lib/screens/account/login_screen.dart

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart'; // Giữ lại import này
import 'register_screen.dart';
import '../dashboard_screen.dart';
import 'user_management_screen.dart'; // Import màn hình Admin

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); 

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Sử dụng logic validate chung
    if (!(_formKey.currentState?.validate() ?? false)) return; 

    setState(() => _isLoading = true);
    
    // Khối try-catch để bắt các ngoại lệ không phải Auth (ví dụ: lỗi mạng, lỗi Firestore)
    try {
      // 1. Thực hiện Đăng nhập (Bao gồm kiểm tra isLocked trong AuthService)
      User? user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 2. Kiểm tra mounted ngay sau await đầu tiên (QUAN TRỌNG)
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (user != null) {
        // ==> LOGIC TÍCH HỢP TỪ NHÁNH THU: Đảm bảo Document User tồn tại
        // Điều này rất quan trọng nếu bạn có logic đăng nhập từ bên ngoài Auth (ví dụ: Google/Apple)
        // Dù bạn đã làm trong register, nhưng đây là lưới an toàn.
        await ProfileService().ensureUserDoc(user); 

        // 3. Kiểm tra mounted sau ProfileService (QUAN TRỌNG)
        if (!mounted) return;
        
        // 4. Đăng nhập thành công, lấy vai trò
        final role = await _authService.getCurrentUserRole();

        // 5. Kiểm tra mounted lần hai sau await vai trò (QUAN TRỌNG)
        if (!mounted) return;

        // 6. Chuyển hướng dựa trên vai trò
        if (role == 'admin') {
          // Admin đi thẳng vào màn hình quản lý người dùng
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserManagementScreen()),
          );
        } else {
          // User/Editor đi vào Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        // Nếu user == null (đăng nhập thất bại hoặc bị khóa)
        // Hiển thị SnackBar thông báo chung
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thất bại. Vui lòng thử lại.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hệ thống: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nhập email' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Đăng Nhập'),
                    ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}