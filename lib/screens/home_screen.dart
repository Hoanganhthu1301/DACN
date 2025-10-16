// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; // <-- Bắt buộc phải có
import 'food/add_food_page.dart';
import 'food/edit_food_page.dart';
import 'food/food_detail_screen.dart';

// Chuyển sang StatefulWidget để quản lý trạng thái vai trò người dùng
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Biến lưu trữ vai trò người dùng hiện tại, mặc định là 'guest'
  String _currentUserRole = 'guest';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  // Hàm tải vai trò người dùng từ Firestore
  Future<void> _loadUserRole() async {
    final role = await AuthService().getCurrentUserRole();
    if (mounted) {
      setState(() {
        _currentUserRole = role;
      });
    }
  }

  // Getter kiểm tra quyền CRUD (admin hoặc editor)
  bool get _canModify => _currentUserRole == 'admin' || _currentUserRole == 'editor';

  @override
  Widget build(BuildContext context) {
    final foods = FirebaseFirestore.instance.collection('foods');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.green,
        // ==> 1. THÊM BIỂU TƯỢNG MENU ĐỂ MỞ DRAWER
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Lệnh để mở Drawer được định nghĩa trong Scaffold cha (DashboardScreen)
            Scaffold.of(context).openDrawer(); 
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: foods.orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có món ăn nào!'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final food = docs[i];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: food['image_url'] != null && food['image_url'] != ''
                      ? Image.network(food['image_url'],
                          width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.fastfood, size: 40),
                  title: Text(food['name']),
                  subtitle: Text('Calo: ${food['calories']} kcal | Chế độ: ${food['diet']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodDetailScreen(foodId: food.id),
                      ),
                    );
                  },
                  
                  // ==> 2. PHÂN QUYỀN CHO NÚT SỬA/XÓA
                  trailing: _canModify
                      ? PopupMenuButton(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditFoodPage(foodId: food.id, data: food),
                                ),
                              );
                            } else if (value == 'delete') {
                              // Logic xóa
                              await foods.doc(food.id).delete();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã xóa món ăn!')),
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Sửa')),
                            PopupMenuItem(value: 'delete', child: Text('Xóa')),
                          ],
                        )
                      : null, // Ẩn nút nếu không có quyền
                ),
              );
            },
          );
        },
      ),
      
      // ==> 3. PHÂN QUYỀN CHO FLOATING ACTION BUTTON
      floatingActionButton: _canModify
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddFoodPage()),
                );
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            )
          : null, // Ẩn nút nếu không có quyền
    );
  }
}