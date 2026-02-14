/// Speech Models for TTS, STT, and Pronunciation

class TTSRequest {
  final String text;
  final String language;
  final String voice;
  final double speed;
  final String format;

  TTSRequest({
    required this.text,
    required this.language,
    this.voice = 'nova',
    this.speed = 1.0,
    this.format = 'mp3',
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'language': language,
      'voice': voice,
      'speed': speed,
      'format': format,
    };
  }
}

class TTSResponse {
  final String audioUrl;
  final String text;
  final String language;
  final String voice;
  final int durationMs;

  TTSResponse({
    required this.audioUrl,
    required this.text,
    required this.language,
    required this.voice,
    required this.durationMs,
  });

  factory TTSResponse.fromJson(Map<String, dynamic> json) {
    return TTSResponse(
      audioUrl: json['audioUrl']?.toString() ?? json['url']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      voice: json['voice']?.toString() ?? 'nova',
      durationMs: json['durationMs'] ?? json['duration'] ?? 0,
    );
  }
}

class STTResponse {
  final String text;
  final String language;
  final double confidence;
  final List<WordSegment>? segments;

  STTResponse({
    required this.text,
    required this.language,
    required this.confidence,
    this.segments,
  });

  factory STTResponse.fromJson(Map<String, dynamic> json) {
    return STTResponse(
      text: json['text']?.toString() ?? json['transcript']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      segments: (json['segments'] as List<dynamic>?)
          ?.map((e) => WordSegment.fromJson(e))
          .toList(),
    );
  }
}

class WordSegment {
  final String word;
  final double start;
  final double end;
  final double confidence;

  WordSegment({
    required this.word,
    required this.start,
    required this.end,
    required this.confidence,
  });

  factory WordSegment.fromJson(Map<String, dynamic> json) {
    return WordSegment(
      word: json['word']?.toString() ?? '',
      start: (json['start'] as num?)?.toDouble() ?? 0.0,
      end: (json['end'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PronunciationResult {
  final String id;
  final String targetText;
  final String transcribedText;
  final String language;
  final int overallScore;
  final int accuracyScore;
  final int fluencyScore;
  final int completenessScore;
  final List<WordPronunciation> words;
  final String feedback;
  final List<String> suggestions;
  final String source;
  final String? vocabularyId;
  final DateTime createdAt;

  PronunciationResult({
    required this.id,
    required this.targetText,
    required this.transcribedText,
    required this.language,
    required this.overallScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    this.words = const [],
    required this.feedback,
    this.suggestions = const [],
    required this.source,
    this.vocabularyId,
    required this.createdAt,
  });

  factory PronunciationResult.fromJson(Map<String, dynamic> json) {
    return PronunciationResult(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      targetText: json['targetText']?.toString() ?? '',
      transcribedText: json['transcribedText']?.toString() ?? json['transcription']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      overallScore: json['overallScore'] ?? json['score'] ?? 0,
      accuracyScore: json['accuracyScore'] ?? json['accuracy'] ?? 0,
      fluencyScore: json['fluencyScore'] ?? json['fluency'] ?? 0,
      completenessScore: json['completenessScore'] ?? json['completeness'] ?? 0,
      words: (json['words'] as List<dynamic>?)
              ?.map((e) => WordPronunciation.fromJson(e))
              .toList() ??
          [],
      feedback: json['feedback']?.toString() ?? '',
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      source: json['source']?.toString() ?? 'practice',
      vocabularyId: json['vocabularyId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isExcellent => overallScore >= 90;
  bool get isGood => overallScore >= 70;
  bool get needsPractice => overallScore < 70;

  String get scoreGrade {
    if (overallScore >= 90) return 'A';
    if (overallScore >= 80) return 'B';
    if (overallScore >= 70) return 'C';
    if (overallScore >= 60) return 'D';
    return 'F';
  }
}

class WordPronunciation {
  final String word;
  final String expectedPhonemes;
  final String actualPhonemes;
  final int score;
  final bool isCorrect;
  final String? suggestion;

  WordPronunciation({
    required this.word,
    this.expectedPhonemes = '',
    this.actualPhonemes = '',
    required this.score,
    required this.isCorrect,
    this.suggestion,
  });

  factory WordPronunciation.fromJson(Map<String, dynamic> json) {
    return WordPronunciation(
      word: json['word']?.toString() ?? '',
      expectedPhonemes: json['expectedPhonemes']?.toString() ?? '',
      actualPhonemes: json['actualPhonemes']?.toString() ?? '',
      score: json['score'] ?? 0,
      isCorrect: json['isCorrect'] ?? false,
      suggestion: json['suggestion']?.toString(),
    );
  }
}

class PronunciationStats {
  final int totalAttempts;
  final double averageScore;
  final int perfectScores;
  final Map<String, double> categoryScores;
  final List<WeakWord> weakWords;
  final int streak;

  PronunciationStats({
    required this.totalAttempts,
    required this.averageScore,
    required this.perfectScores,
    this.categoryScores = const {},
    this.weakWords = const [],
    this.streak = 0,
  });

  factory PronunciationStats.fromJson(Map<String, dynamic> json) {
    return PronunciationStats(
      totalAttempts: json['totalAttempts'] ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      perfectScores: json['perfectScores'] ?? 0,
      categoryScores: (json['categoryScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      weakWords: (json['weakWords'] as List<dynamic>?)
              ?.map((e) => WeakWord.fromJson(e))
              .toList() ??
          [],
      streak: json['streak'] ?? 0,
    );
  }
}

class WeakWord {
  final String word;
  final double averageScore;
  final int attempts;

  WeakWord({
    required this.word,
    required this.averageScore,
    required this.attempts,
  });

  factory WeakWord.fromJson(Map<String, dynamic> json) {
    return WeakWord(
      word: json['word']?.toString() ?? '',
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      attempts: json['attempts'] ?? 0,
    );
  }
}

class VoiceOption {
  final String id;
  final String name;
  final String gender;
  final String language;
  final String preview;

  VoiceOption({
    required this.id,
    required this.name,
    required this.gender,
    required this.language,
    this.preview = '',
  });

  factory VoiceOption.fromJson(Map<String, dynamic> json) {
    return VoiceOption(
      id: json['id']?.toString() ?? json['voice']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'neutral',
      language: json['language']?.toString() ?? '',
      preview: json['preview']?.toString() ?? '',
    );
  }
}

/// Available TTS voices
class TTSVoices {
  static const List<Map<String, String>> voices = [
    {'id': 'alloy', 'name': 'Alloy', 'gender': 'neutral'},
    {'id': 'echo', 'name': 'Echo', 'gender': 'male'},
    {'id': 'fable', 'name': 'Fable', 'gender': 'neutral'},
    {'id': 'onyx', 'name': 'Onyx', 'gender': 'male'},
    {'id': 'nova', 'name': 'Nova', 'gender': 'female'},
    {'id': 'shimmer', 'name': 'Shimmer', 'gender': 'female'},
  ];

  static String getVoiceName(String id) {
    final voice = voices.firstWhere(
      (v) => v['id'] == id,
      orElse: () => {'name': id},
    );
    return voice['name'] ?? id;
  }
}
