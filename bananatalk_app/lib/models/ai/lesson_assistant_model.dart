/// AI Lesson Assistant Models

class HintResponse {
  final String hint;
  final int hintLevel;
  final bool hasMoreHints;
  final String? encouragement;

  HintResponse({
    required this.hint,
    required this.hintLevel,
    required this.hasMoreHints,
    this.encouragement,
  });
  factory HintResponse.fromJson(Map<String, dynamic> json) {
    return HintResponse(
      hint: json['hint']?.toString() ?? '',
      hintLevel: json['hintLevel'] ?? 1,
      hasMoreHints: json['hasMoreHints'] ?? false,
      encouragement: json['encouragement']?.toString(),
    );
  }
}

class ExplanationResponse {
  final String concept;
  final String explanation;
  final List<ExplanationExample> examples;
  final String? tip;
  final List<String> relatedConcepts;

  ExplanationResponse({
    required this.concept,
    required this.explanation,
    this.examples = const [],
    this.tip,
    this.relatedConcepts = const [],
  });

  factory ExplanationResponse.fromJson(Map<String, dynamic> json) {
    return ExplanationResponse(
      concept: json['concept']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      examples:
          (json['examples'] as List<dynamic>?)
              ?.map(
                (e) => ExplanationExample.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      tip: json['tip']?.toString(),
      relatedConcepts:
          (json['relatedConcepts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class ExplanationExample {
  final String sentence;
  final String translation;

  ExplanationExample({required this.sentence, required this.translation});

  factory ExplanationExample.fromJson(Map<String, dynamic> json) {
    return ExplanationExample(
      sentence: json['sentence']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
    );
  }
}

class FeedbackResponse {
  final String userAnswer;
  final String correctAnswer;
  final String feedback;
  final String? correction;
  final String? explanation;
  final String? commonMistake;
  final String? encouragement;

  FeedbackResponse({
    required this.userAnswer,
    required this.correctAnswer,
    required this.feedback,
    this.correction,
    this.explanation,
    this.commonMistake,
    this.encouragement,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      userAnswer: json['userAnswer']?.toString() ?? '',
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      feedback: json['feedback']?.toString() ?? '',
      correction: json['correction']?.toString(),
      explanation: json['explanation']?.toString(),
      commonMistake: json['commonMistake']?.toString(),
      encouragement: json['encouragement']?.toString(),
    );
  }
}

class AskQuestionResponse {
  final String question;
  final String answer;
  final List<ExplanationExample> examples;
  final String? additionalInfo;
  final String? suggestedFocus;

  AskQuestionResponse({
    required this.question,
    required this.answer,
    this.examples = const [],
    this.additionalInfo,
    this.suggestedFocus,
  });

  factory AskQuestionResponse.fromJson(Map<String, dynamic> json) {
    return AskQuestionResponse(
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      examples:
          (json['examples'] as List<dynamic>?)
              ?.map(
                (e) => ExplanationExample.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      additionalInfo: json['additionalInfo']?.toString(),
      suggestedFocus: json['suggestedFocus']?.toString(),
    );
  }
}

class PracticeVariation {
  final String type;
  final String question;
  final String? targetText;
  final List<String>? options;
  final String correctAnswer;
  final List<String> acceptedAnswers;
  final String? explanation;

  PracticeVariation({
    required this.type,
    required this.question,
    this.targetText,
    this.options,
    required this.correctAnswer,
    this.acceptedAnswers = const [],
    this.explanation,
  });

  factory PracticeVariation.fromJson(Map<String, dynamic> json) {
    return PracticeVariation(
      type: json['type']?.toString() ?? 'fill_blank',
      question: json['question']?.toString() ?? '',
      targetText: json['targetText']?.toString(),
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      acceptedAnswers:
          (json['acceptedAnswers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      explanation: json['explanation']?.toString(),
    );
  }
}

class PracticeVariationsResponse {
  final Map<String, dynamic>? originalExercise;
  final List<PracticeVariation> variations;

  PracticeVariationsResponse({this.originalExercise, required this.variations});

  factory PracticeVariationsResponse.fromJson(Map<String, dynamic> json) {
    return PracticeVariationsResponse(
      originalExercise: json['originalExercise'] as Map<String, dynamic>?,
      variations:
          (json['variations'] as List<dynamic>?)
              ?.map(
                (e) => PracticeVariation.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class LessonSummaryResponse {
  final String lessonTitle;
  final String? lessonTopic;
  final String summary;
  final List<String> keyPoints;
  final List<VocabularyItem> vocabularyToRemember;
  final List<String> grammarRules;
  final String? practiceRecommendation;
  final String? encouragement;
  final int userScore;
  final bool isPerfect;

  LessonSummaryResponse({
    required this.lessonTitle,
    this.lessonTopic,
    required this.summary,
    this.keyPoints = const [],
    this.vocabularyToRemember = const [],
    this.grammarRules = const [],
    this.practiceRecommendation,
    this.encouragement,
    required this.userScore,
    required this.isPerfect,
  });

  factory LessonSummaryResponse.fromJson(Map<String, dynamic> json) {
    return LessonSummaryResponse(
      lessonTitle: json['lessonTitle']?.toString() ?? '',
      lessonTopic: json['lessonTopic']?.toString(),
      summary: json['summary']?.toString() ?? '',
      keyPoints:
          (json['keyPoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vocabularyToRemember:
          (json['vocabularyToRemember'] as List<dynamic>?)
              ?.map((e) => VocabularyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      grammarRules:
          (json['grammarRules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      practiceRecommendation: json['practiceRecommendation']?.toString(),
      encouragement: json['encouragement']?.toString(),
      userScore: json['userScore'] ?? 0,
      isPerfect: json['isPerfect'] ?? false,
    );
  }
}

class VocabularyItem {
  final String word;
  final String translation;
  final String? usage;

  VocabularyItem({required this.word, required this.translation, this.usage});

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      word: json['word']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      usage: json['usage']?.toString(),
    );
  }
}

class TranslationHelpResponse {
  final String originalText;
  final String sourceLanguage;
  final String targetLanguage;
  final String translation;
  final String? literal;
  final List<WordBreakdown> breakdown;
  final List<String> alternatives;
  final String? culturalNote;

  TranslationHelpResponse({
    required this.originalText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.translation,
    this.literal,
    this.breakdown = const [],
    this.alternatives = const [],
    this.culturalNote,
  });

  factory TranslationHelpResponse.fromJson(Map<String, dynamic> json) {
    return TranslationHelpResponse(
      originalText: json['originalText']?.toString() ?? '',
      sourceLanguage: json['sourceLanguage']?.toString() ?? '',
      targetLanguage: json['targetLanguage']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      literal: json['literal']?.toString(),
      breakdown:
          (json['breakdown'] as List<dynamic>?)
              ?.map((e) => WordBreakdown.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      alternatives:
          (json['alternatives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      culturalNote: json['culturalNote']?.toString(),
    );
  }
}

class WordBreakdown {
  final String word;
  final String translation;
  final String? note;

  WordBreakdown({required this.word, required this.translation, this.note});

  factory WordBreakdown.fromJson(Map<String, dynamic> json) {
    return WordBreakdown(
      word: json['word']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      note: json['note']?.toString(),
    );
  }
}
