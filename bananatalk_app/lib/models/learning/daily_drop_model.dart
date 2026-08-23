/// Models for the Study Hub daily drop (spec §4.2, §4.6).
class DailyQuickCheck {
  final String prompt;
  final List<String> options;

  const DailyQuickCheck({required this.prompt, required this.options});

  factory DailyQuickCheck.fromJson(Map<String, dynamic> json) => DailyQuickCheck(
        prompt: json['prompt'] as String? ?? '',
        options: (json['options'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class DailyExample {
  final String text;
  final String translation;

  const DailyExample({required this.text, required this.translation});

  factory DailyExample.fromJson(Map<String, dynamic> json) => DailyExample(
        text: json['text'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
      );
}

class DailyItem {
  final String id;
  final String kind;
  final String level;
  final String title;
  final String explanation;
  final List<DailyExample> examples;
  final List<DailyQuickCheck> quickCheck;

  const DailyItem({
    required this.id,
    required this.kind,
    required this.level,
    required this.title,
    required this.explanation,
    required this.examples,
    required this.quickCheck,
  });

  factory DailyItem.fromJson(Map<String, dynamic> json) => DailyItem(
        id: json['id'].toString(),
        kind: json['kind'] as String? ?? '',
        level: json['level'] as String? ?? '',
        title: json['title'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        examples: (json['examples'] as List? ?? const [])
            .map((e) => DailyExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        quickCheck: (json['quickCheck'] as List? ?? const [])
            .map((e) => DailyQuickCheck.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DailyDropState {
  final bool needsLanguage;
  final String dateKey;
  final String? language;
  final String? requestedLevel;
  final String? servedLevel;
  final DailyItem? grammar;
  final DailyItem? vocabulary;
  final Map<String, int> completedScores;
  final bool dayComplete;

  const DailyDropState({
    required this.needsLanguage,
    required this.dateKey,
    this.language,
    this.requestedLevel,
    this.servedLevel,
    this.grammar,
    this.vocabulary,
    this.completedScores = const {},
    this.dayComplete = false,
  });

  /// True when the server served an easier level than the one requested,
  /// so the card can say which level it is showing (spec §4.3).
  bool get isLevelFallback =>
      servedLevel != null && requestedLevel != null && servedLevel != requestedLevel;

  int? scoreFor(String kind) => completedScores[kind];

  factory DailyDropState.fromJson(Map<String, dynamic> json) {
    final completed = <String, int>{};
    for (final c in (json['completed'] as List? ?? const [])) {
      final m = c as Map<String, dynamic>;
      completed[m['kind'].toString()] = (m['score'] as num?)?.toInt() ?? 0;
    }
    return DailyDropState(
      needsLanguage: json['needsLanguage'] as bool? ?? false,
      dateKey: json['dateKey'] as String? ?? '',
      language: json['language'] as String?,
      requestedLevel: json['requestedLevel'] as String?,
      servedLevel: json['servedLevel'] as String?,
      grammar: json['grammar'] == null
          ? null
          : DailyItem.fromJson(json['grammar'] as Map<String, dynamic>),
      vocabulary: json['vocabulary'] == null
          ? null
          : DailyItem.fromJson(json['vocabulary'] as Map<String, dynamic>),
      completedScores: completed,
      dayComplete: json['dayComplete'] as bool? ?? false,
    );
  }
}

class DailyCompletionResult {
  final int score;
  final int total;
  final List<int> correctAnswers;
  final bool dayComplete;
  final int? streak;
  final int xpAwarded;

  const DailyCompletionResult({
    required this.score,
    required this.total,
    required this.correctAnswers,
    required this.dayComplete,
    this.streak,
    this.xpAwarded = 0,
  });

  factory DailyCompletionResult.fromJson(Map<String, dynamic> json) =>
      DailyCompletionResult(
        score: (json['score'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        correctAnswers: (json['correctAnswers'] as List? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        dayComplete: json['dayComplete'] as bool? ?? false,
        streak: (json['streak'] as num?)?.toInt(),
        xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
      );
}
