/// One curated study tip / teaching technique returned by the
/// `/exam-study/exams/:examId/tips` endpoint.
class ExamStudyTip {
  const ExamStudyTip({
    required this.id,
    required this.examId,
    required this.category,
    required this.title,
    required this.body,
    this.sectionType,
    this.tags = const [],
    this.order = 0,
  });

  final String id;
  final String examId;
  final String? sectionType;
  /// One of: strategy, grammar, vocabulary, time-management,
  /// common-mistakes, band-booster, cultural-notes, pronunciation, fluency.
  final String category;
  final String title;
  final String body;
  final List<String> tags;
  final int order;

  factory ExamStudyTip.fromJson(Map<String, dynamic> json) {
    return ExamStudyTip(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      sectionType: json['sectionType']?.toString(),
      category: json['category']?.toString() ?? 'strategy',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
