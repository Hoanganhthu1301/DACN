import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _db.collection('users').doc(uid);

  /// Tạo hoặc cập nhật document người dùng dựa vào User object
  Future<void> ensureUserDoc(User user) async {
    final ref = userRef(user.uid);
    final snap = await ref.get();
    final now = FieldValue.serverTimestamp();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'bio': '',
        'createdAt': now,
        'updatedAt': now,
      });
    } else {
      await ref.set({
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'updatedAt': now,
      }, SetOptions(merge: true));
    }
  }

  /// Upload ảnh đại diện và cập nhật cả FirebaseAuth lẫn Firestore
  Future<String> uploadAvatar(User user, File image) async {
    final ref = _storage.ref('users/${user.uid}/avatar.jpg');
    await ref.putFile(image);
    final url = await ref.getDownloadURL();

    await userRef(user.uid).set({
      'photoURL': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.updatePhotoURL(url);
    return url;
  }
}
