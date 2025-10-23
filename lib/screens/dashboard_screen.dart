// lib/screens/dashboard_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Import AuthService
import 'account/user_management_screen.dart'; // Màn hình Admin
import 'food/food_list_page.dart'; // Danh sách món ăn
import 'home_screen.dart';
import 'profile/profile_screen.dart';

// ignore: library_private_types_in_public_api
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// ignore: library_private_types_in_public_api
class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _userRole = ''; // Trạng thái vai trò: 'admin', 'user', hoặc rỗng khi đang tải
  
  // Khai báo an toàn
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_id'; 
  
  // Khởi tạo các list sau này
  late List<Widget> _pages = [];
  List<BottomNavigationBarItem> _bottomNavItems = []; 

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndPages(); 
  }

  // Khôi phục hàm tải vai trò và định nghĩa pages
  Future<void> _loadUserRoleAndPages() async {
    // Dùng AuthService để lấy vai trò
    String role = await AuthService().getCurrentUserRole();
    
    List<Widget> newPages;
    List<BottomNavigationBarItem> newItems;

    if (role == 'admin' || role == 'editor') {
      newPages = [
        const HomeScreen(),
        const FoodListPage(), // Vị trí 1: Quản lý Món ăn/Danh sách
        ProfileScreen(userId: currentUserId),
      ];
      newItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Quản lý'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
      ];
    } else {
      // User thông thường: Chỉ có Trang chủ và Cá nhân
      newPages = [
        const HomeScreen(),
        ProfileScreen(userId: currentUserId),
      ];
      newItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
      ];
    }

    if (mounted) {
      setState(() {
        _userRole = role;
        _pages = newPages;
        _bottomNavItems = newItems;
      });
    }
  }

  // KHÔI PHỤC HÀM BUILD VÀ LOẠI BỎ LỖI TRÙNG LẶP KHAI BÁO
  @override
  Widget build(BuildContext context) {
    // Hiển thị Loading nếu chưa tải xong vai trò
    if (_userRole.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Đảm bảo currentIndex không vượt quá số lượng page hiện tại
    final displayIndex = _currentIndex.clamp(0, _pages.length - 1);

    return Scaffold(
      // KHÔI PHỤC DRAWER
      drawer: _buildDrawer(context),
      
      body: _pages[displayIndex],
      
      // BottomNavigationBar sử dụng Items đã được định nghĩa động
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: displayIndex,
        selectedItemColor: Colors.orange,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _bottomNavItems, 
      ),
    );
  }

  // KHÔI PHỤC HÀM _buildDrawer
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

          // Mục Trang chủ
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Trang chủ'),
            onTap: () {
              Navigator.pop(context); 
              setState(() => _currentIndex = 0); 
            },
          ),

          // Mục Quản lý/Món ăn (Hiển thị nếu có trong BottomBar)
          if (_bottomNavItems.length > 2)
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Quản lý Món ăn'),
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
              setState(() => _currentIndex = _pages.length - 1); 
            },
          ),

          const Divider(),

          // CHỨC NĂNG ADMIN TRONG DRAWER (Quản lý User)
          if (_userRole == 'admin') // Dùng biến cục bộ _userRole
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
              title: const Text('Quản lý Người dùng (Admin)'),
              onTap: () {
                Navigator.pop(context); 
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                );
              },
            ),
          
          const Divider(),

          // Mục Đăng xuất (Cho mọi User)
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () async {
              await AuthService().logout();
              if (!context.mounted) return; 
              Navigator.of(context).popUntil((route) => route.isFirst); 
            },
          ),
        ],
      ),
    );
  }
}