import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // 👈 thêm dòng này
import 'food/add_food_page.dart';
import 'food/edit_food_page.dart';
import 'food/food_detail_screen.dart';
// import 'food/manage_food_page.dart';
// import 'account/login_screen.dart'; // 👈 import màn hình đăng nhập của bạn

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final foods = FirebaseFirestore.instance.collection('foods');
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.green,
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     tooltip: 'Đăng xuất',
        //     onPressed: () async {
        //       await FirebaseAuth.instance.signOut(); // 👈 đăng xuất tài khoản
        //       if (context.mounted) {
        //         Navigator.pushAndRemoveUntil(
        //           context,
        //           MaterialPageRoute(builder: (_) => const LoginScreen()), // 👈 quay về login
        //           (route) => false,
        //         );
        //       }
        //     },
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // 🔍 Thanh tìm kiếm
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

            // 🧭 Dãy card chức năng
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // _buildFeatureCard('Quản lý bài viết', Icons.article, Colors.blue, () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(builder: (_) => const ManageFoodPage()),
                  //   );
                  // }),
                  _buildFeatureCard('Yêu thích', Icons.favorite, Colors.pink, () {}),
                  _buildFeatureCard('Nguyên liệu', Icons.shopping_basket, Colors.green, () {}),
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

            // 🍜 Danh sách món ăn
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: foods.orderBy('created_at', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

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
                          trailing: PopupMenuButton(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditFoodPage(foodId: food.id, data: food),
                                  ),
                                );
                              }
                              // } else if (value == 'delete') {
                              //   await foods.doc(food.id).delete();
                              //   if (context.mounted) {
                              //     ScaffoldMessenger.of(context).showSnackBar(
                              //       const SnackBar(content: Text('Đã xóa món ăn!')),
                              //     );
                              //   }
                              // }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Sửa')),
                              // PopupMenuItem(value: 'delete', child: Text('Xóa')),
                            ],
                          ),
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
    );
  }

  // Hàm tạo card chức năng
  Widget _buildFeatureCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color.withValues(alpha: 0.1),
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
