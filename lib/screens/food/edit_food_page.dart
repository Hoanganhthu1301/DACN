import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditFoodPage extends StatefulWidget {
  final String foodId;
  final dynamic data;
  const EditFoodPage({super.key, required this.foodId, required this.data});

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  late TextEditingController _name;
  late TextEditingController _cal;
  late TextEditingController _ingredients;
  late TextEditingController _instructions;

  File? _newImage;
  File? _newVideo;
  bool _loading = false;

  // Dropdown chế độ ăn
  String _diet = 'Mặn';
  final List<String> _dietOptions = ['Mặn', 'Chay', 'Ăn kiêng', 'Low-carb'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data['name']);
    _cal = TextEditingController(text: widget.data['calories'].toString());
    _ingredients = TextEditingController(text: widget.data['ingredients'] ?? '');
    _instructions = TextEditingController(text: widget.data['instructions'] ?? '');
    _diet = widget.data['diet'] ?? 'Mặn';
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _newImage = File(picked.path));
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _newVideo = File(picked.path));
  }

  Future<void> _updateFood() async {
    if (_name.text.isEmpty || _cal.text.isEmpty) return;
    setState(() => _loading = true);

    try {
      String imageUrl = widget.data['image_url'] ?? '';
      String videoUrl = widget.data['video_url'] ?? '';

      // Upload ảnh mới nếu có
      if (_newImage != null) {
        final refImage = FirebaseStorage.instance
            .ref('foods/images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await refImage.putFile(_newImage!);
        imageUrl = await refImage.getDownloadURL();
      }

      // Upload video mới nếu có
      if (_newVideo != null) {
        final refVideo = FirebaseStorage.instance
            .ref('foods/videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
        await refVideo.putFile(_newVideo!);
        videoUrl = await refVideo.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('foods').doc(widget.foodId).update({
        'name': _name.text,
        'calories': int.parse(_cal.text),
        'ingredients': _ingredients.text,
        'instructions': _instructions.text,
        'diet': _diet,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!')),
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
      appBar: AppBar(title: const Text('Sửa món ăn')),
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
              items: _dietOptions.map((diet) => DropdownMenuItem(
                value: diet,
                child: Text(diet),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _diet = val);
              },
            ),

            const SizedBox(height: 20),
            _newImage != null
                ? Image.file(_newImage!, width: 120, height: 120, fit: BoxFit.cover)
                : (widget.data['image_url'] != null
                    ? Image.network(widget.data['image_url'], width: 120, height: 120, fit: BoxFit.cover)
                    : const Text('Chưa có ảnh')),
            TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Chọn ảnh')),

            const SizedBox(height: 10),
            _newVideo != null
                ? const Text('Đã chọn video mới ✅')
                : (widget.data['video_url'] != null
                    ? const Text('Video hiện tại có sẵn ✅')
                    : const Text('Chưa có video')),
            TextButton.icon(onPressed: _pickVideo, icon: const Icon(Icons.video_library), label: const Text('Chọn video')),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _updateFood,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}
