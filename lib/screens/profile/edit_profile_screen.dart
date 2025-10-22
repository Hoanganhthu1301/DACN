import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _svc = ProfileService();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || me.uid != widget.userId) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      await _svc.uploadAvatar(user: me, image: File(picked.path));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật ảnh đại diện')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || me.uid != widget.userId) return;

    setState(() => _busy = true);
    try {
      await _svc.updateProfile(
        user: me,
        displayName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final isMe = me?.uid == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          IconButton(
            tooltip: 'Lưu',
            icon: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            onPressed: _busy || !isMe ? null : _save,
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _svc.userStream(widget.userId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? {};
          final photoURL = (data['photoURL'] ?? '') as String;
          final displayName = (data['displayName'] ?? '') as String;
          final bio = (data['bio'] ?? '') as String;

          if (_nameCtrl.text != displayName) _nameCtrl.text = displayName;
          if (_bioCtrl.text != bio) _bioCtrl.text = bio;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundImage: photoURL.isNotEmpty
                          ? NetworkImage(photoURL)
                          : null,
                      child: photoURL.isEmpty
                          ? const Icon(Icons.person, size: 48)
                          : null,
                    ),
                    if (isMe)
                      IconButton.filled(
                        onPressed: _busy ? null : _pickAndUploadAvatar,
                        icon: const Icon(Icons.camera_alt, size: 18),
                        tooltip: 'Đổi ảnh đại diện',
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  enabled: isMe && !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    hintText: 'Nhập tên hiển thị',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioCtrl,
                  enabled: isMe && !_busy,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Giới thiệu',
                    hintText: 'Mô tả ngắn về bạn...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 100), // chừa chỗ cho nút dưới
              ],
            ),
          );
        },
      ),
      // Nút Lưu lớn ở dưới cho dễ thấy
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton.icon(
            onPressed: _busy || !isMe ? null : _save,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: const Text('Lưu'),
          ),
        ),
      ),
    );
  }
}
