// lib/screens/account/register_screen.dart

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../home_screen.dart'; // Đã sửa đường dẫn thành '../home_screen.dart'

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key}); // Thêm key và const

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// ignore: library_private_types_in_public_api 
class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Ký')), // const
      body: Padding(
        padding: const EdgeInsets.all(16.0), // const
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'), // const
                validator: (value) => value?.isEmpty ?? true ? 'Nhập email' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'), // const
                obscureText: true,
                validator: (value) => (value?.length ?? 0) < 6 ? 'Mật khẩu ít nhất 6 ký tự' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator() // const
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), // const, style trước child
                      child: const Text('Đăng Ký'), // const
                    ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())), // const Login
                child: const Text('Đã có tài khoản? Đăng nhập'), // const
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      User? user = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // Khắc phục lỗi: Kiểm tra mounted trước khi sử dụng context
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      if (user != null) { 
        // Đăng ký thành công, chuyển hướng đến HomeScreen
        // Dùng pushReplacement để người dùng không thể back lại màn hình đăng ký
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
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