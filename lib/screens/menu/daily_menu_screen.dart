import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/recommendation_service.dart';
import '../food/food_detail_screen.dart';

class DailyMenuScreen extends StatefulWidget {
  const DailyMenuScreen({super.key});

  @override
  State<DailyMenuScreen> createState() => _DailyMenuScreenState();
}

class _DailyMenuScreenState extends State<DailyMenuScreen> {
  // Khởi tạo Future mặc định để tránh LateInitializationError
  Future<Map<String, DocumentSnapshot?>> _menuFuture = Future.value({});
  final RecommendationService _recommendationService = RecommendationService();

  Map<String, DocumentSnapshot?> lockedMeals = {
    'main': null,
    'side': null,
    'appetizer': null,
    'dessert': null,
  };

  static const Map<String, String> titleToKey = {
    'Món chính': 'main',
    'Món phụ': 'side',
    'Khai vị': 'appetizer',
    'Tráng miệng': 'dessert',
  };

  @override
  void initState() {
    super.initState();
    // Load món đã khóa và menu cũ, nếu không có thì lấy menu mới
    _menuFuture = _loadLockedMeals().then((_) async {
      final savedMenu = await _loadSavedMenu();
      bool hasSaved = savedMenu.values.any((doc) => doc != null);
      if (hasSaved) return savedMenu;

      final newMenu = await _recommendationService.getDailyMenu();
      await _saveMenu(newMenu); // lưu menu mới
      return newMenu;
    });
  }

  // Load món đã giữ từ SharedPreferences
  Future<void> _loadLockedMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final foodsCollection = FirebaseFirestore.instance.collection('foods');
    for (var key in lockedMeals.keys) {
      final id = prefs.getString('locked_$key');
      if (id != null && id.isNotEmpty) {
        final doc = await foodsCollection.doc(id).get();
        if (doc.exists) {
          lockedMeals[key] = doc;
        }
      }
    }
  }

  // Lưu món đã giữ vào SharedPreferences
  Future<void> _saveLockedMeal(String key, String? foodId) async {
    final prefs = await SharedPreferences.getInstance();
    if (foodId != null) {
      await prefs.setString('locked_$key', foodId);
    } else {
      await prefs.remove('locked_$key');
    }
  }

  // Lưu menu hiện tại vào SharedPreferences
  Future<void> _saveMenu(Map<String, DocumentSnapshot?> menu) async {
    final prefs = await SharedPreferences.getInstance();
    for (var key in menu.keys) {
      final doc = menu[key];
      if (doc != null && doc.exists) {
        await prefs.setString('saved_$key', doc.id);
      } else {
        await prefs.remove('saved_$key');
      }
    }
  }

  // Load menu cũ từ SharedPreferences
  Future<Map<String, DocumentSnapshot?>> _loadSavedMenu() async {
    final prefs = await SharedPreferences.getInstance();
    final foodsCollection = FirebaseFirestore.instance.collection('foods');
    Map<String, DocumentSnapshot?> savedMenu = {
      'main': null,
      'side': null,
      'appetizer': null,
      'dessert': null,
    };

    for (var key in savedMenu.keys) {
      final id = prefs.getString('saved_$key');
      if (id != null && id.isNotEmpty) {
        final doc = await foodsCollection.doc(id).get();
        if (doc.exists) savedMenu[key] = doc;
      }
    }

    return savedMenu;
  }

  // Reload menu mới từ RecommendationService, giữ các món đã khóa
  void _reloadMenu() async {
    final newMenu = await _recommendationService.getDailyMenu();

    // Giữ các món đã khóa
    newMenu.forEach((key, value) {
      if (lockedMeals[key] != null) newMenu[key] = lockedMeals[key];
    });

    await _saveMenu(newMenu); // lưu menu mới

    setState(() {
      _menuFuture = Future.value(newMenu);
    });
  }

  Widget _buildMealCard(
    BuildContext context,
    String title,
    IconData icon,
    DocumentSnapshot? foodDoc,
  ) {
    final key = titleToKey[title] ?? title;
    final isLocked = lockedMeals[key] == foodDoc && foodDoc != null;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (foodDoc != null && foodDoc.exists)
                  IconButton(
                    icon: Icon(
                      isLocked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isLocked) {
                          lockedMeals[key] = null;
                          _saveLockedMeal(key, null);
                        } else {
                          lockedMeals[key] = foodDoc;
                          _saveLockedMeal(key, foodDoc.id);
                        }
                      });
                    },
                    tooltip: isLocked ? 'Bỏ giữ món' : 'Giữ món',
                  ),
              ],
            ),
            const Divider(height: 20),
            if (foodDoc != null && foodDoc.exists) ...[
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FoodDetailScreen(foodId: foodDoc.id),
                    ),
                  );
                },
                child: Builder(
                  builder: (_) {
                    final data = foodDoc.data() as Map<String, dynamic>? ?? {};
                    final imageUrl =
                        (data['image_url'] ?? data['imageUrl']) as String? ??
                        '';
                    final name = data['name'] as String? ?? 'Món ăn';
                    final calories = data['calories']?.toString() ?? '0';
                    return Row(
                      children: [
                        imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.grey,
                                ),
                              ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$calories kcal',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    );
                  },
                ),
              ),
            ] else ...[
              const Text(
                'Không tìm thấy món phù hợp với sở thích của bạn cho bữa này. Hãy thử lưu thêm món nhé!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thực đơn gợi ý hôm nay"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadMenu,
            tooltip: "Gợi ý thực đơn khác",
          ),
        ],
      ),
      body: FutureBuilder<Map<String, DocumentSnapshot?>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Lỗi tải gợi ý: ${snapshot.error}"),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không có gợi ý nào."));
          }

          final menu = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMealCard(
                context,
                'Món chính',
                Icons.restaurant,
                menu['main'],
              ),
              const SizedBox(height: 16),
              _buildMealCard(context, 'Món phụ', Icons.rice_bowl, menu['side']),
              const SizedBox(height: 16),
              _buildMealCard(
                context,
                'Khai vị',
                Icons.local_dining,
                menu['appetizer'],
              ),
              const SizedBox(height: 16),
              _buildMealCard(
                context,
                'Tráng miệng',
                Icons.icecream,
                menu['dessert'],
              ),
            ],
          );
        },
      ),
    );
  }
}
