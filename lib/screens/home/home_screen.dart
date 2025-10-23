// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; 
import '../../services/like_service.dart';
import '../../services/auth_service.dart'; 
import '../account/user_management_screen.dart'; 

import '../../widgets/notifications_button.dart';
import '../../core/push/push_service_min.dart';

import '../food/add_food_page.dart';
import '../food/food_detail_screen.dart';
import '../food/edit_food_page.dart'; 
import '../food/saved_foods_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final foods = FirebaseFirestore.instance.collection('foods');
  // Khai báo Services, sẽ được gán trong didChangeDependencies
  late LikeService _likeSvc; 
  late AuthService _authService;

  final _push = PushServiceMin(); 

  String searchQuery = '';
  
  // LOGIC PHÂN QUYỀN
  String _currentUserRole = 'guest'; 
  bool get _isAdmin => _currentUserRole == 'admin'; // Kiểm tra quyền Admin
  
  // Lấy UID ở đây để dùng trong build
  final String? uid = FirebaseAuth.instance.currentUser?.uid; 
  bool get _isLoggedIn => uid != null; // Quyền CRUD mở rộng cho tất cả user đã đăng nhập

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _push.init(context: context); 
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lấy các Service qua Provider
    _authService = context.read<AuthService>();
    _likeSvc = context.read<LikeService>();
    // Tải vai trò ngay sau khi lấy được AuthService
    _loadUserRole(); 
  }


  Future<void> _loadUserRole() async {
    final role = await _authService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _currentUserRole = role;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Xác định widget Leading (Nút Admin)
    final Widget? leadingWidget = _isAdmin
        ? IconButton(
            icon: const Icon(Icons.group, color: Colors.white),
            tooltip: 'Quản lý Người dùng',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManagementScreen()),
              );
            },
          )
        : null; // Không hiển thị gì nếu không phải admin

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.green,
        centerTitle: true,
        
        // ==> ĐẶT NÚT ADMIN Ở VỊ TRÍ LEADING (Góc trái) <==
        leading: leadingWidget,
        
        actions: const [
          // Nút Thông báo (giữ nguyên ở bên phải)
          NotificationsButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // 🔍 Thanh tìm kiếm (Giữ nguyên)
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
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
                  // Yêu thích
                  _buildFeatureCard(
                    'Yêu thích',
                    Icons.favorite,
                    Colors.pink,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedFoodsPage()),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    'Nguyên liệu',
                    Icons.shopping_basket,
                    Colors.green,
                    () {},
                  ),
                  
                  // Thêm món (HIỂN THỊ CHO TẤT CẢ USER ĐÃ ĐĂNG NHẬP)
                  if (_isLoggedIn)
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
                                  child: Image.network(
                                    food['image_url'],
                                    width: 60, height: 60, fit: BoxFit.cover,
                                  ),
                                )
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
                          
                          // ==> TRAILING: LIKE, COUNT, SAVE VÀ POPUPMENU (SỬA/XÓA)
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ❤️ Like & Count
                              StreamBuilder<bool>(
                                stream: _likeSvc.isLikedStream(food.id),
                                initialData: false,
                                builder: (context, s) {
                                  final liked = s.data ?? false;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: liked ? 'Bỏ thích' : 'Thích',
                                        onPressed: uid == null ? null : () => _likeSvc.toggleLike(food.id, liked),
                                        icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.pink : null),
                                      ),
                                      StreamBuilder<int>(
                                        stream: _likeSvc.likesCount(food.id),
                                        builder: (context, s) {
                                          final count = s.data ?? 0;
                                          return Text('$count', style: const TextStyle(fontSize: 12));
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // 🔖 Lưu món + NÚT SỬA/XÓA
                              StreamBuilder<bool>(
                                stream: _likeSvc.isSavedStream(food.id),
                                initialData: false,
                                builder: (context, s) {
                                  final saved = s.data ?? false;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: saved ? 'Bỏ lưu' : 'Lưu',
                                        onPressed: uid == null ? null : () => _likeSvc.toggleSave(food.id, saved),
                                        icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                                      ),
                                      
                                      // NÚT SỬA/XÓA (PopupMenuButton) - HIỂN THỊ CHO TẤT CẢ USER ĐÃ ĐĂNG NHẬP
                                      if (_isLoggedIn) 
                                        PopupMenuButton(
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              // Chuyển đến trang sửa
                                              Navigator.push(context, MaterialPageRoute(builder: (_) => EditFoodPage(foodId: food.id, data: food)));
                                            } else if (value == 'delete') {
                                              // Logic xóa
                                              await foods.doc(food.id).delete();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa món ăn!')));
                                              }
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                            PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                          ],
                                        ),
                                    ],
                                  );
                                },
                              ),
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
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
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