import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/profile_screen.dart'; // import trang profile người đăng

class FoodDetailScreen extends StatefulWidget {
  final String foodId;
  const FoodDetailScreen({super.key, required this.foodId});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  String instructions = '';

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _setupVideo(String videoUrl) {
    if (_videoController == null && videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) setState(() => _isVideoReady = true);
        });
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      _videoController!.value.isPlaying
          ? _videoController!.pause()
          : _videoController!.play();
    });
  }

  void _seekBy(Duration offset) {
    if (_videoController == null) return;
    final pos = _videoController!.value.position;
    final dur = _videoController!.value.duration;
    var target = pos + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > dur) target = dur;
    _videoController!.seekTo(target);
  }

  void _changeSpeed(double delta) {
    if (_videoController == null) return;
    final curSpeed = _videoController!.value.playbackSpeed;
    _videoController!.setPlaybackSpeed((curSpeed + delta).clamp(0.25, 3.0));
    setState(() {}); // cập nhật text tốc độ
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
          final instrData = food['instructions'];
          if (instrData != null) {
            if (instrData is String) {
              instructions = instrData;
            } else if (instrData is List<dynamic>) {
              instructions = instrData.join("\n");
            }
          }

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

          if (videoUrl.isNotEmpty && !_isVideoReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _setupVideo(videoUrl);
            });
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh món ăn
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
                const SizedBox(height: 12),

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

                      // Người đăng
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

                      // Nguyên liệu
                      const Text(
                        "Nguyên liệu:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ingredients.isEmpty ? 'Không có' : ingredients,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 20),

                      // Hướng dẫn
                      const Text(
                        "Hướng dẫn nấu:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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

                // Video
                if (videoUrl.isNotEmpty && _videoController != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "🎬 Video hướng dẫn:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        VideoProgressIndicator(_videoController!,
                            allowScrubbing: true),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.replay_10),
                                onPressed: () =>
                                    _seekBy(const Duration(seconds: -10))),
                            IconButton(
                                icon: Icon(_videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow),
                                onPressed: _togglePlayPause),
                            IconButton(
                                icon: const Icon(Icons.forward_10),
                                onPressed: () =>
                                    _seekBy(const Duration(seconds: 10))),
                            IconButton(
                                icon: const Icon(Icons.fast_forward),
                                onPressed: () => _changeSpeed(0.25)),
                            IconButton(
                                icon: const Icon(Icons.fast_rewind),
                                onPressed: () => _changeSpeed(-0.25)),
                            Text(
                                '${_videoController!.value.playbackSpeed.toStringAsFixed(2)}x')
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
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
                    fontSize: 16, fontWeight: FontWeight.w600),
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

    final userDocStream =
        FirebaseFirestore.instance.collection('users').doc(authorId).snapshots();

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

          final nameToShow = displayName.isNotEmpty ? displayName : fallbackName;
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
                        fontSize: 16, fontWeight: FontWeight.w600),
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
