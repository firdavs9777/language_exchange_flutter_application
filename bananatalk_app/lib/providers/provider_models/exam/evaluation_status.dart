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
    this.transcript,
    this.audioUrl,
    this.errorMessage,
    this.completedAt,
  });

  final String id;
  final String status; // "pending" | "completed" | "failed"
  final int? score;
  final String? feedback;
  final List<String> strengths;
  final List<String> improvements;
  /// Whisper-STT output for speaking submissions. Null for essay submissions.
  final String? transcript;
  /// Optional S3 URL for the user's recorded audio (when SPEECH_PERSIST_AUDIO is on).
  final String? audioUrl;
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
      transcript: json['transcript']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }
}
