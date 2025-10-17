// lib/screens/account/register_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart'; // Giữ lại import này
import '../dashboard_screen.dart'; 
import 'login_screen.dart';
// import '../home_screen.dart'; // Không cần thiết nếu đã dùng DashboardScreen

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// Giữ lại ignore lint cho private types (chuẩn Flutter)
// ignore: library_private_types_in_public_api 
class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  
  // Giữ lại trường displayName từ nhánh thu
  final _displayNameController = TextEditingController(); 
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Sử dụng logic validate an toàn hơn từ nhánh thu
    if (!(_formKey.currentState?.validate() ?? false)) return; 
    
    // Tắt bàn phím
    FocusScope.of(context).unfocus(); 

    setState(() => _isLoading = true);

    try {
      // 1. Đăng ký user mới (Cần đảm bảo AuthService.register được cập nhật để nhận displayName)
      final User? user = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _displayNameController.text.trim(), // Truyền thêm displayName
      );

      // 2. Kiểm tra mounted ngay sau await (QUAN TRỌNG)
      if (!mounted) return;
      
      setState(() => _isLoading = false);

      if (user != null) {
        // 3. Tạo hoặc cập nhật document Firestore cho user vừa đăng ký
        // Dùng ProfileService().ensureUserDoc(user) nếu logic profile phức tạp
        // HOẶC dùng logic đơn giản trong AuthService.register() nếu chỉ lưu role
        await ProfileService().ensureUserDoc(user); // Giữ lại logic này từ nhánh thu
        
        // 4. Kiểm tra mounted lần nữa
        if (!mounted) return;
        
        // 5. Chuyển hướng đến Dashboard và xóa lịch sử navigation
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        // Xử lý lỗi (Thất bại do email tồn tại, mật khẩu yếu, v.v.)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thất bại. Email có thể đã tồn tại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi hệ thống: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Ký')),
      body: Center(
        child: SingleChildScrollView( // Giữ lại SingleChildScrollView từ nhánh thu
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trường Tên hiển thị (displayName)
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Vui lòng nhập tên của bạn'
                      : null,
                ),
                const SizedBox(height: 16),
                // Trường Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Vui lòng nhập email' : null,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Trường Mật khẩu
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mật khẩu cần ít nhất 6 ký tự'
                      : null,
                ),
                const SizedBox(height: 24),
                // Nút Đăng ký
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Đăng Ký'),
                      ),
                // Nút Đăng nhập
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Đã có tài khoản? Đăng nhập ngay'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}