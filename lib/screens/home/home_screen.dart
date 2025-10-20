import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../food/add_food_page.dart';
//import 'food/edit_food_page.dart';
import '../food/food_detail_screen.dart';
import '../food/saved_foods_page.dart';
import '../../services/like_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final foods = FirebaseFirestore.instance.collection('foods');
  final _likeSvc = LikeService();

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          // Lối tắt tới "Món đã lưu"
          IconButton(
            tooltip: 'Món đã lưu',
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedFoodsPage()),
              );
            },
          ),
        ],
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
                  // Card "Yêu thích" → mở danh sách món đã lưu (Saved)
                  _buildFeatureCard(
                    'Yêu thích',
                    Icons.favorite,
                    Colors.pink,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedFoodsPage(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    'Nguyên liệu',
                    Icons.shopping_basket,
                    Colors.green,
                    () {},
                  ),
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
                stream: foods
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final name = doc['name'].toString().toLowerCase();
                    return name.contains(searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Không tìm thấy món ăn nào!'),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final food = docs[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: ListTile(
                          leading:
                              food['image_url'] != null &&
                                  food['image_url'] != ''
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    food['image_url'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.fastfood, size: 40),
                          title: Text(food['name']),
                          subtitle: Text(
                            'Calo: ${food['calories']} kcal | Chế độ: ${food['diet']}',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FoodDetailScreen(foodId: food.id),
                              ),
                            );
                          },
                          // Nút tim + số lượt thích + nút lưu
                          trailing: SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Like
                                StreamBuilder<bool>(
                                  stream: _likeSvc.isLikedStream(food.id),
                                  initialData: false,
                                  builder: (context, s) {
                                    final liked = s.data ?? false;
                                    return IconButton(
                                      tooltip: liked ? 'Bỏ thích' : 'Thích',
                                      onPressed: uid == null
                                          ? null
                                          : () => _likeSvc.toggleLike(
                                              food.id,
                                              liked,
                                            ),
                                      icon: Icon(
                                        liked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: liked ? Colors.pink : null,
                                      ),
                                    );
                                  },
                                ),
                                // Count
                                StreamBuilder<int>(
                                  stream: _likeSvc.likesCount(food.id),
                                  builder: (context, s) {
                                    final count = s.data ?? 0;
                                    return Text(
                                      '$count',
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                // Save
                                StreamBuilder<bool>(
                                  stream: _likeSvc.isSavedStream(food.id),
                                  initialData: false,
                                  builder: (context, s) {
                                    final saved = s.data ?? false;
                                    return IconButton(
                                      tooltip: saved ? 'Bỏ lưu' : 'Lưu',
                                      onPressed: uid == null
                                          ? null
                                          : () => _likeSvc.toggleSave(
                                              food.id,
                                              saved,
                                            ),
                                      icon: Icon(
                                        saved
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                      ),
                                    );
                                  },
                                ),
                                // Bạn có thể giữ menu Sửa tại đây nếu muốn, nhưng sẽ chật.
                                // Popup menu sửa:
                                // PopupMenuButton(
                                //   onSelected: (value) async {
                                //     if (value == 'edit') {
                                //       Navigator.push(
                                //         context,
                                //         MaterialPageRoute(
                                //           builder: (_) => EditFoodPage(foodId: food.id, data: food),
                                //         ),
                                //       );
                                //     }
                                //   },
                                //   itemBuilder: (context) => const [
                                //     PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                //   ],
                                // ),
                              ],
                            ),
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
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        // Nếu withValues không hỗ trợ SDK của bạn, đổi thành withOpacity(0.1)
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
