import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String role;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'text': text,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static ChatMessage fromJson(Map<String, Object?> json) {
    return ChatMessage(
      id: (json['id'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'assistant',
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
