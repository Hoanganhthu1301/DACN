// lib/models/food_search_state.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/food_service.dart';

class FoodSearchState with ChangeNotifier {
  // Dependency Injection: Service được truyền vào
  final FoodService _foodService;
  
  // 1. Các biến trạng thái
  bool _isSearching = false;
  List<QueryDocumentSnapshot> _searchResults = [];
  String _currentQuery = '';

  // 2. Constructor
  FoodSearchState(this._foodService); 
  
  // 3. Getters công khai (để UI đọc)
  bool get isSearching => _isSearching;
  List<QueryDocumentSnapshot> get searchResults => _searchResults;
  String get currentQuery => _currentQuery;

  // Stream món ăn chung (để HomeScreen hiển thị toàn bộ món ăn)
  Stream<QuerySnapshot> get allDishesStream => _foodService.getDishes();
  
  // 4. Phương thức thay đổi trạng thái
  Future<void> searchByIngredients(String query) async {
    _isSearching = true;
    _currentQuery = query;
    notifyListeners(); // Báo cho UI hiển thị loading

    // Chuẩn hóa query
    final List<String> ingredients = query.split(',').map((s) => s.trim()).toList();

    // Gọi hàm tìm kiếm từ FoodService
    final results = await _foodService.searchDishesByIngredients(ingredients);

    _searchResults = results;
    _isSearching = false;
    notifyListeners(); // Báo cho UI hiển thị kết quả
  }
  
  // 5. Xóa trạng thái tìm kiếm (khi người dùng xóa thanh tìm kiếm)
  void clearSearch() {
    _searchResults = [];
    _currentQuery = '';
    notifyListeners();
  }
}