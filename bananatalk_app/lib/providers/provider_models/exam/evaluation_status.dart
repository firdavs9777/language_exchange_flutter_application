/// Async-eval polling response from
/// `GET /exam-study/evaluations/:evaluationId`.
class EvaluationStatus {
  const EvaluationStatus({
    required this.id,
    required this.status,
    this.score,
    this.feedback,
    this.strengths = const [],
    this.improvements = const [],
    this.errorMessage,
    this.completedAt,
  });

  final String id;
  final String status; // "pending" | "completed" | "failed"
  final int? score;
  final String? feedback;
  final List<String> strengths;
  final List<String> improvements;
  final String? errorMessage;
  final DateTime? completedAt;

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  factory EvaluationStatus.fromJson(Map<String, dynamic> json) {
    return EvaluationStatus(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      score: (json['score'] as num?)?.toInt(),
      feedback: json['feedback']?.toString(),
      strengths: (json['strengths'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      improvements: (json['improvements'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      errorMessage: json['errorMessage']?.toString(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }
}
