// lib/screens/account/user_management_screen.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart'; // Đã được tạo ở bước trước

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        backgroundColor: Colors.deepPurple,
      ),
      // Sử dụng StreamBuilder để lắng nghe danh sách người dùng theo thời gian thực
      body: StreamBuilder<List<AppUser>>(
        stream: AuthService().getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có người dùng nào.'));
          }

          final users = snapshot.data!;
          // Lấy UID của Admin hiện tại
          final currentUserUid = AuthService().currentUser?.uid;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isCurrentUser = user.uid == currentUserUid;
              final isLocked = user.isLocked;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    // Màu sắc dựa trên trạng thái khóa (ưu tiên) hoặc vai trò
                    backgroundColor: isLocked ? Colors.grey.shade500 : _getRoleColor(user.role),
                    child: Text(user.role[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  
                  // Hiển thị vai trò và trạng thái khóa
                  subtitle: Text(
                    '${user.email}\nVai trò: ${user.role} | Trạng thái: ${isLocked ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG'}',
                    style: TextStyle(color: isLocked ? Colors.red.shade700 : Colors.green.shade700)
                  ),
                  isThreeLine: true,
                  
                  // Chỉ hiển thị nút thao tác nếu không phải là Admin hiện tại
                  trailing: isCurrentUser
                      ? const Chip(label: Text('Bạn (Admin)', style: TextStyle(fontWeight: FontWeight.bold)))
                      : _LockToggleButton(user: user), 
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  // Hàm trợ giúp màu sắc cho CircleAvatar
  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red.shade700;
      case 'editor':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
    }
  }
}

// ---
// Widget Mới: Nút Khóa/Mở Khóa Tài khoản (_LockToggleButton)
// ---

class _LockToggleButton extends StatelessWidget {
  final AppUser user;
  const _LockToggleButton({required this.user});

  @override
  Widget build(BuildContext context) {
    final bool isLocked = user.isLocked;

    return ElevatedButton.icon(
      onPressed: () async {
        // Hỏi xác nhận trước khi khóa/mở khóa
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isLocked ? "Mở khóa ${user.displayName}?" : "Khóa tài khoản ${user.displayName}?"),
            content: Text(isLocked ? "Tài khoản sẽ được kích hoạt lại và có thể đăng nhập." : "Người dùng sẽ không thể đăng nhập."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true), 
                child: Text(isLocked ? "Mở Khóa" : "Khóa", style: TextStyle(color: isLocked ? Colors.green : Colors.red)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          // Thực hiện cập nhật trạng thái khóa (đảo ngược trạng thái hiện tại)
          String? errorMessage = await AuthService().updateUserLockStatus(user.uid, !isLocked);
          
          if (!context.mounted) return; // Kiểm tra mounted
          
          // Hiển thị kết quả
          if (errorMessage == null) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã ${isLocked ? "MỞ KHÓA" : "KHÓA"} ${user.displayName} thành công!')),
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $errorMessage')),
            );
          }
        }
      },
      icon: Icon(isLocked ? Icons.lock_open : Icons.lock, size: 18),
      label: Text(isLocked ? "Mở Khóa" : "Khóa"),
      style: ElevatedButton.styleFrom(
        backgroundColor: isLocked ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }
}