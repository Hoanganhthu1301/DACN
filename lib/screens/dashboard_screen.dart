import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'food/manage_food_page.dart'; // Trang quản lý (admin)
import 'home_screen.dart';
import 'profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String userRole = ''; // admin hoặc user
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      String role = userDoc['role'] ?? 'user';

      setState(() {
        userRole = role;

        // 👉 Nếu là admin thì có thêm trang "Quản lý"
        if (userRole == 'admin') {
          _pages = [
            const HomeScreen(),
            const ManageFoodPage(),
            ProfileScreen(userId: currentUserId),
          ];
        } else {
          // 👉 User chỉ có Trang chủ và Cá nhân
          _pages = [
            const HomeScreen(),
            ProfileScreen(userId: currentUserId),
          ];
        }
      });
    } catch (e) {
      print('Lỗi lấy role: $e');
      setState(() {
        userRole = 'user';
        _pages = [
          const HomeScreen(),
          ProfileScreen(userId: currentUserId),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userRole.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        items: userRole == 'admin'
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Quản lý'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
              ],
      ),
    );
  }
}
