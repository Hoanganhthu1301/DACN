import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageCategoryPage extends StatefulWidget {
  const ManageCategoryPage({super.key});

  @override
  State<ManageCategoryPage> createState() => _ManageCategoryPageState();
}

class _ManageCategoryPageState extends State<ManageCategoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        debugPrint('⚠️ Không tìm thấy user trong Firestore!');
        setState(() {
          _isAdmin = false;
          _loading = false;
        });
        return;
      }

      final data = doc.data();
      debugPrint('👤 Dữ liệu user: $data');

      setState(() {
        _isAdmin = data?['role'] == 'admin';
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Lỗi khi kiểm tra admin: $e');
      setState(() {
        _isAdmin = false;
        _loading = false;
      });
    }
  }


  Future<void> _addOrEditCategory({String? id, String? name, String? type}) async {
    TextEditingController nameController = TextEditingController(text: name ?? '');
    String selectedType = type ?? 'theo_loai_mon_an';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? 'Thêm danh mục' : 'Sửa danh mục'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên danh mục'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(labelText: 'Loại danh mục'),
              items: const [
                DropdownMenuItem(value: 'theo_loai_mon_an', child: Text('Theo loại món ăn')),
                DropdownMenuItem(value: 'theo_che_do_an', child: Text('Theo chế độ ăn')),
              ],
              onChanged: (val) => selectedType = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameController.text.trim(),
                'type': selectedType,
                'createdAt': FieldValue.serverTimestamp(),
              };

              if (id == null) {
                await _firestore.collection('categories').add(data);
              } else {
                await _firestore.collection('categories').doc(id).update(data);
              }

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Bạn không có quyền truy cập trang này.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('categories')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.category, color: Colors.green),
                  title: Text(data['name']),
                  subtitle: Text(
                    data['type'] == 'theo_loai_mon_an'
                        ? 'Phân loại món ăn'
                        : 'Phân loại theo chế độ ăn',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _addOrEditCategory(
                          id: data.id,
                          name: data['name'],
                          type: data['type'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCategory(data.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _addOrEditCategory(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
