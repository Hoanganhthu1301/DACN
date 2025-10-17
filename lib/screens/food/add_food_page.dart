import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Các thư viện khác nếu cần (ví dụ image_picker, firebase_storage)

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});
  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  // Giả sử em có thêm trường imageUrl
  final _imageUrlController = TextEditingController();

  String _selectedDiet = 'Mặn';
  final List<String> _dietOptions = ['Mặn', 'Chay', 'Ăn kiêng', 'Low-carb'];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // === CẬP NHẬT HÀM LƯU MÓN ĂN ===
  Future<void> _saveFood() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    // Kiểm tra xem người dùng đã đăng nhập chưa
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thực hiện chức năng này.'),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Tạo một document mới trong collection 'foods'
      await FirebaseFirestore.instance.collection('foods').add({
        'name': _nameController.text.trim(),
        'calories': int.tryParse(_caloriesController.text.trim()) ?? 0,
        'ingredients': _ingredientsController.text.trim(),
        'instructions': _instructionsController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
        'diet': _selectedDiet,
        'created_at': FieldValue.serverTimestamp(),
        // --- THÊM THÔNG TIN NGƯỜI ĐĂNG ---
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Không rõ tên',
        'authorPhotoURL': user.photoURL ?? '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm món ăn thành công!')),
        );
        Navigator.pop(context); // Quay về trang trước sau khi thêm thành công
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xảy ra lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm món ăn mới')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên món ăn'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Không được bỏ trống'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Lượng Calo (kcal)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? 'Không được bỏ trống'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              // Sửa chỗ deprecated: dùng initialValue thay cho value
              DropdownButtonFormField<String>(
                initialValue: _selectedDiet,
                decoration: const InputDecoration(labelText: 'Chế độ ăn'),
                items: _dietOptions
                    .map(
                      (diet) =>
                          DropdownMenuItem(value: diet, child: Text(diet)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDiet = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Nguyên liệu (cách nhau bởi dấu phẩy)',
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Không được bỏ trống'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Các bước thực hiện',
                ),
                maxLines: 5,
                validator: (value) => value == null || value.isEmpty
                    ? 'Không được bỏ trống'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveFood,
                icon: _isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Lưu món ăn'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
