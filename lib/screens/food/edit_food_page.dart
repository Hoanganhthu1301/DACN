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
  File? _newImage;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data['name']);
    _cal = TextEditingController(text: widget.data['calories'].toString());
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _newImage = File(picked.path));
  }

  Future<void> _updateFood() async {
    setState(() => _loading = true);
    try {
      String imageUrl = widget.data['image_url'];
      if (_newImage != null) {
        final ref = FirebaseStorage.instance.ref('foods/${DateTime.now()}.jpg');
        await ref.putFile(_newImage!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('foods').doc(widget.foodId).update({
        'name': _name.text,
        'calories': int.parse(_cal.text),
        'image_url': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sửa món ăn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên món')),
            TextField(controller: _cal, decoration: const InputDecoration(labelText: 'Calo')),
            const SizedBox(height: 20),
            _newImage != null
                ? Image.file(_newImage!, width: 100, height: 100)
                : Image.network(widget.data['image_url'], width: 100, height: 100),
            TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Đổi ảnh')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _updateFood,
              child: _loading ? const CircularProgressIndicator() : const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}
