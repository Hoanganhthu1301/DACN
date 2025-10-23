// lib/services/food_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Giả định bạn đã có một Food Model, nếu chưa, QueryDocumentSnapshot là đủ
// import '../models/food.dart'; 

class FoodService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Tên collection món ăn là 'food' (dựa trên ảnh Firestore)
  final String _collectionName = 'food'; 

  // 1. Stream: Lấy toàn bộ món ăn (dùng cho HomeScreen)
  Stream<QuerySnapshot> getDishes() {
    return _db.collection(_collectionName)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // 2. Logic Tìm kiếm Nâng cao (Search by Ingredients)
  // Lưu ý: Firestore không hỗ trợ tìm kiếm mảng (array-contains-any) cho logic AND/OR
  // nên chúng ta sẽ thực hiện lọc phụ trợ trên client (Flutter).
  Future<List<QueryDocumentSnapshot>> searchDishesByIngredients(
      List<String> userIngredients) async {
    
    // 1. Lấy tất cả món ăn từ Firestore
    final snapshot = await _db.collection(_collectionName).get();
    
    // 2. Chuẩn hóa nguyên liệu đầu vào (loại bỏ khoảng trắng, chuyển về chữ thường)
    final normalizedUserIngredients = userIngredients
        .map((e) => e.trim().toLowerCase())
        .toSet(); // Set để loại bỏ trùng lặp và tăng tốc độ tìm kiếm

    if (normalizedUserIngredients.isEmpty || (normalizedUserIngredients.length == 1 && normalizedUserIngredients.first.isEmpty)) {
      // Nếu query rỗng, trả về danh sách trống
      return []; 
    }

    List<QueryDocumentSnapshot> filteredResults = [];

    for (var doc in snapshot.docs) {
      final dishData = doc.data();
      final dishIngredientsString = dishData['ingredients'] as String? ?? '';
      
      // Tách và chuẩn hóa nguyên liệu của món ăn
      final dishIngredients = dishIngredientsString
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toSet();

      if (dishIngredients.isEmpty) {
        continue; // Bỏ qua nếu món ăn không có nguyên liệu
      }

      // Tính toán mức độ phù hợp (tỷ lệ phần trăm)
      int matchedCount = 0;
      for (var userIngredient in normalizedUserIngredients) {
        if (dishIngredients.contains(userIngredient)) {
          matchedCount++;
        }
      }

      // Tỷ lệ phù hợp: (Nguyên liệu user có khớp) / (Tổng số nguyên liệu user nhập)
      final matchRatio = matchedCount / normalizedUserIngredients.length;
      
      // ĐIỀU KIỆN LỌC: Phải khớp ít nhất 60% nguyên liệu người dùng nhập
      if (matchRatio >= 0.6) {
        filteredResults.add(doc);
      }
    }
    
    // Sắp xếp kết quả theo tỷ lệ phù hợp (từ cao xuống thấp)
    // (Đây là logic tối ưu, nhưng chúng ta sẽ giữ code đơn giản nhất cho bước này)
    
    return filteredResults;
  }
}