/// A single practice question. `questionType` drives which UI renders:
/// MC card with options, essay editor, fill-blank input, or speaking
/// prompt (Phase 2+).
class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.examId,
    required this.sectionId,
    required this.questionText,
    required this.questionType,
    this.correctAnswer,
    this.options = const [],
    this.audioUrl,
    this.imageUrl,
    this.explanation,
    this.difficulty = 'medium',
    this.source = 'builtin',
    this.topic,
  });

  final String id;
  final String examId;
  final String sectionId;
  final String questionText;
  /// "multiple-choice" | "essay" | "speaking-prompt" | "fill-blank"
  final String questionType;
  /// For MC: the correct option (string). For essay/speaking: null.
  final String? correctAnswer;
  final List<String> options;
  final String? audioUrl;
  final String? imageUrl;
  final String? explanation;
  /// "easy" | "medium" | "hard"
  final String difficulty;
  /// "builtin" | "ai-generated"
  final String source;
  /// Free-form topic tag ("Climate", "Travel", …) used by the topic picker.
  /// Null when the question hasn't been categorized yet.
  final String? topic;

  bool get isMultipleChoice => questionType == 'multiple-choice';
  bool get isEssay => questionType == 'essay';
  bool get isSpeaking => questionType == 'speaking-prompt';
  bool get isFillBlank => questionType == 'fill-blank';

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      sectionId: json['sectionId']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? '',
      questionType: json['questionType']?.toString() ?? 'multiple-choice',
      correctAnswer: json['correctAnswer']?.toString(),
      options: (json['options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      audioUrl: json['audioUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      explanation: json['explanation']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'medium',
      source: json['source']?.toString() ?? 'builtin',
      topic: json['topic']?.toString(),
    );
  }
}
