import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class FoodDetailScreen extends StatefulWidget {
  final String foodId;
  const FoodDetailScreen({super.key, required this.foodId});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  VideoPlayerController? _videoController;
  String instructions = '';

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _setupVideo(String videoUrl) {
    if (videoUrl.isNotEmpty) {
      _videoController ??= VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
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

          final data = snapshot.data!.data()!;
          final imageUrl = data['image_url'] ?? '';
          final name = data['name'] ?? '';
          final calories = data['calories']?.toString() ?? '0';
          final diet = data['diet'] ?? '';
          final videoUrl = data['video_url'] ?? '';
          final ingredients = data['ingredients'] ?? '';

          // --- Hướng dẫn nấu ---
          final instrData = data['instructions'];
          if (instrData != null) {
            if (instrData is String) {
              instructions = instrData;
            } else if (instrData is List<dynamic>) {
              instructions = instrData.join("\n");
            }
          }

          // --- Setup video lần đầu ---
          if (_videoController == null && videoUrl.isNotEmpty) {
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
                    ? Image.network(imageUrl,
                        width: double.infinity, height: 240, fit: BoxFit.cover)
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.fastfood, size: 80),
                      ),
                const SizedBox(height: 12),

                // Thông tin món ăn
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Calo: $calories kcal"),
                      if (diet.isNotEmpty) Text("Chế độ ăn: $diet"),
                      const SizedBox(height: 16),

                      // Nguyên liệu
                      const Text("Nguyên liệu:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        ingredients,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      // Hướng dẫn nấu
                      const Text("Hướng dẫn nấu:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        instructions.isNotEmpty
                            ? instructions
                            : "Chưa có hướng dẫn.",
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Video
                if (_videoController != null &&
                    _videoController!.value.isInitialized)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!)),
                        VideoProgressIndicator(_videoController!,
                            allowScrubbing: true),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.replay_10),
                                onPressed: () => _seekBy(const Duration(seconds: -10))),
                            IconButton(
                                icon: Icon(_videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow),
                                onPressed: _togglePlayPause),
                            IconButton(
                                icon: const Icon(Icons.forward_10),
                                onPressed: () => _seekBy(const Duration(seconds: 10))),
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
