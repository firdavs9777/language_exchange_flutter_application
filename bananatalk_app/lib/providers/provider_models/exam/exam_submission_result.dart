/// Result of `POST /questions/:id/submit-answer`. MC = instant 200,
/// essay/speaking = 202 with a poll URL (Chunk D wires the poll).
sealed class ExamSubmissionResult {
  const ExamSubmissionResult();
}

/// Returned for multiple-choice (and fill-blank in the future) — the
/// score, correctness, and explanation come back in one shot.
class InstantResult extends ExamSubmissionResult {
  const InstantResult({
    required this.score,
    required this.isCorrect,
    required this.feedback,
    this.explanation,
  });

  final int score; // 0 or 100 for MC; 0-100 in general.
  final bool isCorrect;
  final String feedback;
  final String? explanation;

  factory InstantResult.fromJson(Map<String, dynamic> json) {
    return InstantResult(
      score: (json['score'] as num?)?.toInt() ?? 0,
      isCorrect: json['isCorrect'] == true,
      feedback: json['feedback']?.toString() ?? '',
      explanation: json['explanation']?.toString(),
    );
  }
}

/// Returned for essay / speaking-prompt submissions. The caller must
/// poll [pollUrl] (or fetch by [evaluationId]) until the eval completes.
class AsyncResult extends ExamSubmissionResult {
  const AsyncResult({required this.evaluationId, required this.pollUrl});

  final String evaluationId;
  final String pollUrl;

  factory AsyncResult.fromJson(Map<String, dynamic> json) {
    final url = json['pollUrl']?.toString() ?? '';
    // Last path segment is the evaluation id when the URL is shaped
    // `/api/exam-study/evaluations/<id>`.
    final id = url.split('/').where((s) => s.isNotEmpty).lastOrNull ?? '';
    return AsyncResult(evaluationId: id, pollUrl: url);
  }
}

extension _LastOrNull<E> on Iterable<E> {
  E? get lastOrNull => isEmpty ? null : last;
}
