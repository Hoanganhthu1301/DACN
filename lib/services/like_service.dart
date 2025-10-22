import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<bool> isLikedStream(String foodId) {
    final uid = _uid;
    if (uid == null) return const Stream<bool>.empty();
    return _db
        .collection('food_likes')
        .doc(foodId)
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((d) => d.exists);
  }

  Stream<int> likesCount(String foodId) {
    return _db
        .collection('food_likes')
        .doc(foodId)
        .collection('users')
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> toggleLike(String foodId, bool currentlyLiked) async {
    final uid = _uid;
    if (uid == null) throw Exception('Bạn cần đăng nhập');
    final ref = _db
        .collection('food_likes')
        .doc(foodId)
        .collection('users')
        .doc(uid);
    if (currentlyLiked) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Stream<bool> isSavedStream(String foodId) {
    final uid = _uid;
    if (uid == null) return const Stream<bool>.empty();
    return _db
        .collection('user_saves')
        .doc(uid)
        .collection('foods')
        .doc(foodId)
        .snapshots()
        .map((d) => d.exists);
  }

  Future<void> toggleSave(String foodId, bool currentlySaved) async {
    final uid = _uid;
    if (uid == null) throw Exception('Bạn cần đăng nhập');
    final ref = _db
        .collection('user_saves')
        .doc(uid)
        .collection('foods')
        .doc(foodId);
    if (currentlySaved) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }
}
