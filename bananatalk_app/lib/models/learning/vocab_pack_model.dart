// Vocab Pack models — curated, level-tagged vocabulary packs served by
// GET /learning/vocab-packs (list) and GET /learning/vocab-packs/:id (detail).
// A pack bundles a word inventory plus optional authored VocabPackExercises
// (multiple_choice, fill_blank, matching, error_correction).

/// Lightweight list item (no word/exercise bodies) from GET /learning/vocab-packs.
class VocabPackSummary {
  final String id;
  final String level;
  final String topic;
  final String language;
  final int wordCount;
  final int exerciseCount;

  VocabPackSummary({
    required this.id,
    required this.level,
    required this.topic,
    required this.language,
    required this.wordCount,
    required this.exerciseCount,
  });

  factory VocabPackSummary.fromJson(Map<String, dynamic> json) {
    return VocabPackSummary(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      language: (json['language'] ?? 'English').toString(),
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
      exerciseCount: (json['exerciseCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class VocabPackWord {
  final String word;
  final String definition;
  final String example;
  final String? translationHint;

  VocabPackWord({
    required this.word,
    required this.definition,
    required this.example,
    this.translationHint,
  });

  factory VocabPackWord.fromJson(Map<String, dynamic> json) {
    return VocabPackWord(
      word: (json['word'] ?? '').toString(),
      definition: (json['definition'] ?? '').toString(),
      example: (json['example'] ?? '').toString(),
      translationHint: json['translationHint']?.toString(),
    );
  }
}

class VocabPackExercisePair {
  final String term;
  final String definition;

  VocabPackExercisePair({required this.term, required this.definition});

  factory VocabPackExercisePair.fromJson(Map<String, dynamic> json) {
    return VocabPackExercisePair(
      term: (json['term'] ?? '').toString(),
      definition: (json['definition'] ?? '').toString(),
    );
  }
}

class VocabPackExercise {
  final String type; // multiple_choice | fill_blank | matching | error_correction
  final String? prompt;
  final List<String>? options;
  final int? answerIndex;
  final String? answer;
  final String? corrected;
  final String? targetWord;
  final List<VocabPackExercisePair>? pairs;

  VocabPackExercise({
    required this.type,
    this.prompt,
    this.options,
    this.answerIndex,
    this.answer,
    this.corrected,
    this.targetWord,
    this.pairs,
  });

  factory VocabPackExercise.fromJson(Map<String, dynamic> json) {
    return VocabPackExercise(
      type: (json['type'] ?? '').toString(),
      prompt: json['prompt']?.toString(),
      options: (json['options'] as List?)?.map((e) => e.toString()).toList(),
      answerIndex: (json['answerIndex'] as num?)?.toInt(),
      answer: json['answer']?.toString(),
      corrected: json['corrected']?.toString(),
      targetWord: json['targetWord']?.toString(),
      pairs: (json['pairs'] as List?)
          ?.map((e) => VocabPackExercisePair.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Full pack from GET /learning/vocab-packs/:id.
class VocabPack {
  final String id;
  final String level;
  final String topic;
  final String language;
  final List<VocabPackWord> words;
  final List<VocabPackExercise> exercises;

  VocabPack({
    required this.id,
    required this.level,
    required this.topic,
    required this.language,
    required this.words,
    required this.exercises,
  });

  factory VocabPack.fromJson(Map<String, dynamic> json) {
    return VocabPack(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      language: (json['language'] ?? 'English').toString(),
      words: (json['words'] as List?)
              ?.map((e) => VocabPackWord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      exercises: (json['exercises'] as List?)
              ?.map((e) => VocabPackExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
