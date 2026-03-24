/// Enhanced Translation Models

class EnhancedTranslation {
  final String originalText;
  final String translation;
  final String sourceLanguage;
  final String targetLanguage;
  final List<TranslationAlternative> alternatives;
  final TranslationBreakdown? breakdown;
  final List<GrammarNote> grammarNotes;
  final List<IdiomInfo> idioms;
  final String? culturalContext;
  final DateTime createdAt;

  EnhancedTranslation({
    required this.originalText,
    required this.translation,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.alternatives = const [],
    this.breakdown,
    this.grammarNotes = const [],
    this.idioms = const [],
    this.culturalContext,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory EnhancedTranslation.fromJson(Map<String, dynamic> json) {
    // Handle breakdown - API returns array directly, not nested object
    TranslationBreakdown? breakdown;
    final breakdownData = json['breakdown'];
    if (breakdownData != null) {
      if (breakdownData is List) {
        // API returns breakdown as array of word objects
        breakdown = TranslationBreakdown.fromWordsList(breakdownData);
      } else if (breakdownData is Map) {
        breakdown = TranslationBreakdown.fromJson(Map<String, dynamic>.from(breakdownData));
      }
    }

    // Handle grammar - API uses 'grammar' instead of 'grammarNotes'
    final grammarList = json['grammarNotes'] ?? json['grammar'];

    // Handle cultural - API returns object with 'notes' field
    String? culturalContext = json['culturalContext']?.toString();
    if (culturalContext == null && json['cultural'] != null) {
      final cultural = json['cultural'];
      if (cultural is Map) {
        culturalContext = cultural['notes']?.toString();
      } else if (cultural is String) {
        culturalContext = cultural;
      }
    }

    return EnhancedTranslation(
      originalText: json['originalText']?.toString() ?? json['text']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      sourceLanguage: json['sourceLanguage']?.toString() ?? '',
      targetLanguage: json['targetLanguage']?.toString() ?? '',
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => TranslationAlternative.fromJson(e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}))
              .toList() ??
          [],
      breakdown: breakdown,
      grammarNotes: (grammarList as List<dynamic>?)
              ?.map((e) => GrammarNote.fromJson(e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}))
              .toList() ??
          [],
      idioms: (json['idioms'] as List<dynamic>?)
              ?.map((e) => IdiomInfo.fromJson(e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}))
              .toList() ??
          [],
      culturalContext: culturalContext,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  bool get hasAlternatives => alternatives.isNotEmpty;
  bool get hasIdioms => idioms.isNotEmpty;
  bool get hasGrammarNotes => grammarNotes.isNotEmpty;
}

class TranslationAlternative {
  final String text;
  final String formality; // formal, informal, neutral
  final String context;
  final double confidence;

  TranslationAlternative({
    required this.text,
    required this.formality,
    required this.context,
    required this.confidence,
  });

  factory TranslationAlternative.fromJson(Map<String, dynamic> json) {
    return TranslationAlternative(
      text: json['text']?.toString() ?? json['translation']?.toString() ?? '',
      formality: json['formality']?.toString() ?? 'neutral',
      context: json['context']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get formalityIcon {
    switch (formality) {
      case 'formal':
        return '👔';
      case 'informal':
        return '😊';
      default:
        return '📝';
    }
  }
}

class TranslationBreakdown {
  final List<WordBreakdown> words;
  final String structure;
  final String explanation;

  TranslationBreakdown({
    this.words = const [],
    this.structure = '',
    this.explanation = '',
  });

  factory TranslationBreakdown.fromJson(Map<String, dynamic> json) {
    return TranslationBreakdown(
      words: (json['words'] as List<dynamic>?)
              ?.map((e) => WordBreakdown.fromJson(e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}))
              .toList() ??
          [],
      structure: json['structure']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  /// Create from API response where breakdown is a direct array of words
  factory TranslationBreakdown.fromWordsList(List<dynamic> wordsList) {
    return TranslationBreakdown(
      words: wordsList
          .where((e) => e is Map)
          .map((e) => WordBreakdown.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      structure: '',
      explanation: '',
    );
  }
}

class WordBreakdown {
  final String original;
  final String translation;
  final String partOfSpeech;
  final String? pronunciation;
  final List<String> alternatives;

  WordBreakdown({
    required this.original,
    required this.translation,
    required this.partOfSpeech,
    this.pronunciation,
    this.alternatives = const [],
  });

  factory WordBreakdown.fromJson(Map<String, dynamic> json) {
    return WordBreakdown(
      // API may use 'word' or 'original'
      original: json['original']?.toString() ?? json['word']?.toString() ?? '',
      // API may use 'translation', 'translated', or 'meaning'
      translation: json['translation']?.toString() ?? json['translated']?.toString() ?? json['meaning']?.toString() ?? '',
      partOfSpeech: json['partOfSpeech']?.toString() ?? '',
      pronunciation: json['pronunciation']?.toString() ?? json['notes']?.toString(),
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  String get posAbbreviation {
    switch (partOfSpeech.toLowerCase()) {
      case 'noun':
        return 'n.';
      case 'verb':
        return 'v.';
      case 'adjective':
        return 'adj.';
      case 'adverb':
        return 'adv.';
      case 'preposition':
        return 'prep.';
      case 'conjunction':
        return 'conj.';
      case 'pronoun':
        return 'pron.';
      case 'article':
        return 'art.';
      default:
        return partOfSpeech;
    }
  }
}

class GrammarNote {
  final String topic;
  final String explanation;
  final String sourceExample;
  final String targetExample;
  final String? tip;

  GrammarNote({
    required this.topic,
    required this.explanation,
    required this.sourceExample,
    required this.targetExample,
    this.tip,
  });

  factory GrammarNote.fromJson(Map<String, dynamic> json) {
    // API uses 'aspect' instead of 'topic', 'sourceRule'/'targetRule' instead of examples
    return GrammarNote(
      topic: json['topic']?.toString() ?? json['aspect']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? json['sourceRule']?.toString() ?? '',
      sourceExample: json['sourceExample']?.toString() ?? json['example']?.toString() ?? '',
      targetExample: json['targetExample']?.toString() ?? json['targetRule']?.toString() ?? '',
      tip: json['tip']?.toString(),
    );
  }
}

class IdiomInfo {
  final String original;
  final String literalTranslation;
  final String meaning;
  final String equivalentIdiom;
  final String usage;
  final List<String> examples;

  IdiomInfo({
    required this.original,
    required this.literalTranslation,
    required this.meaning,
    required this.equivalentIdiom,
    required this.usage,
    this.examples = const [],
  });

  factory IdiomInfo.fromJson(Map<String, dynamic> json) {
    return IdiomInfo(
      original: json['original']?.toString() ?? json['idiom']?.toString() ?? '',
      // API uses 'literal' instead of 'literalTranslation'
      literalTranslation: json['literalTranslation']?.toString() ?? json['literal']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      equivalentIdiom: json['equivalentIdiom']?.toString() ?? json['equivalent']?.toString() ?? '',
      usage: json['usage']?.toString() ?? '',
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Request for enhanced translation
class EnhancedTranslationRequest {
  final String text;
  final String sourceLanguage;
  final String targetLanguage;
  final String? nativeLanguage;
  final bool includeBreakdown;
  final bool includeGrammar;
  final bool includeIdioms;

  EnhancedTranslationRequest({
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.nativeLanguage,
    this.includeBreakdown = true,
    this.includeGrammar = true,
    this.includeIdioms = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
      'includeBreakdown': includeBreakdown,
      'includeGrammar': includeGrammar,
      'includeIdioms': includeIdioms,
    };
  }
}

/// Request for contextual translation
class ContextualTranslationRequest {
  final String text;
  final String sourceLanguage;
  final String targetLanguage;
  final String context;
  final String? tone;
  final String? audience;

  ContextualTranslationRequest({
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.context,
    this.tone,
    this.audience,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'context': context,
      if (tone != null) 'tone': tone,
      if (audience != null) 'audience': audience,
    };
  }
}

/// Popular translation for quick reference
class PopularTranslation {
  final String text;
  final String translation;
  final String sourceLanguage;
  final String targetLanguage;
  final int usageCount;

  PopularTranslation({
    required this.text,
    required this.translation,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.usageCount,
  });

  factory PopularTranslation.fromJson(Map<String, dynamic> json) {
    return PopularTranslation(
      text: json['text']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      sourceLanguage: json['sourceLanguage']?.toString() ?? '',
      targetLanguage: json['targetLanguage']?.toString() ?? '',
      usageCount: json['usageCount'] ?? 0,
    );
  }
}
