import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});
  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _name = TextEditingController();
  final _cal = TextEditingController();
  final _ingredients = TextEditingController();
  final _instructions = TextEditingController();
  String _diet = 'Mặn';
  final List<String> _dietOptions = ['Mặn', 'Chay', 'Ăn kiêng', 'Low-carb'];

  bool _loading = false;
  bool _isAdmin = false;
  bool _checkingRole = true;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Lấy token chứa custom claims
      final idTokenResult = await user.getIdTokenResult(true);
      final claims = idTokenResult.claims;
      if (claims != null && claims['role'] == 'admin') {
        setState(() => _isAdmin = true);
      }
    }
    setState(() => _checkingRole = false);
  }

  Future<void> _saveFood() async {
    if (!_isAdmin) return; // chỉ admin mới thêm được
    if (_name.text.isEmpty || _cal.text.isEmpty) return;

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection('foods').add({
        'name': _name.text,
        'calories': int.parse(_cal.text),
        'ingredients': _ingredients.text,
        'instructions': _instructions.text,
        'diet': _diet,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm món ăn thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Bạn không có quyền thêm món ăn.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm món ăn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên món')),
            TextField(controller: _cal, decoration: const InputDecoration(labelText: 'Calo')),
            TextField(controller: _ingredients, decoration: const InputDecoration(labelText: 'Nguyên liệu')),
            TextField(
              controller: _instructions,
              decoration: const InputDecoration(labelText: 'Hướng dẫn nấu'),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
             initialValue: _diet,
              decoration: const InputDecoration(labelText: 'Chế độ ăn'),
              items: _dietOptions
                  .map((diet) => DropdownMenuItem(value: diet, child: Text(diet)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _diet = val);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _saveFood,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Lưu món ăn'),
            ),
          ],
        ),
      ),
    );
  }
}
