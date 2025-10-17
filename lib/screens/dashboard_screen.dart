// lib/screens/dashboard_screen.dart

import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter/material.dart';

// Imports từ cả hai nhánh (Đã hợp nhất)
import 'food/food_list_page.dart';
import 'home_screen.dart';
import 'account/user_management_screen.dart'; // Màn hình Admin (HEAD)
import '../services/auth_service.dart'; // Import AuthService (HEAD)
import 'profile/profile_screen.dart'; // Màn hình Profile (THU)

// ignore: library_private_types_in_public_api
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// ignore: library_private_types_in_public_api
class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Lấy UID của người dùng hiện tại (QUAN TRỌNG: Phải đảm bảo user đã đăng nhập)
  // Nếu FirebaseAuth.instance.currentUser là null, ứng dụng sẽ crash.
  // Vì DashboardScreen chỉ được load sau khi login, nên ta có thể dùng !.
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_id'; 

  late final List<Widget> _pages; // Khai báo _pages

  @override
  void initState() {
    super.initState();
    // Khởi tạo _pages với 3 màn hình
    _pages = [
      const HomeScreen(), 
      const FoodListPage(), 
      ProfileScreen(userId: currentUserId), // Trang cá nhân
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thêm Drawer để chứa các chức năng phụ và chức năng Admin
      drawer: _buildDrawer(context),
      
      body: _pages[_currentIndex],
      
      // BottomNavigationBar với 3 mục
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Món ăn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'), // Mục Profile
        ],
      ),
    );
  }

  // Hàm xây dựng Drawer (Menu bên)
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const UserAccountsDrawerHeader(
            accountName: Text('Tài khoản người dùng'),
            accountEmail: Text('Menu quản lý'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.deepOrange),
            ),
            decoration: BoxDecoration(
              color: Colors.deepOrange,
            ),
          ),

          // Mục chính: Trang chủ
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Trang chủ'),
            onTap: () {
              Navigator.pop(context); 
              setState(() => _currentIndex = 0); 
            },
          ),
          
          // Mục chính: Món ăn
          ListTile(
            leading: const Icon(Icons.fastfood),
            title: const Text('Danh sách Món ăn'),
            onTap: () {
              Navigator.pop(context); 
              setState(() => _currentIndex = 1); 
            },
          ),

          // Mục Profile (Cá nhân)
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Trang cá nhân'),
            onTap: () {
              Navigator.pop(context); 
              setState(() => _currentIndex = 2); 
            },
          ),

          const Divider(),

          // ==> KIỂM TRA PHÂN QUYỀN VÀ HIỂN THỊ CHỨC NĂNG ADMIN
          FutureBuilder<String>(
            future: AuthService().getCurrentUserRole(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }
              
              final role = snapshot.data;
              
              if (role == 'admin') {
                return ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                  title: const Text('Quản lý Người dùng (Admin)'),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const Divider(),

          // Mục Đăng xuất (Cho mọi User)
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () async {
              await AuthService().logout();
              // Chuyển hướng về màn hình Login/Wrapper
              Navigator.of(context).popUntil((route) => route.isFirst); 
            },
          ),
        ],
      ),
    );
  }
}