<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile/profile_screen.dart';
import 'food/manage_food_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
=======
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'food/manage_food_page.dart'; // Trang quản lý (admin)
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
>>>>>>> main

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
<<<<<<< HEAD
  bool isAdmin = false;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];
=======
  String userRole = ''; // admin hoặc user
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late List<Widget> _pages;
>>>>>>> main

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
<<<<<<< HEAD
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
=======
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
          _pages = [const HomeScreen(), ProfileScreen(userId: currentUserId)];
        }
      });
    } catch (e) {
    debugPrint('Lỗi lấy role: $e');
      setState(() {
        userRole = 'user';
        _pages = [const HomeScreen(), ProfileScreen(userId: currentUserId)];
>>>>>>> main
      });
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    if (_pages.isEmpty) {
=======
    if (userRole.isEmpty) {
>>>>>>> main
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
<<<<<<< HEAD
        items: _navItems,
=======
        items: userRole == 'admin'
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Quản lý',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Cá nhân',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Cá nhân',
                ),
              ],
>>>>>>> main
      ),
    );
  }
}
