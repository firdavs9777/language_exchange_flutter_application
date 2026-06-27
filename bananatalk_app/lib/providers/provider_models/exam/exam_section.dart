/// A section within an exam (Reading / Writing / Speaking / Listening /
/// Vocabulary). Phase 1 ships only Reading and Writing.
class ExamSection {
  const ExamSection({
    required this.id,
    required this.examId,
    required this.sectionName,
    required this.sectionType,
    this.description,
    this.durationMinutes,
    this.questionCount = 20,
  });

  final String id;
  final String examId;
  final String sectionName; // "Reading"
  final String sectionType; // "reading" | "writing" | …
  final String? description;
  final int? durationMinutes;
  final int questionCount;

  factory ExamSection.fromJson(Map<String, dynamic> json) {
    return ExamSection(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      sectionName: json['sectionName']?.toString() ?? '',
      sectionType: json['sectionType']?.toString() ?? '',
      description: json['description']?.toString(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 20,
    );
  }
}
