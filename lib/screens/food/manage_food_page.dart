import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageFoodPage extends StatefulWidget {
  const ManageFoodPage({super.key});

  @override
  State<ManageFoodPage> createState() => _ManageFoodPageState();
}

class _ManageFoodPageState extends State<ManageFoodPage> {
  final user = FirebaseAuth.instance.currentUser!;
  String? role;

  @override
  void initState() {
    super.initState();
    _getRole();
  }

Future<void> _getRole() async {
  String fetchedRole = 'user';

  try {
    // 1. Ưu tiên lấy role từ custom claims
    final idTokenResult = await user.getIdTokenResult(true);
    fetchedRole = idTokenResult.claims?['role'] ?? 'user';

    // 2. Nếu chưa có thì fallback qua Firestore
    if (fetchedRole == 'user') {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      fetchedRole = doc.data()?['role'] ?? 'user';
    }

    // 🔥 KHẮC PHỤC LỖI TỰ MẤT DỮ LIỆU
    if (!mounted) return; // tránh setState khi widget đã dispose
    setState(() {
      role = fetchedRole;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      role = 'user'; // fallback nếu lỗi
    });
  }
}


  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final query = role == 'admin'
        ? FirebaseFirestore.instance.collection('foods').orderBy('created_at', descending: true)
        : FirebaseFirestore.instance
            .collection('foods')
            .where('authorId', isEqualTo: user.uid)
            .orderBy('created_at', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý bài viết')),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có bài viết nào.'));
          }

          final foods = snapshot.data!.docs;

          return ListView.builder(
            itemCount: foods.length,
            itemBuilder: (context, index) {
              final food = foods[index];
              final data = food.data() as Map<String, dynamic>;

              final locked = data['isLocked'] ?? false;
              final isOwner = data['authorId'] == user.uid;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: data['image_url'] != null && data['image_url'] != ''
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['image_url'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(
                    data['name'] ?? 'Không có tên',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: locked ? Colors.grey : Colors.black,
                    ),
                  ),
                  subtitle: Text('Người đăng: ${data['authorEmail'] ?? 'Ẩn danh'}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await FirebaseFirestore.instance.collection('foods').doc(food.id).delete();
                      } else if (value == 'lock' && role == 'admin') {
                        await FirebaseFirestore.instance.collection('foods').doc(food.id).update({'isLocked': true});
                      } else if (value == 'unlock' && role == 'admin') {
                        await FirebaseFirestore.instance.collection('foods').doc(food.id).update({'isLocked': false});
                      }
                    },
                    itemBuilder: (context) => [
                      if (role == 'admin' && !locked)
                        const PopupMenuItem(value: 'lock', child: Text('Khóa bài viết')),
                      if (role == 'admin' && locked)
                        const PopupMenuItem(value: 'unlock', child: Text('Mở khóa bài viết')),
                      if (role == 'admin' || isOwner)
                        const PopupMenuItem(value: 'delete', child: Text('Xóa bài viết')),
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
