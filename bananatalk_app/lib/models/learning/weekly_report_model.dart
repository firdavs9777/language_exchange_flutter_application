/// One week of the learner's daily-pack activity.
///
/// Every field is something they actually did. `accuracy` is deliberately
/// nullable: 0% reads as "you got everything wrong", null as "nothing to
/// report", and those are different weeks.
library;

class WeeklyReport {
  final String weekStartKey;
  final String weekEndKey;
  final int daysStudied;
  final int stationsCompleted;
  final int unitsMastered;
  final int wordsLearned;
  final double? accuracy;
  final String? bestDayKey;
  final int bestDayStations;

  /// The server's own call on whether anything happened, so the screen does
  /// not re-derive it from six separate numbers and risk disagreeing.
  final bool isEmpty;

  const WeeklyReport({
    required this.weekStartKey,
    required this.weekEndKey,
    required this.daysStudied,
    required this.stationsCompleted,
    required this.unitsMastered,
    required this.wordsLearned,
    required this.isEmpty,
    this.accuracy,
    this.bestDayKey,
    this.bestDayStations = 0,
  });

  int? get accuracyPercent => accuracy == null ? null : (accuracy! * 100).round();

  factory WeeklyReport.fromJson(Map<String, dynamic> json) => WeeklyReport(
        weekStartKey: json['weekStartKey'] as String? ?? '',
        weekEndKey: json['weekEndKey'] as String? ?? '',
        daysStudied: (json['daysStudied'] as num?)?.toInt() ?? 0,
        stationsCompleted: (json['stationsCompleted'] as num?)?.toInt() ?? 0,
        unitsMastered: (json['unitsMastered'] as num?)?.toInt() ?? 0,
        wordsLearned: (json['wordsLearned'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        bestDayKey: json['bestDayKey'] as String?,
        bestDayStations: (json['bestDayStations'] as num?)?.toInt() ?? 0,
        isEmpty: json['isEmpty'] as bool? ?? false,
      );
}
