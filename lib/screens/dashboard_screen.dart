import 'package:flutter/material.dart';
import 'food/food_list_page.dart';
import 'home_screen.dart';
import 'account/user_management_screen.dart'; // Màn hình Admin
import '../services/auth_service.dart'; // Import AuthService để kiểm tra vai trò

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),    // Trang chủ
    FoodListPage(),  // Danh sách món ăn
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thêm Drawer để chứa các chức năng phụ và chức năng Admin
      drawer: _buildDrawer(context),
      
      body: _pages[_currentIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Món ăn',
          ),
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
              Navigator.pop(context); // Đóng Drawer
              setState(() => _currentIndex = 0); // Chuyển đến trang chủ
            },
          ),
          
          // Mục chính: Món ăn
          ListTile(
            leading: const Icon(Icons.fastfood),
            title: const Text('Danh sách Món ăn'),
            onTap: () {
              Navigator.pop(context); // Đóng Drawer
              setState(() => _currentIndex = 1); // Chuyển đến trang món ăn
            },
          ),

          const Divider(),

          // ==> KIỂM TRA PHÂN QUYỀN VÀ HIỂN THỊ CHỨC NĂNG ADMIN
          FutureBuilder<String>(
            future: AuthService().getCurrentUserRole(),
            builder: (context, snapshot) {
              // Nếu đang tải hoặc có lỗi, không hiển thị gì
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }
              
              final role = snapshot.data;
              
              // CHỈ HIỂN THỊ cho Admin
              if (role == 'admin') {
                return ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                  title: const Text('Quản lý Người dùng (Admin)'),
                  onTap: () {
                    Navigator.pop(context); // Đóng Drawer
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                    );
                  },
                );
              }
              // Trả về widget rỗng nếu không phải Admin
              return const SizedBox.shrink();
            },
          ),
          
          const Divider(),

          // Mục Đăng xuất
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () async {
              await AuthService().logout();
              // Thường sẽ chuyển hướng về màn hình Login/Wrapper
              Navigator.of(context).popUntil((route) => route.isFirst); 
            },
          ),
        ],
      ),
    );
  }
}