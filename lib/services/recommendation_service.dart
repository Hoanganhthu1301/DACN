// lib/services/recommendation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class RecommendationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Lấy hồ sơ sở thích của người dùng
  Future<Map<String, dynamic>> _getFavoriteProfile() async {
    final userId = _uid;
    if (userId == null) {
      return {'categories': <String>{}, 'savedIds': <String>{}};
    }

    final savedSnapshot = await _db
        .collection('user_saves')
        .doc(userId)
        .collection('foods')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    final savedFoodIds = savedSnapshot.docs.map((doc) => doc.id).toSet();

    if (savedFoodIds.isEmpty) {
      return {'categories': <String>{}, 'savedIds': <String>{}};
    }

    final foodDocsSnap = await _db
        .collection('foods')
        .where(FieldPath.documentId, whereIn: savedFoodIds.toList())
        .get();

    final Set<String> favCategories = <String>{};
    for (var doc in foodDocsSnap.docs) {
      final data = doc.data();
      if (data['categoryName'] != null) {
        favCategories.add(data['categoryName'] as String);
      }
    }

    return {'categories': favCategories, 'savedIds': savedFoodIds};
  }

  // Tìm một món ngẫu nhiên cho một category
  Future<DocumentSnapshot?> _findRandomFoodForCategory({
    required String
    category, // "Món chính", "Món phụ", "Món khai vị", "Món tráng miệng"
    required Set<String> favCategories,
    required Set<String> excludeIds,
  }) async {
    // 1. Query theo category
    Query query = _db
        .collection('foods')
        .where('categoryName', isEqualTo: category)
        .limit(20);

    final snapshot = await query.get();

    // 2. Lọc client-side loại trừ món đã chọn/đã lưu
    final potentialMatches = snapshot.docs
        .where((doc) => !excludeIds.contains(doc.id))
        .toList();

    // 3. Nếu có món phù hợp, trả về ngẫu nhiên
    if (potentialMatches.isNotEmpty) {
      return potentialMatches[Random().nextInt(potentialMatches.length)];
    }

    // 4. Fallback: Nếu không còn món nào, vẫn lấy bất kỳ món nào trong category
    final fallbackSnap = await _db
        .collection('foods')
        .where('categoryName', isEqualTo: category)
        .limit(20)
        .get();
    final fallbackMatches = fallbackSnap.docs;
    if (fallbackMatches.isNotEmpty) {
      return fallbackMatches[Random().nextInt(fallbackMatches.length)];
    }

    // 5. Không còn món nào, trả về null
    return null;
  }

  // Lấy menu hàng ngày
  Future<Map<String, DocumentSnapshot?>> getDailyMenu() async {
    final userId = _uid;
    if (userId == null) throw Exception("Người dùng chưa đăng nhập");

    final profile = await _getFavoriteProfile();
    final favCategories = profile['categories'] as Set<String>;
    final excludeIds = profile['savedIds'] as Set<String>;

    // Tìm Món chính
    final main = await _findRandomFoodForCategory(
      category: 'Món chính',
      favCategories: favCategories,
      excludeIds: excludeIds,
    );
    if (main != null) excludeIds.add(main.id);

    // Tìm Món phụ
    final side = await _findRandomFoodForCategory(
      category: 'Món phụ',
      favCategories: favCategories,
      excludeIds: excludeIds,
    );
    if (side != null) excludeIds.add(side.id);

    // Tìm Món khai vị
    final appetizer = await _findRandomFoodForCategory(
      category: 'Món khai vị',
      favCategories: favCategories,
      excludeIds: excludeIds,
    );
    if (appetizer != null) excludeIds.add(appetizer.id);

    // Tìm Món tráng miệng
    final dessert = await _findRandomFoodForCategory(
      category: 'Món tráng miệng',
      favCategories: favCategories,
      excludeIds: excludeIds,
    );

    return {
      'main': main,
      'side': side,
      'appetizer': appetizer,
      'dessert': dessert,
    };
  }

  // Reload một món cụ thể
  Future<DocumentSnapshot?> reloadSingleMeal({
    required String category,
    required List<String> currentMenuFoodIds,
  }) async {
    final userId = _uid;
    if (userId == null) throw Exception("Người dùng chưa đăng nhập");

    final profile = await _getFavoriteProfile();
    final favCategories = profile['categories'] as Set<String>;
    final excludeIds = profile['savedIds'] as Set<String>;

    excludeIds.addAll(currentMenuFoodIds);

    final newFood = await _findRandomFoodForCategory(
      category: category,
      favCategories: favCategories,
      excludeIds: excludeIds,
    );

    return newFood;
  }
}
