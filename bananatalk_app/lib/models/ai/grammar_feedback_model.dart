/// Grammar Feedback Models

class GrammarFeedback {
  final String id;
  final String originalText;
  final String correctedText;
  final String targetLanguage;
  final String? nativeLanguage;
  final String cefrLevel;
  final List<GrammarError> errors;
  final List<GrammarSuggestion> suggestions;
  final List<String> positives;
  final int overallScore;
  final String summary;
  final int errorCount;
  final bool isPerfect;
  final bool viewed;
  final DateTime createdAt;

  GrammarFeedback({
    required this.id,
    required this.originalText,
    required this.correctedText,
    required this.targetLanguage,
    this.nativeLanguage,
    required this.cefrLevel,
    this.errors = const [],
    this.suggestions = const [],
    this.positives = const [],
    required this.overallScore,
    required this.summary,
    this.errorCount = 0,
    this.isPerfect = false,
    this.viewed = false,
    required this.createdAt,
  });

  factory GrammarFeedback.fromJson(Map<String, dynamic> json) {
    // Parse errors list
    List<GrammarError> errors = [];
    if (json['errors'] != null && json['errors'] is List) {
      errors = (json['errors'] as List<dynamic>)
          .where((e) => e is Map)
          .map((e) => GrammarError.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Parse suggestions list - API returns array of suggestion objects
    List<GrammarSuggestion> suggestions = [];
    if (json['suggestions'] != null && json['suggestions'] is List) {
      suggestions = (json['suggestions'] as List<dynamic>)
          .where((e) => e is Map)
          .map((e) => GrammarSuggestion.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Parse positives - array of strings
    List<String> positives = [];
    if (json['positives'] != null && json['positives'] is List) {
      positives = (json['positives'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return GrammarFeedback(
      id: json['_id']?.toString() ?? json['feedbackId']?.toString() ?? '',
      originalText: json['originalText']?.toString() ?? json['text']?.toString() ?? '',
      correctedText: json['correctedText']?.toString() ?? '',
      targetLanguage: json['targetLanguage']?.toString() ?? '',
      nativeLanguage: json['nativeLanguage']?.toString(),
      cefrLevel: json['cefrLevel']?.toString() ?? 'B1',
      errors: errors,
      suggestions: suggestions,
      positives: positives,
      overallScore: json['overallScore'] ?? json['score'] ?? 0,
      summary: json['summary']?.toString() ?? json['overallFeedback']?.toString() ?? json['feedback']?.toString() ?? '',
      errorCount: json['errorCount'] ?? errors.length,
      isPerfect: json['isPerfect'] == true,
      viewed: json['viewed'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isExcellent => overallScore >= 90;
  bool get isGood => overallScore >= 70;
  bool get needsImprovement => overallScore < 70;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
  bool get hasPositives => positives.isNotEmpty;

  // Aliases for compatibility
  String get feedback => summary;
  String get overallFeedback => summary;
}

/// Suggestion for improving text
class GrammarSuggestion {
  final String type; // improvement, alternative
  final String text;
  final String explanation;

  GrammarSuggestion({
    required this.type,
    required this.text,
    required this.explanation,
  });

  factory GrammarSuggestion.fromJson(Map<String, dynamic> json) {
    return GrammarSuggestion(
      type: json['type']?.toString() ?? 'improvement',
      text: json['text']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

class GrammarError {
  final String type; // spelling, grammar, punctuation, style
  final String severity; // minor, moderate, major
  final String original;
  final String corrected;
  final String explanation;
  final String? rule;
  final int startIndex;
  final int endIndex;
  final List<String> examples;

  GrammarError({
    required this.type,
    required this.severity,
    required this.original,
    required this.corrected,
    required this.explanation,
    this.rule,
    required this.startIndex,
    required this.endIndex,
    this.examples = const [],
  });

  factory GrammarError.fromJson(Map<String, dynamic> json) {
    // Parse examples - can be array of strings
    List<String> examples = [];
    if (json['examples'] != null && json['examples'] is List) {
      examples = (json['examples'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return GrammarError(
      type: json['type']?.toString() ?? 'grammar',
      severity: json['severity']?.toString() ?? 'moderate',
      // API uses 'originalSegment' and 'correctedSegment'
      original: json['original']?.toString() ??
                json['originalSegment']?.toString() ?? '',
      corrected: json['corrected']?.toString() ??
                 json['correctedSegment']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      rule: json['rule']?.toString(),
      startIndex: json['startIndex'] ?? 0,
      endIndex: json['endIndex'] ?? json['startIndex'] ?? 0,
      examples: examples,
    );
  }

  bool get isMinor => severity == 'minor';
  bool get isMajor => severity == 'major';
  bool get isModerate => severity == 'moderate';
  String get message => explanation;
  bool get hasRule => rule != null && rule!.isNotEmpty;
  bool get hasExamples => examples.isNotEmpty;

  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'spelling':
        return '📝';
      case 'grammar':
        return '📚';
      case 'punctuation':
        return '✏️';
      case 'style':
        return '🎨';
      case 'vocabulary':
        return '📖';
      default:
        return '❓';
    }
  }

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'spelling':
        return 'Spelling';
      case 'grammar':
        return 'Grammar';
      case 'punctuation':
        return 'Punctuation';
      case 'style':
        return 'Style';
      case 'vocabulary':
        return 'Vocabulary';
      default:
        return type;
    }
  }
}

class GrammarRuleExplanation {
  final String rule;
  final String title;
  final String explanation;
  final List<RuleExample> examples;
  final List<String> commonMistakes;
  final List<String> tips;

  GrammarRuleExplanation({
    required this.rule,
    required this.title,
    required this.explanation,
    this.examples = const [],
    this.commonMistakes = const [],
    this.tips = const [],
  });

  factory GrammarRuleExplanation.fromJson(Map<String, dynamic> json) {
    return GrammarRuleExplanation(
      rule: json['rule']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => RuleExample.fromJson(e))
              .toList() ??
          [],
      commonMistakes: (json['commonMistakes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tips: (json['tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class RuleExample {
  final String correct;
  final String incorrect;
  final String explanation;

  RuleExample({
    required this.correct,
    required this.incorrect,
    required this.explanation,
  });

  factory RuleExample.fromJson(Map<String, dynamic> json) {
    return RuleExample(
      correct: json['correct']?.toString() ?? '',
      incorrect: json['incorrect']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

/// Request for grammar analysis
class AnalyzeGrammarRequest {
  final String text;
  final String targetLanguage;
  final String? nativeLanguage;
  final String? cefrLevel;

  AnalyzeGrammarRequest({
    required this.text,
    required this.targetLanguage,
    this.nativeLanguage,
    this.cefrLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'targetLanguage': targetLanguage,
      if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
      if (cefrLevel != null) 'cefrLevel': cefrLevel,
    };
  }
}

/// Request for rule explanation
class ExplainRuleRequest {
  final String rule;
  final String targetLanguage;
  final String? nativeLanguage;
  final String? cefrLevel;

  ExplainRuleRequest({
    required this.rule,
    required this.targetLanguage,
    this.nativeLanguage,
    this.cefrLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'rule': rule,
      'targetLanguage': targetLanguage,
      if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
      if (cefrLevel != null) 'cefrLevel': cefrLevel,
    };
  }
}
