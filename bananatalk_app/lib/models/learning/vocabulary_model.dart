/// Vocabulary Model
/// Represents vocabulary items with Spaced Repetition System (SRS) data

class VocabularyItem {
  final String id;
  final String userId;
  final String word;
  final String translation;
  final String language;
  final String? pronunciation;
  final String? partOfSpeech;
  final String? exampleSentence;
  final String? exampleTranslation;
  final int srsLevel;
  final DateTime? nextReview;
  final int reviewCount;
  final int correctCount;
  final List<String> tags;
  final String? notes;
  final VocabularyContext? context;
  final DateTime createdAt;
  final DateTime updatedAt;

  VocabularyItem({
    required this.id,
    required this.userId,
    required this.word,
    required this.translation,
    required this.language,
    this.pronunciation,
    this.partOfSpeech,
    this.exampleSentence,
    this.exampleTranslation,
    this.srsLevel = 0,
    this.nextReview,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.tags = const [],
    this.notes,
    this.context,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['_id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      word: json['word']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      pronunciation: json['pronunciation']?.toString(),
      partOfSpeech: json['partOfSpeech']?.toString(),
      exampleSentence: json['exampleSentence']?.toString(),
      exampleTranslation: json['exampleTranslation']?.toString(),
      srsLevel: json['srsLevel'] ?? 0,
      nextReview: json['nextReview'] != null
          ? DateTime.tryParse(json['nextReview'])
          : null,
      reviewCount: json['reviewCount'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      notes: json['notes']?.toString(),
      context: json['context'] != null
          ? VocabularyContext.fromJson(json['context'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'word': word,
      'translation': translation,
      'language': language,
      if (pronunciation != null) 'pronunciation': pronunciation,
      if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
      if (exampleSentence != null) 'exampleSentence': exampleSentence,
      if (exampleTranslation != null) 'exampleTranslation': exampleTranslation,
      'srsLevel': srsLevel,
      if (nextReview != null) 'nextReview': nextReview!.toIso8601String(),
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      if (tags.isNotEmpty) 'tags': tags,
      if (notes != null) 'notes': notes,
      if (context != null) 'context': context!.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get SRS status label
  String get srsStatus {
    if (srsLevel == 0) return 'New';
    if (srsLevel <= 2) return 'Learning';
    if (srsLevel <= 4) return 'Reviewing';
    if (srsLevel <= 8) return 'Known';
    return 'Mastered';
  }

  /// Check if due for review
  bool get isDue {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview!);
  }

  /// Get accuracy rate
  double get accuracy {
    if (reviewCount == 0) return 0;
    return correctCount / reviewCount;
  }

  VocabularyItem copyWith({
    String? id,
    String? userId,
    String? word,
    String? translation,
    String? language,
    String? pronunciation,
    String? partOfSpeech,
    String? exampleSentence,
    String? exampleTranslation,
    int? srsLevel,
    DateTime? nextReview,
    int? reviewCount,
    int? correctCount,
    List<String>? tags,
    String? notes,
    VocabularyContext? context,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VocabularyItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      language: language ?? this.language,
      pronunciation: pronunciation ?? this.pronunciation,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      srsLevel: srsLevel ?? this.srsLevel,
      nextReview: nextReview ?? this.nextReview,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      context: context ?? this.context,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VocabularyContext {
  final String source;
  final String? conversationId;
  final String? messageId;

  VocabularyContext({
    required this.source,
    this.conversationId,
    this.messageId,
  });

  factory VocabularyContext.fromJson(Map<String, dynamic> json) {
    return VocabularyContext(
      source: json['source']?.toString() ?? 'manual',
      conversationId: json['conversationId']?.toString(),
      messageId: json['messageId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      if (conversationId != null) 'conversationId': conversationId,
      if (messageId != null) 'messageId': messageId,
    };
  }
}

class VocabularyStats {
  final int total;
  final int mastered;
  final int learning;
  final int newWords;
  final int dueToday;
  final Map<String, int> byLanguage;
  final Map<String, int> bySrsLevel;
  final int reviewStreak;
  final double averageAccuracy;

  VocabularyStats({
    required this.total,
    required this.mastered,
    required this.learning,
    required this.newWords,
    required this.dueToday,
    required this.byLanguage,
    required this.bySrsLevel,
    required this.reviewStreak,
    required this.averageAccuracy,
  });

  factory VocabularyStats.empty() {
    return VocabularyStats(
      total: 0,
      mastered: 0,
      learning: 0,
      newWords: 0,
      dueToday: 0,
      byLanguage: {},
      bySrsLevel: {},
      reviewStreak: 0,
      averageAccuracy: 0,
    );
  }

  factory VocabularyStats.fromJson(Map<String, dynamic> json) {
    // Handle both field name variations from backend
    final srsData = json['srsDistribution'] ?? json['bySrsLevel'];

    return VocabularyStats(
      total: json['total'] ?? 0,
      mastered: json['mastered'] ?? 0,
      learning: json['learning'] ?? 0,
      newWords: json['new'] ?? 0,
      dueToday: json['dueToday'] ?? json['dueNow'] ?? 0,
      byLanguage: (json['byLanguage'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      bySrsLevel: (srsData as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      reviewStreak: json['streak'] ?? json['reviewStreak'] ?? 0,
      averageAccuracy: (json['reviewAccuracy'] ?? json['averageAccuracy'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'mastered': mastered,
      'learning': learning,
      'new': newWords,
      'dueToday': dueToday,
      'byLanguage': byLanguage,
      'bySrsLevel': bySrsLevel,
      'reviewStreak': reviewStreak,
      'averageAccuracy': averageAccuracy,
    };
  }
}

/// Vocabulary review result
class VocabularyReviewResult {
  final VocabularyItem vocabulary;
  final int xpEarned;
  final bool mastered;
  final String? message;

  VocabularyReviewResult({
    required this.vocabulary,
    required this.xpEarned,
    required this.mastered,
    this.message,
  });

  factory VocabularyReviewResult.fromJson(Map<String, dynamic> json) {
    return VocabularyReviewResult(
      vocabulary: VocabularyItem.fromJson(json['vocabulary']),
      xpEarned: json['xpEarned'] ?? 0,
      mastered: json['mastered'] ?? false,
      message: json['message']?.toString(),
    );
  }
}

/// Due words response
class DueWordsResponse {
  final List<VocabularyItem> dueWords;
  final int totalDue;
  final ReviewSession reviewSession;

  DueWordsResponse({
    required this.dueWords,
    required this.totalDue,
    required this.reviewSession,
  });

  factory DueWordsResponse.fromJson(Map<String, dynamic> json) {
    return DueWordsResponse(
      dueWords: (json['dueWords'] as List<dynamic>?)
              ?.map((e) => VocabularyItem.fromJson(e))
              .toList() ??
          [],
      totalDue: json['totalDue'] ?? 0,
      reviewSession: json['reviewSession'] != null
          ? ReviewSession.fromJson(json['reviewSession'])
          : ReviewSession.empty(),
    );
  }
}

class ReviewSession {
  final int estimatedMinutes;
  final int xpPotential;

  ReviewSession({
    required this.estimatedMinutes,
    required this.xpPotential,
  });

  factory ReviewSession.empty() {
    return ReviewSession(estimatedMinutes: 0, xpPotential: 0);
  }

  factory ReviewSession.fromJson(Map<String, dynamic> json) {
    return ReviewSession(
      estimatedMinutes: json['estimatedMinutes'] ?? 0,
      xpPotential: json['xpPotential'] ?? 0,
    );
  }
}

/// SRS Level reference
/// Level | Interval | Status
/// 0     | Same day | New
/// 1     | 1 day    | Learning
/// 2     | 2 days   | Learning
/// 3     | 4 days   | Learning
/// 4     | 1 week   | Known
/// 5     | 2 weeks  | Known
/// 6     | 1 month  | Known
/// 7     | 2 months | Known
/// 8     | 4 months | Known
/// 9     | 1 year   | Mastered
