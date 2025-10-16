import 'package:firebase_auth/firebase_auth.dart'; // Thêm import này
import 'package:flutter/material.dart';
import 'food/food_list_page.dart';
import 'home_screen.dart';
import 'profile/profile_screen.dart'; // Thêm import cho màn hình profile mới

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Lấy UID của người dùng hiện tại
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  late final List<Widget> _pages; // Khai báo _pages ở đây

  @override
  void initState() {
    super.initState();
    // Khởi tạo _pages trong initState để có thể truyền currentUserId
    _pages = [
      const HomeScreen(), // Trang chủ
      const FoodListPage(), // Danh sách món ăn
      ProfileScreen(userId: currentUserId), // Trang cá nhân, truyền UID vào
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Món ăn'),
          // Thêm mục Profile
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}
