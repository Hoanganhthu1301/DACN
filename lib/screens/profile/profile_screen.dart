import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Import các màn hình liên quan
import '../food/food_detail_screen.dart';
import '../account/login_screen.dart';
// import 'edit_profile_screen.dart'; // Màn hình này em sẽ tạo sau

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Lấy UID của người dùng đang đăng nhập
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Hàm đăng xuất
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Sau khi đăng xuất, quay về màn hình đăng nhập và xóa hết các màn hình cũ
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      Fluttertoast.showToast(msg: "Đăng xuất thành công!");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem người dùng đang xem trang của chính mình hay không
    final bool isCurrentUser = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
        backgroundColor: Colors.orange,
        // Chỉ hiển thị nút sửa nếu là trang cá nhân của chính mình
        actions: [
          if (isCurrentUser)
            IconButton(
              tooltip: 'Chỉnh sửa trang cá nhân',
              icon: const Icon(Icons.edit_note_sharp),
              onPressed: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(userId: widget.userId)));
                Fluttertoast.showToast(msg: "Chức năng đang được phát triển!");
              },
            ),
        ],
      ),
      // Dùng StreamBuilder để lắng nghe thay đổi dữ liệu người dùng real-time
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy người dùng.'));
          }

          // Ép kiểu dữ liệu an toàn
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // --- Phần Header (ảnh đại diện, tên, thông số) ---
              _buildProfileHeader(context, userData, isCurrentUser),
              const Divider(height: 1, thickness: 1),
              // --- Phần danh sách bài viết ---
              _buildUserPostsGrid(context),
            ],
          );
        },
      ),
    );
  }

  /// Widget xây dựng phần thông tin đầu trang cá nhân
  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic> userData,
    bool isCurrentUser,
  ) {
    // URL ảnh đại diện mặc định nếu người dùng chưa có ảnh
    const defaultAvatarUrl =
        'https://static.vecteezy.com/system/resources/previews/009/734/564/original/default-avatar-profile-icon-of-social-media-user-vector.jpg';
    final photoURL = userData['photoURL'] ?? defaultAvatarUrl;

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
            userData['displayName'] ?? 'Tên người dùng',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            userData['email'] ?? '',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          // --- Phần thống kê ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Bài viết', 0), // Sẽ được cập nhật sau
              _buildStatColumn('Followers', userData['followerCount'] ?? 0),
              _buildStatColumn('Following', userData['followingCount'] ?? 0),
            ],
          ),
          const SizedBox(height: 20),
          // --- Phần nút bấm hành động ---
          isCurrentUser
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                )
              : ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Theo dõi'),
                  onPressed: () {
                    Fluttertoast.showToast(
                      msg: "Chức năng đang được phát triển!",
                    );
                  },
                ),
        ],
      ),
    );
  }

  /// Widget con cho từng cột thống kê (Bài viết, Followers, Following)
  Widget _buildStatColumn(String label, int number) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
      ],
    );
  }

  /// Widget xây dựng lưới hiển thị các bài đăng của người dùng
  Widget _buildUserPostsGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Truy vấn các món ăn có 'authorId' trùng với userId của trang cá nhân
      stream: FirebaseFirestore.instance
          .collection('foods')
          .where('authorId', isEqualTo: widget.userId)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Text(
                'Chưa có bài viết nào.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return GridView.builder(
          // shrinkWrap và physics để GridView nằm gọn trong ListView
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(2.0),
          itemCount: posts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Hiển thị 3 ảnh trên một hàng
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemBuilder: (context, index) {
            final postData = posts[index].data() as Map<String, dynamic>;
            final imageUrl = postData['image_url'];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodDetailScreen(foodId: posts[index].id),
                  ),
                );
              },
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      // Hiển thị loading khi tải ảnh
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(color: Colors.grey.shade200);
                      },
                      // Hiển thị icon lỗi nếu không tải được ảnh
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
                  // Widget mặc định nếu bài viết không có ảnh
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
            );
          },
        );
      },
    );
  }
}
