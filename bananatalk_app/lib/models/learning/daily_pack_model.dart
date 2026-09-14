/// Models for the daily learning pack (spec §5.5, §7).
///
/// The server owns scoring and completion: no `answerIndex` is ever sent, and
/// `packComplete` / `doneCount` reflect the server's own view rather than a
/// client-side count.
library;

enum StationStatus { todo, done, empty }

StationStatus _statusFrom(String? raw) {
  switch (raw) {
    case 'done':
      return StationStatus.done;
    case 'empty':
      return StationStatus.empty;
    default:
      // An unknown status must not break the flow — a newer server adding a
      // status should degrade to "still to do", not throw on parse.
      return StationStatus.todo;
  }
}

abstract class StationPayload {}

class PackCheck {
  final String prompt;
  final List<String> options;

  const PackCheck({required this.prompt, required this.options});

  factory PackCheck.fromJson(Map<String, dynamic> json) => PackCheck(
        prompt: json['prompt'] as String? ?? '',
        options:
            (json['options'] as List? ?? const []).map((e) => e.toString()).toList(),
      );
}

class PackWord {
  final String word;
  final String definition;
  final String example;
  final String translationHint;

  const PackWord({
    required this.word,
    required this.definition,
    required this.example,
    this.translationHint = '',
  });

  factory PackWord.fromJson(Map<String, dynamic> json) => PackWord(
        word: json['word'] as String? ?? '',
        definition: json['definition'] as String? ?? '',
        example: json['example'] as String? ?? '',
        translationHint: json['translationHint'] as String? ?? '',
      );
}

class VocabPayload implements StationPayload {
  final List<PackWord> words;
  final List<PackCheck> checks;

  const VocabPayload({required this.words, required this.checks});

  factory VocabPayload.fromJson(Map<String, dynamic> json) => VocabPayload(
        words: (json['words'] as List? ?? const [])
            .map((e) => PackWord.fromJson(e as Map<String, dynamic>))
            .toList(),
        checks: (json['checks'] as List? ?? const [])
            .map((e) => PackCheck.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GrammarPayload implements StationPayload {
  final String itemId;
  final int unit;
  final String section;
  final String title;
  final String explanation;
  final List<String> examples;
  final List<PackCheck> checks;

  const GrammarPayload({
    required this.itemId,
    required this.unit,
    required this.section,
    required this.title,
    required this.explanation,
    required this.examples,
    required this.checks,
  });

  factory GrammarPayload.fromJson(Map<String, dynamic> json) => GrammarPayload(
        itemId: json['itemId'].toString(),
        unit: (json['unit'] as num?)?.toInt() ?? 0,
        section: json['section'] as String? ?? '',
        title: json['title'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        examples: (json['examples'] as List? ?? const [])
            .map((e) => (e as Map<String, dynamic>)['text'].toString())
            .toList(),
        checks: (json['checks'] as List? ?? const [])
            .map((e) => PackCheck.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ListeningClip {
  final String id;
  final String text;
  final String word;

  const ListeningClip({required this.id, required this.text, required this.word});

  factory ListeningClip.fromJson(Map<String, dynamic> json) => ListeningClip(
        id: json['id'].toString(),
        text: json['text'] as String? ?? '',
        word: json['word'] as String? ?? '',
      );
}

class ListeningPayload implements StationPayload {
  final List<ListeningClip> clips;

  const ListeningPayload({required this.clips});

  factory ListeningPayload.fromJson(Map<String, dynamic> json) => ListeningPayload(
        clips: (json['clips'] as List? ?? const [])
            .map((e) => ListeningClip.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ReviewWord {
  final String id;
  final String word;
  final String translation;
  final int srsLevel;

  const ReviewWord({
    required this.id,
    required this.word,
    required this.translation,
    required this.srsLevel,
  });

  factory ReviewWord.fromJson(Map<String, dynamic> json) => ReviewWord(
        id: json['id'].toString(),
        word: json['word'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
        srsLevel: (json['srsLevel'] as num?)?.toInt() ?? 0,
      );
}

class ReviewPayload implements StationPayload {
  final List<ReviewWord> words;

  const ReviewPayload({required this.words});

  factory ReviewPayload.fromJson(Map<String, dynamic> json) => ReviewPayload(
        words: (json['words'] as List? ?? const [])
            .map((e) => ReviewWord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WrapPayload implements StationPayload {
  final List<PackCheck> questions;

  const WrapPayload({required this.questions});

  factory WrapPayload.fromJson(Map<String, dynamic> json) => WrapPayload(
        questions: (json['questions'] as List? ?? const [])
            .map((e) => PackCheck.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TranslatePayload implements StationPayload {
  /// The sentence to translate, in the learner's native language.
  final String sentence;
  final String hint;

  const TranslatePayload({required this.sentence, this.hint = ''});

  factory TranslatePayload.fromJson(Map<String, dynamic> json) => TranslatePayload(
        // `prompt` was the pre-grading field name; accepted so an older
        // server response does not render a blank station.
        sentence: (json['sentence'] ?? json['prompt']) as String? ?? '',
        hint: json['hint'] as String? ?? '',
      );
}

StationPayload? _payloadFor(String kind, Map<String, dynamic>? json) {
  if (json == null) return null;
  switch (kind) {
    case 'vocabulary':
      return VocabPayload.fromJson(json);
    case 'grammar':
      return GrammarPayload.fromJson(json);
    case 'listening':
      return ListeningPayload.fromJson(json);
    case 'review':
      return ReviewPayload.fromJson(json);
    case 'wrap':
      return WrapPayload.fromJson(json);
    case 'translate':
      return TranslatePayload.fromJson(json);
    default:
      return null;
  }
}

class PackStation {
  final String kind;
  final StationStatus status;
  final int? score;
  final StationPayload? payload;

  const PackStation({
    required this.kind,
    required this.status,
    this.score,
    this.payload,
  });

  bool get isOutstanding => status == StationStatus.todo;

  factory PackStation.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String? ?? '';
    return PackStation(
      kind: kind,
      status: _statusFrom(json['status'] as String?),
      score: (json['score'] as num?)?.toInt(),
      payload: _payloadFor(kind, json['payload'] as Map<String, dynamic>?),
    );
  }
}

class PackTheme {
  final String id;
  final String topic;
  final String level;

  const PackTheme({required this.id, required this.topic, required this.level});

  factory PackTheme.fromJson(Map<String, dynamic> json) => PackTheme(
        id: json['id'].toString(),
        topic: json['topic'] as String? ?? '',
        level: json['level'] as String? ?? '',
      );
}

class DailyPack {
  final bool needsLanguage;
  final String dateKey;
  final String weekKey;
  final int dayInWeek;
  final String? language;
  final String? requestedLevel;
  final String? servedLevel;
  final PackTheme? theme;
  final List<PackStation> stations;
  final bool packComplete;

  /// Whether [requestedLevel] is the learner's own level or the server's A2
  /// fallback. False means nobody has ever asked them, so the card offers the
  /// placement test. Defaults to true so an older server that omits the field
  /// does not nag every learner.
  final bool levelPlaced;

  const DailyPack({
    required this.needsLanguage,
    required this.dateKey,
    required this.weekKey,
    required this.dayInWeek,
    this.language,
    this.requestedLevel,
    this.servedLevel,
    this.theme,
    this.stations = const [],
    this.packComplete = false,
    this.levelPlaced = true,
  });

  PackStation? stationOf(String kind) {
    for (final s in stations) {
      if (s.kind == kind) return s;
    }
    return null;
  }

  /// Stations that need nothing more from the learner. 'empty' counts as
  /// satisfied — a learner with no due words must not sit on 3 of 4 forever.
  int get doneCount => stations.where((s) => s.status != StationStatus.todo).length;

  PackStation? get nextStation {
    for (final s in stations) {
      if (s.isOutstanding) return s;
    }
    return null;
  }

  bool get isLevelFallback =>
      servedLevel != null && requestedLevel != null && servedLevel != requestedLevel;

  factory DailyPack.fromJson(Map<String, dynamic> json) => DailyPack(
        needsLanguage: json['needsLanguage'] as bool? ?? false,
        dateKey: json['dateKey'] as String? ?? '',
        weekKey: json['weekKey'] as String? ?? '',
        dayInWeek: (json['dayInWeek'] as num?)?.toInt() ?? 0,
        language: json['language'] as String?,
        requestedLevel: json['requestedLevel'] as String?,
        servedLevel: json['servedLevel'] as String?,
        theme: json['theme'] == null
            ? null
            : PackTheme.fromJson(json['theme'] as Map<String, dynamic>),
        stations: (json['stations'] as List? ?? const [])
            .map((e) => PackStation.fromJson(e as Map<String, dynamic>))
            .toList(),
        packComplete: json['packComplete'] as bool? ?? false,
        levelPlaced: json['levelPlaced'] as bool? ?? true,
      );
}

class StationResult {
  final int score;
  final int total;
  final int xpAwarded;
  final int? streak;
  final bool packComplete;
  final List<String> stationsRemaining;

  /// Translate station only. Null for every other station; false when the
  /// submission was saved but the grader was unavailable, so the UI can say
  /// so instead of implying a mark.
  final bool? graded;
  final String feedback;
  final String suggestedTranslation;
  final int? aiScore;

  const StationResult({
    required this.score,
    required this.total,
    this.xpAwarded = 0,
    this.streak,
    this.packComplete = false,
    this.stationsRemaining = const [],
    this.graded,
    this.feedback = '',
    this.suggestedTranslation = '',
    this.aiScore,
  });

  factory StationResult.fromJson(Map<String, dynamic> json) => StationResult(
        score: (json['score'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
        streak: (json['streak'] as num?)?.toInt(),
        packComplete: json['packComplete'] as bool? ?? false,
        stationsRemaining: (json['stationsRemaining'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        graded: json['graded'] as bool?,
        feedback: json['feedback'] as String? ?? '',
        suggestedTranslation: json['suggestedTranslation'] as String? ?? '',
        aiScore: (json['aiScore'] as num?)?.toInt(),
      );
}

// ---------------------------------------------------------------------------
// Mastery (spec §7.3) — every number here is derived from data the learner
// actually generated.
// ---------------------------------------------------------------------------

class VocabMastery {
  final int mastered;
  final int learning;
  final int fresh;
  final int due;

  const VocabMastery({
    required this.mastered,
    required this.learning,
    required this.fresh,
    required this.due,
  });

  int get total => mastered + learning + fresh;

  factory VocabMastery.fromJson(Map<String, dynamic> json) => VocabMastery(
        mastered: (json['mastered'] as num?)?.toInt() ?? 0,
        learning: (json['learning'] as num?)?.toInt() ?? 0,
        fresh: (json['fresh'] as num?)?.toInt() ?? 0,
        due: (json['due'] as num?)?.toInt() ?? 0,
      );
}

class GrammarSection {
  final String section;
  final int mastered;
  final int total;

  const GrammarSection({
    required this.section,
    required this.mastered,
    required this.total,
  });

  factory GrammarSection.fromJson(Map<String, dynamic> json) => GrammarSection(
        section: json['section'] as String? ?? '',
        mastered: (json['mastered'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

class GrammarProgress {
  final int mastered;
  final int total;
  final List<GrammarSection> sections;

  const GrammarProgress({
    required this.mastered,
    required this.total,
    required this.sections,
  });

  factory GrammarProgress.fromJson(Map<String, dynamic> json) => GrammarProgress(
        mastered: (json['mastered'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        sections: (json['sections'] as List? ?? const [])
            .map((e) => GrammarSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SkillAccuracy {
  /// Null means "not started" — distinct from 0.0, which means "tried and
  /// missed everything". Showing 0% to someone who never began is a lie.
  final double? accuracy;
  final int samples;

  const SkillAccuracy({required this.accuracy, required this.samples});

  factory SkillAccuracy.fromJson(Map<String, dynamic> json) => SkillAccuracy(
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        samples: (json['samples'] as num?)?.toInt() ?? 0,
      );
}

class MasterySummary {
  final String level;
  final String book;
  final VocabMastery vocabulary;
  final GrammarProgress grammar;
  final SkillAccuracy listening;
  final SkillAccuracy translate;
  final List<String> consistencyDays;

  const MasterySummary({
    required this.level,
    required this.book,
    required this.vocabulary,
    required this.grammar,
    required this.listening,
    required this.translate,
    this.consistencyDays = const [],
  });

  factory MasterySummary.fromJson(Map<String, dynamic> json) => MasterySummary(
        level: json['level'] as String? ?? '',
        book: json['book'] as String? ?? '',
        vocabulary:
            VocabMastery.fromJson((json['vocabulary'] as Map<String, dynamic>?) ?? const {}),
        grammar: GrammarProgress.fromJson((json['grammar'] as Map<String, dynamic>?) ?? const {}),
        listening: SkillAccuracy.fromJson((json['listening'] as Map<String, dynamic>?) ?? const {}),
        translate: SkillAccuracy.fromJson((json['translate'] as Map<String, dynamic>?) ?? const {}),
        consistencyDays:
            ((json['consistency'] as Map<String, dynamic>?)?['days'] as List? ?? const [])
                .map((e) => e.toString())
                .toList(),
      );
}
