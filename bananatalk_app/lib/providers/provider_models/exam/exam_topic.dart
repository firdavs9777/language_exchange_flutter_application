/// One row from `GET /sections/:id/topics`. Distinct topic string plus the
/// number of questions tagged with it, so the picker can render
/// "Climate · 4 questions" tiles without a follow-up fetch.
class ExamTopic {
  const ExamTopic({required this.topic, required this.questionCount});

  final String topic;
  final int questionCount;

  factory ExamTopic.fromJson(Map<String, dynamic> json) {
    return ExamTopic(
      topic: json['topic']?.toString() ?? '',
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
    );
  }
}
