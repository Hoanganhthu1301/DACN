import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../food/add_food_page.dart';
import '../food/food_detail_screen.dart';
import '../food/saved_foods_page.dart';
import '../../services/like_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _likeSvc = LikeService();

  List<DocumentSnapshot> _allFoods = []; // 🔹 Tất cả món ăn
  List<DocumentSnapshot> _displayFoods = []; // 🔹 Hiển thị theo trang
  bool _isLoading = true;

  String searchQuery = '';

  // 🔹 Phân trang
  static const int _pageSize = 5;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchAllFoods();
  }

  Future<void> _fetchAllFoods() async {
    setState(() => _isLoading = true);

    final snapshot = await _firestore
        .collection('foods')
        .orderBy('created_at', descending: true)
        .get();

    final docs = snapshot.docs;
    _totalPages = (docs.length / _pageSize).ceil();

    setState(() {
      _allFoods = docs;
      _updatePageData();
      _isLoading = false;
    });
  }

  void _updatePageData() {
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (_currentPage * _pageSize < _allFoods.length)
        ? _currentPage * _pageSize
        : _allFoods.length;

    _displayFoods = _allFoods.sublist(startIndex, endIndex);
  }

  void _changePage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
      _updatePageData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển...')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  // 🔍 Tìm kiếm
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
                        _buildFeatureCard(
                          'Đã lưu',
                          Icons.bookmark,
                          Colors.blueGrey,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SavedFoodsPage()),
                          ),
                        ),
                        _buildFeatureCard(
                          'Nguyên liệu',
                          Icons.shopping_basket,
                          Colors.green,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Chức năng đang được cập nhật...')),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          'Thêm món',
                          Icons.add,
                          Colors.orange,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddFoodPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🍜 Danh sách món ăn + phân trang ở cuối
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _fetchAllFoods(),
                      child: ListView.builder(
                        itemCount: _displayFoods.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _displayFoods.length) {
                            // 👉 Nút phân trang
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: _currentPage > 1
                                        ? () => _changePage(_currentPage - 1)
                                        : null,
                                  ),
                                  ...List.generate(_totalPages, (pageIndex) {
                                    final page = pageIndex + 1;
                                    return GestureDetector(
                                      onTap: () => _changePage(page),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _currentPage == page
                                              ? Colors.green
                                              : Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$page',
                                          style: TextStyle(
                                            color: _currentPage == page
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: _currentPage < _totalPages
                                        ? () => _changePage(_currentPage + 1)
                                        : null,
                                  ),
                                ],
                              ),
                            );
                          }

                          final food = _displayFoods[index];
                          final name =
                              (food['name'] ?? '').toString().toLowerCase();

                          if (!name.contains(searchQuery)) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            child: ListTile(
                              leading: food['image_url'] != null &&
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
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FoodDetailScreen(foodId: food.id),
                                ),
                              ),
                              trailing: SizedBox(
                                width: 120,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                            color: liked
                                                ? Colors.pink
                                                : Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                    StreamBuilder<int>(
                                      stream: _likeSvc.likesCount(food.id),
                                      builder: (context, s) {
                                        final count = s.data ?? 0;
                                        return Text('$count',
                                            style:
                                                const TextStyle(fontSize: 12));
                                      },
                                    ),
                                    const SizedBox(width: 8),
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
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color.withValues(alpha: 0.1), // ✅ Thay vì withOpacity
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
