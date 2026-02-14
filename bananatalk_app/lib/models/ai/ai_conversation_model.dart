/// AI Conversation Models

class AIConversation {
  final String id;
  final String targetLanguage;
  final String cefrLevel;
  final String? nativeLanguage;
  final String? topicId;
  final String? scenarioId;
  final ConversationSettings settings;
  final String status; // active, completed
  final List<AIMessage> messages;
  final ConversationSummary? summary;
  final DateTime createdAt;
  final DateTime? endedAt;

  AIConversation({
    required this.id,
    required this.targetLanguage,
    required this.cefrLevel,
    this.nativeLanguage,
    this.topicId,
    this.scenarioId,
    required this.settings,
    required this.status,
    this.messages = const [],
    this.summary,
    required this.createdAt,
    this.endedAt,
  });

  factory AIConversation.fromJson(Map<String, dynamic> json) {
    // Handle topic - API returns object with {id, name, icon}
    String? topicId = json['topicId']?.toString();
    if (topicId == null && json['topic'] != null) {
      final topic = json['topic'];
      if (topic is Map) {
        topicId = topic['id']?.toString();
      } else if (topic is String) {
        topicId = topic;
      }
    }

    // Handle scenario - API returns object
    String? scenarioId = json['scenarioId']?.toString();
    if (scenarioId == null && json['scenario'] != null) {
      final scenario = json['scenario'];
      if (scenario is Map && scenario.isNotEmpty) {
        scenarioId = scenario['id']?.toString();
      } else if (scenario is String) {
        scenarioId = scenario;
      }
    }

    // Handle createdAt - API may use 'startedAt'
    DateTime createdAt = DateTime.now();
    if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else if (json['startedAt'] != null) {
      createdAt = DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now();
    }

    return AIConversation(
      id: json['_id']?.toString() ?? json['conversationId']?.toString() ?? json['id']?.toString() ?? '',
      targetLanguage: json['targetLanguage']?.toString() ?? '',
      cefrLevel: json['cefrLevel']?.toString() ?? 'B1',
      nativeLanguage: json['nativeLanguage']?.toString(),
      topicId: topicId,
      scenarioId: scenarioId,
      settings: json['settings'] != null
          ? ConversationSettings.fromJson(json['settings'] is Map ? Map<String, dynamic>.from(json['settings']) : {})
          : const ConversationSettings(),
      status: json['status']?.toString() ?? 'active',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => AIMessage.fromJson(e is Map ? Map<String, dynamic>.from(e) : {}))
              .toList() ??
          [],
      summary: json['summary'] != null
          ? ConversationSummary.fromJson(json['summary'] is Map ? Map<String, dynamic>.from(json['summary']) : {})
          : null,
      createdAt: createdAt,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'].toString())
          : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
}

class ConversationSettings {
  final String correctionStyle; // gentle, direct, detailed
  final String responseLength; // short, medium, long
  final String level; // beginner, intermediate, advanced
  final bool autoCorrect;
  final String formality; // formal, neutral, informal
  final bool showTranslations;

  const ConversationSettings({
    this.correctionStyle = 'gentle',
    this.responseLength = 'medium',
    this.level = 'intermediate',
    this.autoCorrect = true,
    this.formality = 'neutral',
    this.showTranslations = false,
  });

  factory ConversationSettings.fromJson(Map<String, dynamic> json) {
    return ConversationSettings(
      correctionStyle: json['correctionStyle']?.toString() ?? 'gentle',
      responseLength: json['responseLength']?.toString() ?? 'medium',
      level: json['level']?.toString() ?? 'intermediate',
      autoCorrect: json['autoCorrect'] == true,
      formality: json['formality']?.toString() ?? 'neutral',
      showTranslations: json['showTranslations'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'correctionStyle': correctionStyle,
      'responseLength': responseLength,
      'level': level,
      'autoCorrect': autoCorrect,
      'formality': formality,
      'showTranslations': showTranslations,
    };
  }
}

class AIMessage {
  final String role; // user, assistant
  final String content;
  final MessageFeedback? feedback;
  final int? responseTime;
  final DateTime timestamp;

  AIMessage({
    required this.role,
    required this.content,
    this.feedback,
    this.responseTime,
    required this.timestamp,
  });

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      feedback: json['feedback'] != null
          ? MessageFeedback.fromJson(json['feedback'])
          : null,
      responseTime: json['responseTime'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class MessageFeedback {
  final List<GrammarCorrection> corrections;
  final String? encouragement;
  final List<String> suggestions;

  MessageFeedback({
    this.corrections = const [],
    this.encouragement,
    this.suggestions = const [],
  });

  factory MessageFeedback.fromJson(Map<String, dynamic> json) {
    return MessageFeedback(
      corrections: (json['corrections'] as List<dynamic>?)
              ?.map((e) => GrammarCorrection.fromJson(e))
              .toList() ??
          [],
      encouragement: json['encouragement']?.toString(),
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  bool get hasCorrections => corrections.isNotEmpty;
}

class GrammarCorrection {
  final String original;
  final String corrected;
  final String explanation;
  final String? rule;

  GrammarCorrection({
    required this.original,
    required this.corrected,
    required this.explanation,
    this.rule,
  });

  factory GrammarCorrection.fromJson(Map<String, dynamic> json) {
    return GrammarCorrection(
      original: json['original']?.toString() ?? '',
      corrected: json['corrected']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      rule: json['rule']?.toString(),
    );
  }
}

class ConversationSummary {
  final int messageCount;
  final int correctMessages;
  final int xpEarned;
  final int duration; // in seconds
  final int fluencyScore; // 0-100
  final List<String> topicsDiscussed;
  final List<String> areasToImprove;
  final String overallFeedback;

  ConversationSummary({
    required this.messageCount,
    required this.correctMessages,
    required this.xpEarned,
    this.duration = 0,
    this.fluencyScore = 0,
    this.topicsDiscussed = const [],
    this.areasToImprove = const [],
    required this.overallFeedback,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      messageCount: json['messageCount'] ?? json['messagesCount'] ?? 0,
      correctMessages: json['correctMessages'] ?? 0,
      xpEarned: json['xpEarned'] ?? 0,
      duration: json['duration'] ?? 0,
      fluencyScore: json['fluencyScore'] ?? 0,
      topicsDiscussed: (json['topicsDiscussed'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      areasToImprove: (json['areasToImprove'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['improvements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      overallFeedback: json['overallFeedback']?.toString() ??
          json['feedback']?.toString() ?? '',
    );
  }

  double get accuracyRate =>
      messageCount > 0 ? (correctMessages / messageCount) * 100 : 0;

  // Aliases for compatibility
  int get messagesCount => messageCount;
  String get feedback => overallFeedback;
  List<String> get improvements => areasToImprove;
}

class ConversationTopic {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String level;
  final List<String> scenarios;

  ConversationTopic({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.level,
    this.scenarios = const [],
  });

  factory ConversationTopic.fromJson(Map<String, dynamic> json) {
    return ConversationTopic(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      icon: json['icon']?.toString() ?? '',
      level: json['level']?.toString() ?? 'B1',
      scenarios: (json['scenarios'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class PracticeScenario {
  final String id;
  final String name;
  final String description;
  final String topicId;
  final String level;
  final String initialPrompt;
  final String setting;
  final String icon;
  final List<String> suggestedPhrases;
  final List<String> objectives;

  PracticeScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.topicId,
    required this.level,
    required this.initialPrompt,
    this.setting = '',
    this.icon = '',
    this.suggestedPhrases = const [],
    this.objectives = const [],
  });

  factory PracticeScenario.fromJson(Map<String, dynamic> json) {
    return PracticeScenario(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      level: json['level']?.toString() ?? 'B1',
      initialPrompt: json['initialPrompt']?.toString() ?? '',
      setting: json['setting']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      suggestedPhrases: (json['suggestedPhrases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      objectives: (json['objectives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  // Alias for name
  String get title => name;
}

/// Request to start a conversation
class StartConversationRequest {
  final String targetLanguage;
  final String cefrLevel;
  final String? nativeLanguage;
  final String? topicId;
  final String? scenarioId;
  final String? level; // beginner, intermediate, advanced
  final ConversationSettings? settings;

  StartConversationRequest({
    this.targetLanguage = 'en',
    this.cefrLevel = 'B1',
    this.nativeLanguage,
    this.topicId,
    this.scenarioId,
    this.level,
    this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'targetLanguage': targetLanguage,
      'cefrLevel': cefrLevel,
      if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
      if (topicId != null) 'topicId': topicId,
      if (scenarioId != null) 'scenarioId': scenarioId,
      if (level != null) 'level': level,
      if (settings != null) 'settings': settings!.toJson(),
    };
  }
}

/// Request to send a message
class SendMessageRequest {
  final String content;
  final int? responseTime;
  final bool stream;

  SendMessageRequest({
    required this.content,
    this.responseTime,
    this.stream = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (responseTime != null) 'responseTime': responseTime,
      if (stream) 'stream': stream,
    };
  }
}
