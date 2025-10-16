import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

Future<void> _loadVideo(String url) async {
  if (url.isEmpty) return;

  _videoController = VideoPlayerController.networkUrl(Uri.parse(url));

  await _videoController!.initialize();
  setState(() => _isVideoReady = true);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết món ăn"), backgroundColor: Colors.green),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('foods').doc(widget.foodId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Không tìm thấy món ăn"));
          }

          final food = snapshot.data!.data() as Map<String, dynamic>;
          final imageUrl = food['image_url'] ?? '';
          final videoUrl = food['video_url'] ?? '';
          debugPrint(" Video URL Firestore: $videoUrl"); 
          final name = food['name'] ?? 'Không rõ tên';
          final calories = food['calories']?.toString() ?? '0';
          final diet = food['diet'] ?? 'Không xác định';
          final ingredients = food['ingredients'] ?? 'Không có';
          final instructions = food['instructions'] ?? 'Không có hướng dẫn.';

          // ✅ Chỉ khởi tạo video 1 lần duy nhất
          if (videoUrl.isNotEmpty && _videoController == null) {
            _loadVideo(videoUrl);
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
                      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Calo: $calories kcal", style: const TextStyle(fontSize: 16)),
                      Text("Chế độ ăn: $diet", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),

                      const Text("Nguyên liệu:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(ingredients, style: const TextStyle(fontSize: 16, height: 1.4)),
                      const SizedBox(height: 20),

                      const Text("Hướng dẫn nấu:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(instructions, style: const TextStyle(fontSize: 16, height: 1.4)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // --- Video hướng dẫn ---
                if (videoUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const Text("Video hướng dẫn:",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        if (_isVideoReady && _videoController != null)
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                VideoPlayer(_videoController!),
                                VideoProgressIndicator(_videoController!, allowScrubbing: true),
                                Center(
                                  child: IconButton(
                                    iconSize: 50,
                                    color: Colors.white,
                                    icon: Icon(
                                      _videoController!.value.isPlaying
                                          ? Icons.pause_circle
                                          : Icons.play_circle,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (_videoController!.value.isPlaying) {
                                          _videoController!.pause();
                                        } else {
                                          _videoController!.play();
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Center(child: CircularProgressIndicator()),
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
