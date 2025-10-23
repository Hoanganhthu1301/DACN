// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; // <-- Giữ lại import này cho Phân quyền
import 'food/add_food_page.dart';
import 'food/edit_food_page.dart';
import 'food/food_detail_screen.dart';
// import 'food/manage_food_page.dart'; // Bỏ comment nếu cần

// Chuyển sang StatefulWidget để quản lý trạng thái vai trò người dùng VÀ tìm kiếm
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Biến cho TÍNH NĂNG TÌM KIẾM
  String searchQuery = '';
  final foods = FirebaseFirestore.instance.collection('foods');
  
  // Biến cho TÍNH NĂNG PHÂN QUYỀN
  String _currentUserRole = 'guest';

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // Tải vai trò khi màn hình khởi tạo
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

  // Getter kiểm tra quyền CRUD
  bool get _canModify => _currentUserRole == 'admin' || _currentUserRole == 'editor';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.green,
        centerTitle: true,
        // ==> 1. THÊM BIỂU TƯỢNG MENU ĐỂ MỞ DRAWER
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer(); // Mở Drawer của DashboardScreen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // 🔍 Thanh tìm kiếm (TỪ NHÁNH MỚI)
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 10),

            // 🧭 Dãy card chức năng (TỪ NHÁNH MỚI)
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFeatureCard('Yêu thích', Icons.favorite, Colors.pink, () {}),
                  _buildFeatureCard('Nguyên liệu', Icons.shopping_basket, Colors.green, () {}),
                  
                  // Thêm Món ăn - PHÂN QUYỀN THÔNG QUA _canModify
                  if (_canModify) // Chỉ hiển thị card này nếu có quyền
                    _buildFeatureCard('Thêm món', Icons.add, Colors.orange, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddFoodPage()),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 🍜 Danh sách món ăn (TỪ NHÁNH MỚI - ĐÃ TÍCH HỢP TÌM KIẾM)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: foods.orderBy('created_at', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Tích hợp tìm kiếm: Lọc cục bộ theo tên
                  final docs = snapshot.data!.docs.where((doc) {
                    final name = doc['name'].toString().toLowerCase();
                    return name.contains(searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('Không tìm thấy món ăn nào!'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final food = docs[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: ListTile(
                          leading: food['image_url'] != null && food['image_url'] != ''
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(food['image_url'],
                                      width: 60, height: 60, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.fastfood, size: 40),
                          title: Text(food['name']),
                          subtitle: Text(
                              'Calo: ${food['calories']} kcal | Chế độ: ${food['diet']}'),
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
            ),
          ],
        ),
      ),
      
      // Bỏ FloatingActionButton vì đã có nút Thêm món trong FeatureCard (tránh lặp)
    );
  }

  // Hàm tạo card chức năng (TỪ NHÁNH MỚI)
  Widget _buildFeatureCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        // KHẮC PHỤC CẢNH BÁO: Thay thế withOpacity(0.1) bằng withAlpha(25)
        color: color.withAlpha(25), 
        margin: const EdgeInsets.only(right: 10),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}