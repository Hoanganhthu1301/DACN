import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _image;
  File? _video;
  bool _loading = false;

  // --- Thêm biến cho chế độ ăn ---
  String _diet = 'Mặn';
  final List<String> _dietOptions = ['Mặn', 'Chay', 'Ăn kiêng', 'Low-carb'];

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _video = File(picked.path));
  }

  Future<void> _saveFood() async {
    if (_name.text.isEmpty || _cal.text.isEmpty) return;
    setState(() => _loading = true);

    try {
      String imageUrl = '';
      String videoUrl = '';

      if (_image != null) {
        final ref = FirebaseStorage.instance.ref('foods/images/${DateTime.now()}.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      if (_video != null) {
        final refVideo = FirebaseStorage.instance.ref('foods/videos/${DateTime.now()}.mp4');
        await refVideo.putFile(_video!);
        videoUrl = await refVideo.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('foods').add({
        'name': _name.text,
        'calories': int.parse(_cal.text),
        'ingredients': _ingredients.text,
        'instructions': _instructions.text,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'diet': _diet, // <-- lưu chế độ ăn
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

            // --- Dropdown chế độ ăn ---
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
            _image != null
                ? Image.file(_image!, width: 120, height: 120, fit: BoxFit.cover)
                : const Text('Chưa chọn ảnh'),
            TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Chọn ảnh')),

            _video != null
                ? const Text('Đã chọn video hướng dẫn ✅')
                : const Text('Chưa chọn video'),
            TextButton.icon(onPressed: _pickVideo, icon: const Icon(Icons.video_library), label: const Text('Chọn video')),

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
