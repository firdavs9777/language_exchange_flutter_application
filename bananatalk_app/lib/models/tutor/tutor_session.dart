// DTOs matching the backend AITutorSession shape (see
// `models/AITutorSession.js`). Card payloads stay as raw `Map`s here
// — the card widgets each parse their own payload shape.

class TutorMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final String messageType; // 'text' | 'quiz_card' | 'vocab_card' | 'grammar_card'
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  TutorMessage({
    required this.role,
    required this.content,
    required this.messageType,
    required this.payload,
    required this.createdAt,
  });

  factory TutorMessage.fromJson(Map<String, dynamic> j) => TutorMessage(
        role: j['role']?.toString() ?? 'assistant',
        content: j['content']?.toString() ?? '',
        messageType: j['messageType']?.toString() ?? 'text',
        payload: j['payload'] is Map
            ? Map<String, dynamic>.from(j['payload'] as Map)
            : null,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class TutorSession {
  final String id;
  final String persona;
  final List<TutorMessage> messages;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? summary;

  TutorSession({
    required this.id,
    required this.persona,
    required this.messages,
    required this.startedAt,
    required this.endedAt,
    required this.summary,
  });

  factory TutorSession.fromJson(Map<String, dynamic> j) => TutorSession(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        persona: j['persona']?.toString() ?? 'nana',
        messages: ((j['messages'] as List?) ?? const [])
            .map((e) => TutorMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        startedAt:
            DateTime.tryParse(j['startedAt']?.toString() ?? '') ?? DateTime.now(),
        endedAt: j['endedAt'] != null
            ? DateTime.tryParse(j['endedAt'].toString())
            : null,
        summary: j['summary'] as String?,
      );
}
