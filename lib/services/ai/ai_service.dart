import 'dart:convert';
import 'package:flutter/material.dart'; // Để dùng debugPrint
import 'package:http/http.dart' as http;
import '../../models/ai/ai_chat_models.dart';

class AIService {
  // ✅ Đã cập nhật theo log của bạn
  static const String baseUrl = 'http://192.168.100.232:8080';

  Future<AIChatResponse> sendMessage(
    String message,
    List<MessageHistory> history,
  ) async {
    final url = Uri.parse('$baseUrl/api/public/ai/chat');

    // Log để kiểm tra xem app có gọi đúng URL không
    debugPrint('--> POST AI Chat: $url');

    // Logic cắt bớt lịch sử
    final limitedHistory = history.length > 6
        ? history.sublist(history.length - 6)
        : history;

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type':
                  'application/json; charset=UTF-8', // Thêm UTF-8 để hỗ trợ tiếng Việt
            },
            body: jsonEncode(
              AIChatRequest(message: message, history: limitedHistory).toJson(),
            ),
          )
          .timeout(const Duration(seconds: 30)); // Timeout sau 30s

      debugPrint('<-- Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Decode UTF-8 chuẩn
        final decodedBody = utf8.decode(response.bodyBytes);
        debugPrint(
          '<-- AI Response: $decodedBody',
        ); // In kết quả ra log để debug
        return AIChatResponse.fromJson(jsonDecode(decodedBody));
      } else {
        debugPrint('❌ Server Error: ${response.body}');
        throw Exception('Lỗi máy chủ: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Connection Error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
