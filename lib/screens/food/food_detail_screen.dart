import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Thêm import để điều hướng tới trang hồ sơ người đăng
import '../profile/profile_screen.dart';

class FoodDetailScreen extends StatefulWidget {
  final String foodId;

  const FoodDetailScreen({super.key, required this.foodId});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _getString(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết món ăn")),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('foods')
            .doc(widget.foodId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Không tìm thấy món ăn"));
          }

          final food = snapshot.data!.data()!;

          final imageUrl = _getString(food, ['image_url', 'imageUrl']);
          final videoUrl = _getString(food, ['video_url', 'videoUrl']);
          final name = _getString(food, ['name', 'title', 'foodName']);
          final calories = _getString(food, ['calories', 'kcal']);
          final diet = _getString(food, ['diet']);
          final ingredients = _getString(food, ['ingredients']);
          final instructions = _getString(food, ['instructions', 'steps']);

          // Thông tin người đăng (có fallback cho dữ liệu cũ)
          final authorId = _getString(food, [
            'authorId',
            'authorID',
            'author',
            'uid',
            'userId',
            'ownerId',
          ]);
          final authorNameFb = _getString(food, [
            'authorName',
            'ownerName',
            'userName',
            'displayName',
            'name',
          ]);
          final authorPhotoURLFb = _getString(food, [
            'authorPhotoURL',
            'ownerPhotoURL',
            'photoURL',
            'avatar',
          ]);

          // Khởi tạo video (chỉ khi có link)
          if (videoUrl.isNotEmpty && !_isVideoReady) {
            _videoController =
                VideoPlayerController.networkUrl(Uri.parse(videoUrl))
                  ..initialize().then((_) {
                    if (mounted) setState(() => _isVideoReady = true);
                  });
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Ảnh món ăn ---
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.fastfood, size: 80),
                      ),

                // --- Thông tin ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Không rõ tên' : name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Calo: ${calories.isEmpty ? '0' : calories} kcal",
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (diet.isNotEmpty)
                        Text(
                          "Chế độ ăn: $diet",
                          style: const TextStyle(fontSize: 16),
                        ),

                      const SizedBox(height: 12),

                      // --- Khu vực người đăng (bấm để vào profile nếu có authorId) ---
                      _AuthorSection(
                        authorId: authorId,
                        fallbackName: authorNameFb.isEmpty
                            ? 'Người dùng'
                            : authorNameFb,
                        fallbackPhotoURL: authorPhotoURLFb,
                      ),

                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),

                      // --- Nguyên liệu ---
                      const Text(
                        "Nguyên liệu:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ingredients.isEmpty ? 'Không có' : ingredients,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 20),

                      // --- Hướng dẫn ---
                      const Text(
                        "Hướng dẫn nấu:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        instructions.isEmpty
                            ? 'Không có hướng dẫn.'
                            : instructions,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // --- Video hướng dẫn ---
                if (videoUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "🎬 Video hướng dẫn:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isVideoReady && _videoController != null)
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        if (_isVideoReady && _videoController != null)
                          IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 40,
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuthorSection extends StatelessWidget {
  final String authorId;
  final String fallbackName;
  final String fallbackPhotoURL;

  const _AuthorSection({
    required this.authorId,
    required this.fallbackName,
    required this.fallbackPhotoURL,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu thiếu authorId (bài cũ), chỉ hiển thị fallback, không điều hướng
    if (authorId.isEmpty) {
      return Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: fallbackPhotoURL.isNotEmpty
                ? NetworkImage(fallbackPhotoURL)
                : null,
            child: fallbackPhotoURL.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fallbackName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Người đăng',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      );
    }

    // Có authorId: đọc users/{authorId} realtime để hiện đúng tên/ảnh và cho phép điều hướng
    final userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(authorId)
        .snapshots();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(userId: authorId)),
        );
      },
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDocStream,
        builder: (context, snap) {
          final data = snap.data?.data();
          final displayName = (data?['displayName'] ?? '').toString().trim();
          final photoURL = (data?['photoURL'] ?? '').toString().trim();

          final nameToShow = displayName.isNotEmpty
              ? displayName
              : fallbackName;
          final photoToShow = photoURL.isNotEmpty ? photoURL : fallbackPhotoURL;

          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: photoToShow.isNotEmpty
                    ? NetworkImage(photoToShow)
                    : null,
                child: photoToShow.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameToShow,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Người đăng',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right),
            ],
          );
        },
      ),
    );
  }
}
