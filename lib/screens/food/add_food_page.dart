import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

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

  String _selectedDiet = 'Mặn';
  final List<String> _dietOptions = ['Mặn', 'Chay', 'Ăn kiêng', 'Low-carb'];

  bool _isLoading = false;
  File? _imageFile;
  File? _videoFile;
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ==== Chọn ảnh ====
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // ==== Chọn video ====
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });

      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    }
  }

  // ==== Upload file lên Firebase Storage ====
  Future<String?> _uploadFile(File file, String folder) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('foods/$folder/${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi upload: $e')));
      return null;
    }
  }

  // ==== Lưu món ăn ====
  Future<void> _saveFood() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm món ăn')),
      );
      setState(() => _isLoading = false);
      return;
    }

    String? imageUrl;
    String? videoUrl;

    if (_imageFile != null) {
      imageUrl = await _uploadFile(_imageFile!, 'images');
    }
    if (_videoFile != null) {
      videoUrl = await _uploadFile(_videoFile!, 'videos');
    }

    try {
      await FirebaseFirestore.instance.collection('foods').add({
        'name': _nameController.text.trim(),
        'calories': int.tryParse(_caloriesController.text.trim()) ?? 0,
        'ingredients': _ingredientsController.text.trim(),
        'instructions': _instructionsController.text.trim(),
        'diet': _selectedDiet,
        'image_url': imageUrl ?? '',
        'video_url': videoUrl ?? '',
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Không rõ tên',
        'authorPhotoURL': user.photoURL ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm món ăn thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              // === Nhập thông tin món ăn ===
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên món ăn'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Không được bỏ trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Lượng calo (kcal)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Không được bỏ trống' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDiet,
                decoration: const InputDecoration(labelText: 'Chế độ ăn'),
                items: _dietOptions
                    .map((diet) => DropdownMenuItem(value: diet, child: Text(diet)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDiet = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                    labelText: 'Nguyên liệu (cách nhau bởi dấu phẩy)'),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Không được bỏ trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration:
                    const InputDecoration(labelText: 'Các bước thực hiện'),
                maxLines: 5,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Không được bỏ trống' : null,
              ),
              const SizedBox(height: 24),

              // === Ảnh đã chọn ===
              if (_imageFile != null)
                Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
              const SizedBox(height: 8),

              // === Video đã chọn ===
              if (_videoFile != null)
                _videoController != null &&
                        _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const CircularProgressIndicator(),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Chọn ảnh'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Chọn video'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveFood,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(color: Colors.white))
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
