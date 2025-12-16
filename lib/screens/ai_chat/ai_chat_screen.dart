import 'package:flutter/material.dart';
import '../../models/ai/ai_chat_models.dart';
import '../../services/ai/ai_service.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/service_suggestion_card.dart';
import 'widgets/doctor_suggestion_card.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();

  final List<ChatMessageUI> _messages = [
    ChatMessageUI(
      text:
          "Chào bạn! 👋 Mình là trợ lý ảo Sunshine. Mình giúp gì được cho bạn?",
      isUser: false,
    ),
  ];

  bool _isLoading = false;

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessageUI(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    // Convert UI models to API models
    List<MessageHistory> history = _messages
        .where((m) => m.text.isNotEmpty)
        .map(
          (m) => MessageHistory(
            role: m.isUser ? 'user' : 'model',
            content: m.text,
          ),
        )
        .toList();

    try {
      final response = await _aiService.sendMessage(text, history);

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessageUI(
              text: response.replyText,
              isUser: false,
              services: response.suggestedServices,
              doctors: response.suggestedDoctors,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        // Hiện lỗi trực tiếp lên màn hình chat để dễ nhận biết
        setState(() {
          _messages.add(
            ChatMessageUI(
              text: "⚠️ Có lỗi xảy ra: ${e.toString()}",
              isUser: false,
            ),
          );
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: ${e.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- Logic điều hướng (Navigation) ---
  void _navigateToBookingService(int serviceId) {
    debugPrint("Navigating to Booking with Service ID: $serviceId");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Đặt dịch vụ ID: $serviceId")));
  }

  void _navigateToBookingDoctor(int doctorId) {
    debugPrint("Navigating to Booking with Doctor ID: $doctorId");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Đặt bác sĩ ID: $doctorId")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text(
              "Trợ lý Sunshine",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          // 1. Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Text Bubble
                    ChatBubble(text: msg.text, isUser: msg.isUser),

                    // Service Suggestions
                    if (!msg.isUser && msg.services != null)
                      ...msg.services!.map(
                        (s) => ServiceSuggestionCard(
                          service: s,
                          onTap: () => _navigateToBookingService(s.id),
                        ),
                      ),

                    // Doctor Suggestions
                    if (!msg.isUser && msg.doctors != null)
                      ...msg.doctors!.map(
                        (d) => DoctorSuggestionCard(
                          doctor: d,
                          onTap: () => _navigateToBookingDoctor(d.id),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // 2. Loading Indicator (Hiển thị khi đang chờ)
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Sunshine đang trả lời...",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Nhập câu hỏi của bạn...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _handleSendMessage,
                    mini: true,
                    elevation: 1,
                    backgroundColor: Colors.blue[600],
                    child: _isLoading
                        ? const SizedBox() // Ẩn icon khi loading
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
