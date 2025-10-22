import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // A có đang theo dõi B không? (đọc một lần)
  Future<bool> isFollowingOnce(String targetUid) async {
    final uid = _uid;
    if (uid == null) return false;
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid)
        .get();
    return snap.exists;
  }

  // Theo dõi B (ghi 2 chiều)
  Future<void> follow(String targetUid) async {
    final uid = _uid;
    if (uid == null) throw Exception('Bạn cần đăng nhập');
    if (uid == targetUid) return;

    final batch = _db.batch();
    final followerRef = _db
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(uid);
    final followingRef = _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid);

    batch.set(followerRef, {'createdAt': FieldValue.serverTimestamp()});
    batch.set(followingRef, {'createdAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  // Hủy theo dõi B (xóa 2 chiều)
  Future<void> unfollow(String targetUid) async {
    final uid = _uid;
    if (uid == null) throw Exception('Bạn cần đăng nhập');
    if (uid == targetUid) return;

    final batch = _db.batch();
    final followerRef = _db
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(uid);
    final followingRef = _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid);

    batch.delete(followerRef);
    batch.delete(followingRef);
    await batch.commit();
  }

  // Đếm followers của user X (đọc một lần, ưu tiên Aggregation)
  Future<int> followersCountOnce(String uid) async {
    try {
      final agg = await _db
          .collection('users')
          .doc(uid)
          .collection('followers')
          .count()
          .get();
      return agg.count ?? 0; // FIX: đảm bảo trả về int, không phải int?
    } catch (_) {
      final qs = await _db
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();
      return qs.docs.length;
    }
  }

  // Đếm following của user X (đọc một lần, ưu tiên Aggregation)
  Future<int> followingCountOnce(String uid) async {
    try {
      final agg = await _db
          .collection('users')
          .doc(uid)
          .collection('following')
          .count()
          .get();
      return agg.count ?? 0; // FIX: đảm bảo trả về int, không phải int?
    } catch (_) {
      final qs = await _db
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();
      return qs.docs.length;
    }
  }
}
