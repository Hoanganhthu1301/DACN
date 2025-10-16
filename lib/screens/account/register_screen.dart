// lib/screens/register_screen.dart (Sửa tất cả lỗi)
// Thêm // ignore cho private types, thêm key, sửa validator null-safe, sort child last (style trước child), mounted check
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});  // Thêm key và const

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// ignore: library_private_types_in_public_api  // Ignore lint này (chuẩn Flutter)
class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Ký')),  // Thêm const nếu có thể
      body: Padding(
        padding: const EdgeInsets.all(16.0),  // const
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),  // const
                validator: (value) => value?.isEmpty ?? true ? 'Nhập email' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),  // const
                obscureText: true,
                validator: (value) => (value?.length ?? 0) < 6 ? 'Mật khẩu ít nhất 6 ký tự' : null,  // Sửa null-safe cho length
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()  // const
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),  // const, di chuyển style trước child
                      child: const Text('Đăng Ký'),  // child last, const
                    ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),  // const Login
                child: const Text('Đã có tài khoản? Đăng nhập'),  // child last, const
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
      setState(() => _isLoading = false);
      if (user != null && mounted) {  // Thêm mounted check
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