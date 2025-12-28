class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
  });

  // Factory constructor to create a ChatMessage from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.user,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // Method to convert ChatMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum MessageType { user, ai, system }
