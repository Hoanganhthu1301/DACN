import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

/// CommentSection widget
/// - Shows paginated comments for a given foodId (initialLimit, load more)
/// - Post new comment to collection 'comments'
/// - Delete own comment
class CommentSection extends StatefulWidget {
  final String foodId;
  final int pageSize;

  const CommentSection({super.key, required this.foodId, this.pageSize = 10});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _listController = ScrollController();

  List<DocumentSnapshot<Map<String, dynamic>>> _docs = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  String? _uid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadInitial();
    // Optional: listen for new comments (most recent ones) and insert if they arrive
    _startRealtimeNewCommentsListener();
  }

  @override
  void didUpdateWidget(covariant CommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.foodId != widget.foodId) {
      _resetAndLoad();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _listController.dispose();
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _resetAndLoad() async {
    setState(() {
      _docs = [];
      _lastDoc = null;
      _hasMore = true;
    });
    await _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final q = _db
          .collection('comments')
          .where('foodId', isEqualTo: widget.foodId)
          .orderBy('createdAt', descending: true)
          .limit(widget.pageSize);
      final snap = await q.get();
      _docs = snap.docs.cast<DocumentSnapshot<Map<String, dynamic>>>();
      _lastDoc = _docs.isNotEmpty ? _docs.last : null;
      // If less than pageSize => no more
      _hasMore = snap.docs.length == widget.pageSize;
    } catch (e) {
      debugPrint('loadInitial comments error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải bình luận: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _lastDoc == null) return;
    setState(() => _loadingMore = true);
    try {
      final q = _db
          .collection('comments')
          .where('foodId', isEqualTo: widget.foodId)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(widget.pageSize);
      final snap = await q.get();
      final newDocs = snap.docs.cast<DocumentSnapshot<Map<String, dynamic>>>();
      _docs.addAll(newDocs);
      _lastDoc = newDocs.isNotEmpty ? newDocs.last : _lastDoc;
      _hasMore = newDocs.length == widget.pageSize;
    } catch (e) {
      debugPrint('loadMore comments error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải thêm bình luận: $e')));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _postComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để bình luận')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final authorName = user.displayName ?? user.email ?? 'Người dùng';
      final ref = await _db.collection('comments').add({
        'foodId': widget.foodId,
        'text': text,
        'authorId': user.uid,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Read created doc once to get timestamp resolved (best-effort)
      final createdDoc = await ref.get();
      // Insert on top of list
      setState(() {
        _docs.insert(0, createdDoc);
        // if we exceed pageSize and we previously had exactly pageSize, we keep hasMore true
      });
      _controller.clear();
      // Optionally scroll to top of comment list
      if (_listController.hasClients) {
        _listController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('postComment error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gửi bình luận thất bại: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteComment(String docId, String authorId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (user.uid != authorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền xóa bình luận này')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa bình luận này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _db.collection('comments').doc(docId).delete();
      setState(() {
        _docs.removeWhere((d) => d.id == docId);
      });
    } catch (e) {
      debugPrint('deleteComment error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
    }
  }

  /// Optional: listen for new comments in realtime (only newest few)
  void _startRealtimeNewCommentsListener() {
    // Listen for very recent comments (e.g., created in last minute) and add them to top if not already present.
    // This is optional and lightweight; adjust query as desired.
    try {
      _realtimeSub = _db
          .collection('comments')
          .where('foodId', isEqualTo: widget.foodId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots()
          .listen((snap) {
            if (snap.docs.isEmpty) return;
            final newest = snap.docs.first;
            if (_docs.isEmpty || _docs.first.id != newest.id) {
              setState(() {
                _docs.insert(
                  0,
                  newest as DocumentSnapshot<Map<String, dynamic>>,
                );
                // if duplicates occur later they will be filtered when building UI
              });
            }
          });
    } catch (e) {
      debugPrint('realtime comments listener error: $e');
    }
  }

  Future<void> _refresh() async {
    await _resetAndLoadForRefresh();
  }

  Future<void> _resetAndLoadForRefresh() async {
    setState(() {
      _docs = [];
      _lastDoc = null;
      _hasMore = true;
    });
    await _loadInitial();
  }

  Widget _buildCommentItem(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final text = data['text'] ?? '';
    final authorName = data['authorName'] ?? 'Người dùng';
    final authorId = data['authorId'] ?? '';
    final ts = data['createdAt'];
    DateTime time;
    if (ts is Timestamp) {
      time = ts.toDate();
    } else if (ts is Map && ts['_seconds'] != null) {
      time = DateTime.fromMillisecondsSinceEpoch(
        (ts['_seconds'] as int) * 1000,
      );
    } else {
      time = DateTime.now();
    }
    final timeStr = timeago.format(
      time,
      locale: 'vi',
    ); // 'vi' if you added vi messages, otherwise default en

    final isOwner = authorId == _uid;

    return ListTile(
      title: Text(
        authorName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(text),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                timeStr,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              if (isOwner)
                GestureDetector(
                  onTap: () => _deleteComment(doc.id, authorId),
                  child: const Text(
                    'Xóa',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Comments list area with pull-to-refresh
        Container(
          constraints: const BoxConstraints(minHeight: 80, maxHeight: 360),
          child: _loading && _docs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    controller: _listController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _docs.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index < _docs.length) {
                        final doc = _docs[index];
                        return _buildCommentItem(doc);
                      } else {
                        // Load more button/footer
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Center(
                            child: _loadingMore
                                ? const CircularProgressIndicator()
                                : TextButton(
                                    onPressed: _loadMore,
                                    child: const Text('Xem thêm bình luận'),
                                  ),
                          ),
                        );
                      }
                    },
                  ),
                ),
        ),

        const Divider(height: 1),

        // Input area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Viết bình luận...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _loading
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _postComment,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
