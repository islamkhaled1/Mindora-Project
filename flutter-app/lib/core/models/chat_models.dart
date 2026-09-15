/// Data models for Mindora AI Chatbot integration.
class ChatMessageModel {
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isFallback;
  final ChatSuggestion? suggestion;

  ChatMessageModel({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isFallback = false,
    this.suggestion,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role.toLowerCase() == 'user';
  bool get isAssistant => role.toLowerCase() == 'assistant';

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isFallback: json['isFallback'] as bool? ?? false,
    );
  }
}

class ChatRequestModel {
  final String message;
  final List<ChatMessageModel>? conversation;

  const ChatRequestModel({
    required this.message,
    this.conversation,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'message': message,
    };

    if (conversation != null && conversation!.isNotEmpty) {
      map['conversation'] = conversation!.map((m) => m.toJson()).toList();
    }

    return map;
  }
}

class ChatResponseModel {
  final String reply;
  final String role;
  final String model;
  final DateTime createdAtUtc;
  final bool isFallback;

  const ChatResponseModel({
    required this.reply,
    required this.role,
    required this.model,
    required this.createdAtUtc,
    required this.isFallback,
  });

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    return ChatResponseModel(
      reply: json['reply'] as String? ?? '',
      role: json['role'] as String? ?? 'assistant',
      model: json['model'] as String? ?? 'gemini-2.5-flash',
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isFallback: json['isFallback'] as bool? ?? false,
    );
  }
}

/// Structured suggestion model for AI chat activity recommendations matching `apply suggestion.png`.
class ChatSuggestion {
  final String title;
  final String domain;
  final String duration;
  final String description;

  const ChatSuggestion({
    required this.title,
    required this.domain,
    required this.duration,
    required this.description,
  });
}
