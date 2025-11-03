import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import 'register_screen.dart';
import '../dashboard_screen.dart';

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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final User? user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);

      if (user != null) {
        // Đảm bảo users/{uid} tồn tại để dùng cho Profile
        await ProfileService().ensureUserDoc(user);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thất bại. Kiểm tra email/mật khẩu.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailResetController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final formKeyReset = GlobalKey<FormState>();
    bool sending = false;

    // showDialog trả về khi dialog bị đóng
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Đặt lại mật khẩu'),
              content: Form(
                key: formKeyReset,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Nhập email liên kết với tài khoản của bạn. Chúng tôi sẽ gửi hướng dẫn để đặt lại mật khẩu.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailResetController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'email@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nhập email';
                        final email = v.trim();
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(email)) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (!(formKeyReset.currentState?.validate() ??
                              false)) {
                            return;
                          }

                          setState(() => sending = true);
                          final email = emailResetController.text.trim();

                          // Gọi async gửi mail (trong AuthService)
                          final result = await _authService.sendPasswordReset(
                            email,
                          );

                          // Sau async: cập nhật UI dialog (spinner) và đóng dialog
                          if (mounted) {
                            setState(() => sending = false);
                            Navigator.of(ctx).pop(); // đóng dialog
                          } else {
                            // nếu state đã unmounted, chỉ đóng dialog nếu possible
                            try {
                              Navigator.of(ctx).pop();
                            } catch (_) {}
                          }

                          // SAU KHI ĐÓ: KHÔNG DÙNG 'ctx' nữa, dùng 'mounted' để an toàn
                          if (!mounted) {
                            emailResetController.dispose();
                            return;
                          }

                          if (result == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã gửi email hướng dẫn đặt lại mật khẩu tới $email',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $result')),
                            );
                          }

                          emailResetController.dispose();
                        },
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
    );

    // dialog đã đóng — dispose controller an toàn (không cần kiểm tra mounted)
    try {
      emailResetController.dispose();
    } catch (_) {}
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
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Nhập email';
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Nhập mật khẩu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text('Quên mật khẩu?'),
                ),
              ),

              const SizedBox(height: 12),
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
