/// One row in the weekly study-plan timeline.
class StudyMilestone {
  const StudyMilestone({
    required this.week,
    required this.focus,
    this.tasks = const [],
    this.estimatedHours = 8,
  });

  final int week;
  final String focus;
  final List<String> tasks;
  final num estimatedHours;

  factory StudyMilestone.fromJson(Map<String, dynamic> json) {
    return StudyMilestone(
      week: (json['week'] as num?)?.toInt() ?? 0,
      focus: json['focus']?.toString() ?? '',
      tasks: (json['tasks'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      estimatedHours: (json['estimatedHours'] as num?) ?? 8,
    );
  }
}

/// One scheduled lesson in the day-by-day plan.
class DailyLesson {
  const DailyLesson({
    required this.date,
    this.section,
    this.topic,
    this.estimatedMinutes = 45,
  });

  final DateTime date;
  final String? section;
  final String? topic;
  final num estimatedMinutes;

  factory DailyLesson.fromJson(Map<String, dynamic> json) {
    return DailyLesson(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.now(),
      section: json['section']?.toString(),
      topic: json['topic']?.toString(),
      estimatedMinutes: (json['estimatedMinutes'] as num?) ?? 45,
    );
  }
}

/// AI-generated study plan for a (user, exam) pair.
class UserStudyPlan {
  const UserStudyPlan({
    required this.id,
    required this.userId,
    required this.examId,
    this.targetScore,
    this.targetExamDate,
    this.milestones = const [],
    this.dailyLessons = const [],
    this.status = 'active',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String examId;
  final num? targetScore;
  final DateTime? targetExamDate;
  final List<StudyMilestone> milestones;
  final List<DailyLesson> dailyLessons;
  final String status;
  final DateTime? createdAt;

  factory UserStudyPlan.fromJson(Map<String, dynamic> json) {
    final planMap = (json['plan'] is Map)
        ? Map<String, dynamic>.from(json['plan'] as Map)
        : const <String, dynamic>{};
    return UserStudyPlan(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      targetScore: json['targetScore'] as num?,
      targetExamDate: json['targetExamDate'] != null
          ? DateTime.tryParse(json['targetExamDate'].toString())
          : null,
      milestones: (planMap['milestones'] as List?)
              ?.whereType<Map>()
              .map((m) => StudyMilestone.fromJson(
                  Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      dailyLessons: (planMap['dailyLessons'] as List?)
              ?.whereType<Map>()
              .map((m) =>
                  DailyLesson.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      status: json['status']?.toString() ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
