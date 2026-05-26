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
  final String mode; // 'free' | 'roleplay'
  final String? scenarioId;
  final List<TutorMessage> messages;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? summary;
  final ScenarioScore? scenarioScore;

  TutorSession({
    required this.id,
    required this.persona,
    this.mode = 'free',
    this.scenarioId,
    required this.messages,
    required this.startedAt,
    this.endedAt,
    this.summary,
    this.scenarioScore,
  });

  factory TutorSession.fromJson(Map<String, dynamic> j) => TutorSession(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        persona: j['persona']?.toString() ?? 'nana',
        mode: j['mode']?.toString() ?? 'free',
        scenarioId: j['scenarioId']?.toString(),
        messages: ((j['messages'] as List?) ?? const [])
            .map((e) => TutorMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        startedAt:
            DateTime.tryParse(j['startedAt']?.toString() ?? '') ?? DateTime.now(),
        endedAt: j['endedAt'] != null
            ? DateTime.tryParse(j['endedAt'].toString())
            : null,
        summary: j['summary'] as String?,
        scenarioScore: j['scenarioScore'] is Map
            ? ScenarioScore.fromJson(
                Map<String, dynamic>.from(j['scenarioScore'] as Map))
            : null,
      );
}

class TutorScenario {
  final String id;
  final String emoji;
  final String title;
  final String summary;
  final String goal;
  final String level; // 'A1' | 'A2' | 'B1' | 'B2' | 'C1'
  final int minTurns;

  TutorScenario({
    required this.id,
    required this.emoji,
    required this.title,
    required this.summary,
    required this.goal,
    required this.level,
    required this.minTurns,
  });

  factory TutorScenario.fromJson(Map<String, dynamic> j) => TutorScenario(
        id: j['id']?.toString() ?? '',
        emoji: j['emoji']?.toString() ?? '🎭',
        title: j['title']?.toString() ?? '',
        summary: j['summary']?.toString() ?? '',
        goal: j['goal']?.toString() ?? '',
        level: (j['level']?.toString() ?? 'A2').toUpperCase(),
        minTurns: (j['minTurns'] as num?)?.toInt() ?? 4,
      );
}

/// User context returned alongside the scenarios list so the picker can
/// render a guide header (level + target language) and group by relative
/// difficulty.
class ScenariosUserContext {
  final String level; // 'A1' | 'A2' | 'B1' | 'B2' | 'C1'
  final String? targetLanguage;
  final String? nativeLanguage;
  const ScenariosUserContext({
    required this.level,
    this.targetLanguage,
    this.nativeLanguage,
  });
  factory ScenariosUserContext.fromJson(Map<String, dynamic> j) =>
      ScenariosUserContext(
        level: (j['level']?.toString() ?? 'A1').toUpperCase(),
        targetLanguage: j['targetLanguage']?.toString(),
        nativeLanguage: j['nativeLanguage']?.toString(),
      );
}

/// Bundle returned by `listScenarios()` so the picker has scenarios + the
/// user's context in a single fetch.
class ScenariosResponse {
  final List<TutorScenario> scenarios;
  final ScenariosUserContext userContext;
  const ScenariosResponse({required this.scenarios, required this.userContext});
}

class ScenarioScore {
  final int score; // 0-100
  final List<bool> criteriaMet;
  final String feedback;
  ScenarioScore({required this.score, required this.criteriaMet, required this.feedback});
  factory ScenarioScore.fromJson(Map<String, dynamic> j) => ScenarioScore(
        score: (j['score'] as num?)?.toInt() ?? 0,
        criteriaMet: ((j['criteriaMet'] as List?) ?? const [])
            .map((e) => e == true)
            .toList(),
        feedback: j['feedback']?.toString() ?? '',
      );
}
