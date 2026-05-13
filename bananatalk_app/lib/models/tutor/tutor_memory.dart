// DTOs matching the backend TutorMemory shape (see
// `models/TutorMemory.js`). Defensive parsing: every field has a
// fallback so a partial server response never crashes the UI.

class TutorMemory {
  final String? persona; // 'nana' | 'sensei' | 'riko' | null
  final String proficiencyLevel;
  final List<String> targetLanguages;
  final String nativeLanguage;
  final List<WeakArea> weakAreas;
  final List<ChatSummary> recentChatSummaries;
  final DailyPlan? dailyPlan;

  TutorMemory({
    required this.persona,
    required this.proficiencyLevel,
    required this.targetLanguages,
    required this.nativeLanguage,
    required this.weakAreas,
    required this.recentChatSummaries,
    required this.dailyPlan,
  });

  factory TutorMemory.fromJson(Map<String, dynamic> json) => TutorMemory(
        persona: json['persona'] as String?,
        proficiencyLevel: json['proficiencyLevel'] as String? ?? 'A1',
        targetLanguages:
            (json['targetLanguages'] as List?)?.cast<String>() ?? const [],
        nativeLanguage: json['nativeLanguage'] as String? ?? '',
        weakAreas: ((json['weakAreas'] as List?) ?? const [])
            .map((e) => WeakArea.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentChatSummaries: ((json['recentChatSummaries'] as List?) ?? const [])
            .map((e) => ChatSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyPlan: json['dailyPlan'] is Map<String, dynamic>
            ? DailyPlan.fromJson(json['dailyPlan'] as Map<String, dynamic>)
            : null,
      );
}

class WeakArea {
  final String topic;
  final int frequency;
  WeakArea({required this.topic, required this.frequency});
  factory WeakArea.fromJson(Map<String, dynamic> j) => WeakArea(
        topic: j['topic']?.toString() ?? '',
        frequency: (j['frequency'] as num?)?.toInt() ?? 0,
      );
}

class ChatSummary {
  final String summary;
  final DateTime createdAt;
  ChatSummary({required this.summary, required this.createdAt});
  factory ChatSummary.fromJson(Map<String, dynamic> j) => ChatSummary(
        summary: j['summary']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class DailyPlan {
  final DateTime date;
  final List<DailyPlanTask> tasks;
  DailyPlan({required this.date, required this.tasks});
  factory DailyPlan.fromJson(Map<String, dynamic> j) => DailyPlan(
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        tasks: ((j['tasks'] as List?) ?? const [])
            .map((e) => DailyPlanTask.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DailyPlanTask {
  final String type; // 'srs_review' | 'grammar_drill' | 'tutor_chat' | 'tutor_pronunciation'
  final int? count;
  final String? topic;
  final int? minutes;
  final dynamic completed; // num for srs/tutor, bool for grammar

  DailyPlanTask({
    required this.type,
    this.count,
    this.topic,
    this.minutes,
    required this.completed,
  });

  factory DailyPlanTask.fromJson(Map<String, dynamic> j) => DailyPlanTask(
        type: j['type']?.toString() ?? '',
        count: (j['count'] as num?)?.toInt(),
        topic: j['topic'] as String?,
        minutes: (j['minutes'] as num?)?.toInt(),
        completed: j['completed'],
      );

  bool get isDone {
    if (completed is bool) return completed == true;
    if (completed is num) {
      if (type == 'srs_review' && count != null) {
        return (completed as num) >= count!;
      }
      if (type == 'tutor_chat' && minutes != null) {
        return (completed as num) >= minutes!;
      }
    }
    return false;
  }
}
