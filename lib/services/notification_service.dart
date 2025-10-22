import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> addFollowNotification({required String targetUid}) async {
    final actor = _auth.currentUser;
    if (actor == null) throw Exception('Bạn cần đăng nhập');
    if (actor.uid == targetUid) return; // không tự thông báo cho mình

    final actorSnap = await _db.collection('users').doc(actor.uid).get();
    final actorData = actorSnap.data() ?? {};

    await _db
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .add({
          'type': 'follow',
          'actorId': actor.uid,
          'actorName': actorData['displayName'] ?? '',
          'actorPhotoURL': actorData['photoURL'] ?? '',
          'targetId': targetUid,
          'title': '${actorData['displayName'] ?? 'Ai đó'} đã theo dõi bạn',
          'body': '',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
  }

  Future<void> addLikeNotification({
    required String targetUid,
    required String foodId,
    String? foodImageUrl,
  }) async {
    final actor = _auth.currentUser;
    if (actor == null) throw Exception('Bạn cần đăng nhập');
    if (actor.uid == targetUid) return;

    final actorSnap = await _db.collection('users').doc(actor.uid).get();
    final actorData = actorSnap.data() ?? {};

    await _db
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .add({
          'type': 'like',
          'actorId': actor.uid,
          'actorName': actorData['displayName'] ?? '',
          'actorPhotoURL': actorData['photoURL'] ?? '',
          'targetId': targetUid,
          'foodId': foodId,
          'foodImageUrl': foodImageUrl ?? '',
          'title':
              '${actorData['displayName'] ?? 'Ai đó'} đã thích bài viết của bạn',
          'body': '',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
  }

  Future<int> unreadCountOnce() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final agg = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .count()
          .get();
      return agg.count ?? 0;
    } catch (_) {
      final qs = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();
      return qs.docs.length;
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchOnce({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    final uid = _uid;
    if (uid == null) throw Exception('Bạn cần đăng nhập');
    Query<Map<String, dynamic>> q = _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    return q.get();
  }

  Future<void> markAsRead(String notiId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notiId)
        .set({'read': true}, SetOptions(merge: true));
  }

  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;
    final qs = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final d in qs.docs) {
      batch.set(d.reference, {'read': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
