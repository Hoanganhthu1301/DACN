import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Liên quan đến bài viết của user (bấm vào ảnh mở chi tiết)
import '../food/food_detail_screen.dart';
// Màn chỉnh sửa hồ sơ
import 'edit_profile_screen.dart';
// Màn hình đăng nhập để điều hướng sau khi logout
import '../account/login_screen.dart';
// Follow service (one-shot)
import '../../services/follow_service.dart';
import '../../services/fcm_token_service.dart';

// ✅ import thêm trang chỉnh sửa món ăn
import '../food/edit_food_page.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  final _followSvc = FollowService();

  bool _loadingStats = true;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;

  bool _loadingPosts = true;
  List<QueryDocumentSnapshot> _posts = [];

  bool _loadingUser = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _logout() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me != null) {
      try {
        await FcmTokenService().unlinkAndDeleteToken();
      } catch (_) {}
    }
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã đăng xuất')));
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadUser(), _loadStats(), _loadPosts()]);
  }

  Future<void> _loadUser() async {
    setState(() => _loadingUser = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      _userData = snap.data();
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final following = await _followSvc.isFollowingOnce(widget.userId);
      final followersCount = await _followSvc.followersCountOnce(widget.userId);
      final followingCount = await _followSvc.followingCountOnce(widget.userId);

      int postsCount = _posts.isNotEmpty ? _posts.length : 0;
      try {
        final agg = await FirebaseFirestore.instance
            .collection('foods')
            .where('authorId', isEqualTo: widget.userId)
            .count()
            .get();
        postsCount = (agg.count ?? 0);
      } catch (_) {
        if (postsCount == 0) {
          final qs = await FirebaseFirestore.instance
              .collection('foods')
              .where('authorId', isEqualTo: widget.userId)
              .get();
          postsCount = qs.docs.length;
        }
      }

      _isFollowing = following;
      _followersCount = followersCount;
      _followingCount = followingCount;
      _postsCount = postsCount;
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final qs = await FirebaseFirestore.instance
          .collection('foods')
          .where('authorId', isEqualTo: widget.userId)
          .orderBy('created_at', descending: true)
          .get();
      _posts = qs.docs;
    } finally {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  // ✅ Thêm hàm xóa món ăn
  Future<void> _deleteFood(String foodId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa món ăn'),
        content: const Text('Bạn có chắc chắn muốn xóa món ăn này không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('foods').doc(foodId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã xóa món ăn')),
      );
      await _loadPosts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
        backgroundColor: Colors.orange,
        actions: [
          if (isCurrentUser)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(userId: widget.userId),
                    ),
                  );
                  if (!context.mounted) return;
                  await _loadUser();
                } else if (value == 'logout') {
                  await _logout();
                }
              },
              itemBuilder: (BuildContext context) => const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Chỉnh sửa'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (_loadingUser)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_userData == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Không tìm thấy người dùng.')),
              )
            else
              _buildProfileHeader(context, _userData!, isCurrentUser),

            const Divider(height: 1, thickness: 1),

            if (_loadingPosts)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_posts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'Chưa có bài viết nào.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(2.0),
                itemCount: _posts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemBuilder: (context, index) {
                  final postData = _posts[index].data() as Map<String, dynamic>;
                  final imageUrl = (postData['image_url'] ?? '') as String;
                  final foodId = _posts[index].id;
                  final isOwner = currentUserId == postData['authorId'];

                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodDetailScreen(foodId: foodId),
                            ),
                          );
                        },
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(color: Colors.grey.shade200);
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.grey,
                                ),
                              ),
                      ),

                      // ✅ Nút sửa / xóa chỉ hiện khi là chủ món ăn
                      if (isOwner)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditFoodPage(
                                      foodId: foodId,
                                      data: postData,
                                    ),
                                  ),
                                );
                                await _loadPosts();
                              } else if (value == 'delete') {
                                _deleteFood(foodId);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: 'edit', child: Text('✏️ Sửa')),
                              PopupMenuItem(
                                  value: 'delete', child: Text('🗑️ Xóa')),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic> userData,
    bool isCurrentUser,
  ) {
    const defaultAvatarUrl =
        'https://static.vecteezy.com/system/resources/previews/009/734/564/original/default-avatar-profile-icon-of-social-media-user-vector.jpg';
    final photoURL = (userData['photoURL'] ?? defaultAvatarUrl) as String;
    final displayName = (userData['displayName'] ?? 'Tên người dùng') as String;
    final email = (userData['email'] ?? '') as String;
    final bio = (userData['bio'] ?? '').toString().trim();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(photoURL),
            backgroundColor: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          if (email.isNotEmpty)
            Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 10),
          Text(
            bio.isNotEmpty ? bio : 'Chưa có giới thiệu',
            style: TextStyle(
              fontSize: 14,
              color: bio.isNotEmpty ? Colors.black87 : Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _loadingStats
                  ? const _StatSkeleton()
                  : _Stat(label: 'Bài viết', number: _postsCount),
              _loadingStats
                  ? const _StatSkeleton()
                  : _Stat(label: 'Followers', number: _followersCount),
              _loadingStats
                  ? const _StatSkeleton()
                  : _Stat(label: 'Following', number: _followingCount),
            ],
          ),
          const SizedBox(height: 20),
          if (!isCurrentUser)
            ElevatedButton.icon(
              icon: Icon(_isFollowing ? Icons.check : Icons.person_add),
              label: Text(_isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
              onPressed: uid == null
                  ? null
                  : () async {
                      try {
                        if (_isFollowing) {
                          await _followSvc.unfollow(widget.userId);
                        } else {
                          await _followSvc.follow(widget.userId);
                        }
                        await _loadStats();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isFollowing ? Colors.grey.shade300 : Colors.orange,
                foregroundColor:
                    _isFollowing ? Colors.black87 : Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int number;
  const _Stat({required this.label, required this.number});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$number',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
      ],
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 24, height: 18, color: Colors.grey.shade300),
        const SizedBox(height: 4),
        Container(width: 60, height: 14, color: Colors.grey.shade300),
      ],
    );
  }
}
