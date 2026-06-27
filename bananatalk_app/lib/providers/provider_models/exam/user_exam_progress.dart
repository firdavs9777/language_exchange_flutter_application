/// One section's tally inside [UserExamProgress.sectionScores].
class SectionScore {
  const SectionScore({
    this.attempted = 0,
    this.correct = 0,
    this.score,
  });

  final int attempted;
  final int correct;
  /// Percentage 0-100 once at least one question has been attempted;
  /// null while the section is untouched.
  final int? score;

  factory SectionScore.fromJson(Map<String, dynamic> json) {
    return SectionScore(
      attempted: (json['attempted'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt(),
    );
  }

  static const empty = SectionScore();
}

/// Per-user, per-exam practice tally. Returned by
/// `GET /exam-study/users/:userId/exams/:examId/progress`.
class UserExamProgress {
  const UserExamProgress({
    required this.userId,
    required this.examId,
    this.questionsAttempted = 0,
    this.questionsCorrect = 0,
    this.sectionScores = const {},
    this.overallScore,
    this.lastAttemptedQuestionId,
    this.lastUpdated,
  });

  final String userId;
  final String examId;
  final int questionsAttempted;
  final int questionsCorrect;
  /// Keyed by `sectionType` ("reading", "writing", …).
  final Map<String, SectionScore> sectionScores;
  final int? overallScore;
  final String? lastAttemptedQuestionId;
  final DateTime? lastUpdated;

  /// Convenience: lookup a section's score, falling back to an empty
  /// tally so the UI doesn't need to null-check before reading counters.
  SectionScore forSection(String sectionType) =>
      sectionScores[sectionType] ?? SectionScore.empty;

  factory UserExamProgress.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sectionScores'];
    final parsed = <String, SectionScore>{};
    if (rawSections is Map) {
      for (final entry in rawSections.entries) {
        if (entry.value is Map) {
          parsed[entry.key.toString()] =
              SectionScore.fromJson(Map<String, dynamic>.from(entry.value));
        }
      }
    }
    return UserExamProgress(
      userId: json['userId']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      questionsAttempted: (json['questionsAttempted'] as num?)?.toInt() ?? 0,
      questionsCorrect: (json['questionsCorrect'] as num?)?.toInt() ?? 0,
      sectionScores: parsed,
      overallScore: (json['overallScore'] as num?)?.toInt(),
      lastAttemptedQuestionId: json['lastAttemptedQuestionId']?.toString(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString())
          : null,
    );
  }

  /// Default empty progress for an unstarted exam.
  factory UserExamProgress.empty({
    required String userId,
    required String examId,
  }) =>
      UserExamProgress(userId: userId, examId: examId);
}
