class ChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;
  final bool isSentByMe;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.isSentByMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isSentByMe: json['isSentByMe'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isSentByMe': isSentByMe,
    };
  }
}
