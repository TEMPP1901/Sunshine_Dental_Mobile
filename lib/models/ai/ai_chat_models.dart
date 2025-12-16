class AIChatRequest {
  final String message;
  final List<MessageHistory> history;

  AIChatRequest({required this.message, required this.history});

  Map<String, dynamic> toJson() => {
    'message': message,
    'history': history.map((e) => e.toJson()).toList(),
  };
}

class MessageHistory {
  final String role;
  final String content;

  MessageHistory({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ServiceSuggestion {
  final int id;
  final String name;
  final double price;
  final String duration;

  ServiceSuggestion({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
  });

  factory ServiceSuggestion.fromJson(Map<String, dynamic> json) {
    return ServiceSuggestion(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] ?? '',
    );
  }
}

class DoctorSuggestion {
  final int id;
  final String fullName;
  final String specialty;
  final String avatarUrl;

  DoctorSuggestion({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.avatarUrl,
  });

  factory DoctorSuggestion.fromJson(Map<String, dynamic> json) {
    return DoctorSuggestion(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      specialty: json['specialty'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }
}

class AIChatResponse {
  final String replyText;
  final List<ServiceSuggestion> suggestedServices;
  final List<DoctorSuggestion> suggestedDoctors;

  AIChatResponse({
    required this.replyText,
    required this.suggestedServices,
    required this.suggestedDoctors,
  });

  factory AIChatResponse.fromJson(Map<String, dynamic> json) {
    return AIChatResponse(
      replyText: json['replyText'] ?? '',
      suggestedServices:
          (json['suggestedServices'] as List?)
              ?.map((e) => ServiceSuggestion.fromJson(e))
              .toList() ??
          [],
      suggestedDoctors:
          (json['suggestedDoctors'] as List?)
              ?.map((e) => DoctorSuggestion.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// Model dùng riêng cho UI (để hiển thị List)
class ChatMessageUI {
  final String text;
  final bool isUser;
  final List<ServiceSuggestion>? services;
  final List<DoctorSuggestion>? doctors;

  ChatMessageUI({
    required this.text,
    required this.isUser,
    this.services,
    this.doctors,
  });
}
