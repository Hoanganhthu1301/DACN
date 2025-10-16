import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile/profile_screen.dart';
import 'food/manage_food_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool isAdmin = false;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      final role = doc.data()?['role'] ?? 'user';

      setState(() {
        isAdmin = role == 'admin';

        // Khởi tạo các trang
        _pages = [
          const HomeScreen(),
          ProfileScreen(userId: currentUserId),
        ];

        if (isAdmin) {
          _pages.add(const ManageFoodPage());
        }

        // Khởi tạo BottomNavigationBarItem
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ];

        if (isAdmin) {
          _navItems.add(
              const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Quản lý'));
        }
      });
    } catch (e) {
      // fallback: user không phải admin
      setState(() {
        isAdmin = false;
        _pages = [
          const HomeScreen(),
          ProfileScreen(userId: currentUserId),
        ];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        items: _navItems,
      ),
    );
  }
}
