import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'edit_food_page.dart';

class ManageFoodPage extends StatefulWidget {
  const ManageFoodPage({super.key});

  @override
  State<ManageFoodPage> createState() => _ManageFoodPageState();
}

class _ManageFoodPageState extends State<ManageFoodPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteFood(String foodId) async {
    try {
      await _firestore.collection('foods').doc(foodId).delete();
      
    if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Đã xóa món ăn thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi khi xóa món ăn: $e')),
      );
    }
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "$name" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deleteFood(id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý bài viết'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('foods').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Chưa có món ăn nào được đăng!'),
            );
          }

          final foods = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: foods.length,
            itemBuilder: (context, index) {
              final food = foods[index];
              final data = food.data() as Map<String, dynamic>;

// <<<<<<< HEAD
//               final locked = data['isLocked'] ?? false;
//               final isOwner = data['authorId'] == user.uid;

//               return Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 child: ListTile(
//                   leading: data['image_url'] != null && data['image_url'] != ''
//                       ? ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: Image.network(
//                             data['image_url'],
//                             width: 60,
//                             height: 60,
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                       : const Icon(Icons.image_not_supported),
//                   title: Text(
//                     data['name'] ?? 'Không có tên',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: locked ? Colors.grey : Colors.black,
//                     ),
//                   ),
//                   subtitle: Text('Người đăng: ${data['authorEmail'] ?? 'Ẩn danh'}'),
//                   trailing: PopupMenuButton<String>(
//                     onSelected: (value) async {
//                       if (value == 'delete') {
//                         await FirebaseFirestore.instance.collection('foods').doc(food.id).delete();
//                       } else if (value == 'lock' && role == 'admin') {
//                         await FirebaseFirestore.instance.collection('foods').doc(food.id).update({'isLocked': true});
//                       } else if (value == 'unlock' && role == 'admin') {
//                         await FirebaseFirestore.instance.collection('foods').doc(food.id).update({'isLocked': false});
//                       }
//                     },
//                     itemBuilder: (context) => [
//                       if (role == 'admin' && !locked)
//                         const PopupMenuItem(value: 'lock', child: Text('Khóa bài viết')),
//                       if (role == 'admin' && locked)
//                         const PopupMenuItem(value: 'unlock', child: Text('Mở khóa bài viết')),
//                       if (role == 'admin' || isOwner)
//                         const PopupMenuItem(value: 'delete', child: Text('Xóa bài viết')),
// =======
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['imageUrl'] ?? data['image_url'] ?? '',                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? 'Không tên',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Người đăng: ${data['authorEmail'] ?? 'Ẩn danh'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (data['locked'] == true)
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Icon(Icons.lock, size: 16, color: Colors.red),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditFoodPage(
                              foodId: food.id,
                              data: data,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(food.id, data['name'] ?? 'món ăn');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa món'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
