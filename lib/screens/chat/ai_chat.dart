import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import '../../services/openai_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final OpenAIService _openAIService = OpenAIService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({"isUser": true, "text": userMessage});
      _isLoading = true;
    });
    _controller.clear();

    await Future.delayed(const Duration(seconds: 2));
    final reply = await _openAIService.sendMessage(userMessage);

    setState(() {
      _messages.add({"isUser": false, "text": reply});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Tư Vấn Món Ăn')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return msg['isUser']
                    ? BubbleSpecialOne(
                        text: msg['text'],
                        isSender: true,
                        color: Colors.greenAccent,
                        textStyle: const TextStyle(color: Colors.black87),
                      )
                    : BubbleSpecialOne(
                        text: msg['text'],
                        isSender: false,
                        color: Colors.white,
                        textStyle: const TextStyle(color: Colors.black87),
                      );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Nhập câu hỏi hoặc món ăn...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
