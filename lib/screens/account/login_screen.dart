// lib/screens/account/login_screen.dart

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../dashboard_screen.dart';
import 'user_management_screen.dart'; // Import màn hình Admin

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); 

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// ignore: library_private_types_in_public_api
class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
                validator: (value) => value?.isEmpty ?? true ? 'Nhập email' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'Nhập mật khẩu' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Đăng Nhập'),
                    ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // 1. Thực hiện Đăng nhập (Bao gồm kiểm tra isLocked trong AuthService)
      User? user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 2. Kiểm tra mounted ngay sau await đầu tiên (QUAN TRỌNG)
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (user != null) {
        // 3. Đăng nhập thành công, lấy vai trò
        final role = await _authService.getCurrentUserRole();

        // 4. Kiểm tra mounted lần hai sau await vai trò (QUAN TRỌNG)
        if (!mounted) return;

        // 5. Chuyển hướng dựa trên vai trò
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
        // Nếu user == null (đăng nhập thất bại do sai thông tin hoặc bị khóa)
        // Thông báo lỗi đã được hiển thị bằng FlutterToast từ AuthService.
        // Chỉ hiển thị SnackBar phụ trợ nếu cần.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thất bại. Vui lòng thử lại.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}