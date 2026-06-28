/// One word in the shared exam-vocabulary bank — read-only seed content
/// surfaced by the Vocabulary browse and practice screens.
class VocabularyWord {
  const VocabularyWord({
    required this.id,
    required this.word,
    required this.level,
    required this.partOfSpeech,
    required this.definition,
    required this.exampleSentence,
    this.topic,
    this.audioUrl,
  });

  final String id;
  final String word;
  final String level; // A1 | A2 | B1 | B2 | C1 | C2
  final String partOfSpeech;
  final String definition;
  final String exampleSentence;
  final String? topic;
  final String? audioUrl;

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      word: json['word']?.toString() ?? '',
      level: json['level']?.toString() ?? 'A1',
      partOfSpeech: json['partOfSpeech']?.toString() ?? 'other',
      definition: json['definition']?.toString() ?? '',
      exampleSentence: json['exampleSentence']?.toString() ?? '',
      topic: json['topic']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
    );
  }
}

/// One MC question inside an in-flight vocab quiz. The correct option is
/// kept server-side — the client only sees the prompt + 4 choices.
class VocabularyQuizQuestion {
  const VocabularyQuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String prompt;
  final List<String> options;

  factory VocabularyQuizQuestion.fromJson(Map<String, dynamic> json) {
    return VocabularyQuizQuestion(
      id: json['id']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      options: (json['options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class VocabularyQuizStart {
  const VocabularyQuizStart({required this.quizId, required this.questions});
  final String quizId;
  final List<VocabularyQuizQuestion> questions;

  factory VocabularyQuizStart.fromJson(Map<String, dynamic> json) {
    return VocabularyQuizStart(
      quizId: json['quizId']?.toString() ?? '',
      questions: (json['questions'] as List?)
              ?.whereType<Map>()
              .map((m) => VocabularyQuizQuestion.fromJson(
                  Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
    );
  }
}

class VocabularyQuizResultItem {
  const VocabularyQuizResultItem({
    required this.questionId,
    required this.isCorrect,
    this.correctChoice,
    this.word,
    this.example,
  });

  final String questionId;
  final bool isCorrect;
  final int? correctChoice;
  final String? word;
  final String? example;

  factory VocabularyQuizResultItem.fromJson(Map<String, dynamic> json) {
    return VocabularyQuizResultItem(
      questionId: json['questionId']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
      correctChoice: (json['correctChoice'] as num?)?.toInt(),
      word: json['word']?.toString(),
      example: json['example']?.toString(),
    );
  }
}

class VocabularyQuizScore {
  const VocabularyQuizScore({
    required this.score,
    required this.correctCount,
    required this.total,
    required this.results,
  });

  final int score; // 0-100
  final int correctCount;
  final int total;
  final List<VocabularyQuizResultItem> results;

  factory VocabularyQuizScore.fromJson(Map<String, dynamic> json) {
    return VocabularyQuizScore(
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      results: (json['results'] as List?)
              ?.whereType<Map>()
              .map((m) => VocabularyQuizResultItem.fromJson(
                  Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
    );
  }
}

/// Thrown by the service when the quiz cache has rotated (410). The UI
/// should clear local quiz state and prompt the user to restart.
class VocabularyQuizExpiredException implements Exception {
  const VocabularyQuizExpiredException();
}
