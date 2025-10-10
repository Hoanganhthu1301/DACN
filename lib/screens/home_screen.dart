import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();  // Removed underscore from _authService

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gợi Ý Món Ăn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Chào mừng! Phần gợi ý món ăn sẽ được thêm sau.'),
      ),
    );
  }
}