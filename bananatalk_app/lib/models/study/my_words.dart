/// A word looked up in a chat that the learner may keep or dismiss.
class WordCandidate {
  const WordCandidate({
    required this.id,
    required this.text,
    required this.translation,
    required this.language,
    this.partOfSpeech,
    this.seenCount = 0,
  });

  final String id, text, translation, language;
  final String? partOfSpeech;
  final int seenCount;

  /// Null when the row has no `id` or no `text`.
  static WordCandidate? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = _str(raw['id']);
    final text = _str(raw['text']);
    if (id.isEmpty || text.isEmpty) return null;
    final pos = raw['partOfSpeech'];
    return WordCandidate(
      id: id,
      text: text,
      translation: _str(raw['translation']),
      language: _str(raw['language']),
      partOfSpeech: pos is String && pos.isNotEmpty ? pos : null,
      seenCount: _int(raw['seenCount']),
    );
  }
}

/// A mistake from a chat or a check, practised until it is resolved.
class StudyMistakeItem {
  const StudyMistakeItem({
    required this.id,
    required this.original,
    required this.corrected,
    required this.explanation,
    required this.source,
    required this.language,
    this.successes = 0,
  });

  final String id, original, corrected, explanation, source, language;
  final int successes;

  /// Null when the row has no `id` or no `original`.
  static StudyMistakeItem? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = _str(raw['id']);
    final original = _str(raw['original']);
    if (id.isEmpty || original.isEmpty) return null;
    return StudyMistakeItem(
      id: id,
      original: original,
      corrected: _str(raw['corrected']),
      explanation: _str(raw['explanation']),
      source: _str(raw['source']),
      language: _str(raw['language']),
      successes: _int(raw['successes']),
    );
  }
}

/// `GET study/my-words`. Parsing never throws: bad rows are dropped and bad
/// numbers read as 0.
class MyWords {
  const MyWords({
    required this.candidateCount,
    required this.mistakeCount,
    required this.dueWords,
    required this.candidates,
    required this.mistakes,
  });

  final int candidateCount, mistakeCount, dueWords;
  final List<WordCandidate> candidates;
  final List<StudyMistakeItem> mistakes;

  static const MyWords empty = MyWords(
    candidateCount: 0,
    mistakeCount: 0,
    dueWords: 0,
    candidates: [],
    mistakes: [],
  );

  factory MyWords.fromJson(Map<String, dynamic> data) {
    final counts = data['counts'];
    final c = counts is Map ? counts : const {};
    final rawCandidates = data['candidates'];
    final rawMistakes = data['mistakes'];
    return MyWords(
      candidateCount: _int(c['candidates']),
      mistakeCount: _int(c['mistakes']),
      dueWords: _int(c['dueWords']),
      candidates: rawCandidates is List
          ? [
              for (final r in rawCandidates)
                if (WordCandidate.tryParse(r) case final w?) w,
            ]
          : const [],
      mistakes: rawMistakes is List
          ? [
              for (final r in rawMistakes)
                if (StudyMistakeItem.tryParse(r) case final m?) m,
            ]
          : const [],
    );
  }
}

String _str(Object? v) => v is String ? v : '';
int _int(Object? v) => v is num ? v.toInt() : 0;
