/// One exam (IELTS, DELE, TOPIK, …) for a given language.
///
/// `scoringType` distinguishes band-scored exams (IELTS) from numeric
/// scores (TOEFL/TOPIK). The client uses `maxScore` to clamp inputs on
/// the study-plan target-score picker.
class ExamType {
  const ExamType({
    required this.id,
    required this.name,
    required this.languageId,
    this.description,
    this.sections = const [],
    this.durationMinutes,
    this.scoringType,
    this.maxScore,
    this.active = true,
  });

  final String id;
  final String name;
  final String languageId;
  final String? description;
  final List<String> sections; // ["reading", "writing", …]
  final int? durationMinutes;
  final String? scoringType; // "band" | "score"
  final num? maxScore;
  final bool active;

  factory ExamType.fromJson(Map<String, dynamic> json) {
    return ExamType(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      languageId: json['languageId']?.toString() ?? '',
      description: json['description']?.toString(),
      sections: (json['sections'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      scoringType: json['scoringType']?.toString(),
      maxScore: json['maxScore'] as num?,
      active: json['active'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'languageId': languageId,
        if (description != null) 'description': description,
        'sections': sections,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (scoringType != null) 'scoringType': scoringType,
        if (maxScore != null) 'maxScore': maxScore,
        'active': active,
      };
}
