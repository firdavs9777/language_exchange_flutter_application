/// AI Lesson Builder Models

class GeneratedLessonResponse {
  final GeneratedLesson lesson;
  final GenerationStats generation;

  GeneratedLessonResponse({
    required this.lesson,
    required this.generation,
  });

  factory GeneratedLessonResponse.fromJson(Map<String, dynamic> json) {
    return GeneratedLessonResponse(
      lesson: GeneratedLesson.fromJson(json['lesson'] as Map<String, dynamic>),
      generation: GenerationStats.fromJson(json['generation'] as Map<String, dynamic>),
    );
  }
}

class GeneratedLesson {
  final String id;
  final String title;
  final String description;
  final String slug;
  final String language;
  final String level;
  final String category;
  final String topic;
  final int exerciseCount;
  final int estimatedMinutes;
  final int xpReward;
  final String? icon;
  final bool isPublished;
  final DateTime? createdAt;

  GeneratedLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.slug,
    required this.language,
    required this.level,
    required this.category,
    required this.topic,
    required this.exerciseCount,
    required this.estimatedMinutes,
    required this.xpReward,
    this.icon,
    this.isPublished = false,
    this.createdAt,
  });

  factory GeneratedLesson.fromJson(Map<String, dynamic> json) {
    return GeneratedLesson(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      level: json['level']?.toString() ?? 'A1',
      category: json['category']?.toString() ?? 'vocabulary',
      topic: json['topic']?.toString() ?? '',
      exerciseCount: json['exerciseCount'] ?? 0,
      estimatedMinutes: json['estimatedMinutes'] ?? 15,
      xpReward: json['xpReward'] ?? 0,
      icon: json['icon']?.toString(),
      isPublished: json['isPublished'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class GenerationStats {
  final int tokensUsed;
  final String estimatedCost;
  final int timeMs;

  GenerationStats({
    required this.tokensUsed,
    required this.estimatedCost,
    required this.timeMs,
  });

  factory GenerationStats.fromJson(Map<String, dynamic> json) {
    return GenerationStats(
      tokensUsed: json['tokensUsed'] ?? 0,
      estimatedCost: json['estimatedCost']?.toString() ?? '\$0.00',
      timeMs: json['timeMs'] ?? 0,
    );
  }
}

class GeneratedExercisesResponse {
  final List<GeneratedExercise> exercises;
  final int count;
  final int tokensUsed;
  final String estimatedCost;

  GeneratedExercisesResponse({
    required this.exercises,
    required this.count,
    required this.tokensUsed,
    required this.estimatedCost,
  });

  factory GeneratedExercisesResponse.fromJson(Map<String, dynamic> json) {
    return GeneratedExercisesResponse(
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => GeneratedExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      count: json['count'] ?? 0,
      tokensUsed: json['tokensUsed'] ?? 0,
      estimatedCost: json['estimatedCost']?.toString() ?? '\$0.00',
    );
  }
}

class GeneratedExercise {
  final String type;
  final String question;
  final String? targetText;
  final List<ExerciseOption>? options;
  final String correctAnswer;
  final List<String> acceptedAnswers;
  final String? hint;
  final String? explanation;
  final int points;

  GeneratedExercise({
    required this.type,
    required this.question,
    this.targetText,
    this.options,
    required this.correctAnswer,
    this.acceptedAnswers = const [],
    this.hint,
    this.explanation,
    this.points = 10,
  });

  factory GeneratedExercise.fromJson(Map<String, dynamic> json) {
    return GeneratedExercise(
      type: json['type']?.toString() ?? 'multiple_choice',
      question: json['question']?.toString() ?? '',
      targetText: json['targetText']?.toString(),
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => ExerciseOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      acceptedAnswers: (json['acceptedAnswers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hint: json['hint']?.toString(),
      explanation: json['explanation']?.toString(),
      points: json['points'] ?? 10,
    );
  }
}

class ExerciseOption {
  final String text;
  final bool isCorrect;

  ExerciseOption({
    required this.text,
    required this.isCorrect,
  });

  factory ExerciseOption.fromJson(Map<String, dynamic> json) {
    return ExerciseOption(
      text: json['text']?.toString() ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}

class GeneratedVocabularyResponse {
  final String topic;
  final List<VocabularyWord> vocabulary;
  final int count;
  final int tokensUsed;
  final String estimatedCost;

  GeneratedVocabularyResponse({
    required this.topic,
    required this.vocabulary,
    required this.count,
    required this.tokensUsed,
    required this.estimatedCost,
  });

  factory GeneratedVocabularyResponse.fromJson(Map<String, dynamic> json) {
    return GeneratedVocabularyResponse(
      topic: json['topic']?.toString() ?? '',
      vocabulary: (json['vocabulary'] as List<dynamic>?)
              ?.map((e) => VocabularyWord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      count: json['count'] ?? 0,
      tokensUsed: json['tokensUsed'] ?? 0,
      estimatedCost: json['estimatedCost']?.toString() ?? '\$0.00',
    );
  }
}

class VocabularyWord {
  final String word;
  final String translation;
  final String? partOfSpeech;
  final String? pronunciation;
  final List<VocabularyExample> examples;
  final String difficulty;
  final List<String> tags;

  VocabularyWord({
    required this.word,
    required this.translation,
    this.partOfSpeech,
    this.pronunciation,
    this.examples = const [],
    this.difficulty = 'easy',
    this.tags = const [],
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      word: json['word']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      partOfSpeech: json['partOfSpeech']?.toString(),
      pronunciation: json['pronunciation']?.toString(),
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => VocabularyExample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      difficulty: json['difficulty']?.toString() ?? 'easy',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class VocabularyExample {
  final String sentence;
  final String translation;

  VocabularyExample({
    required this.sentence,
    required this.translation,
  });

  factory VocabularyExample.fromJson(Map<String, dynamic> json) {
    return VocabularyExample(
      sentence: json['sentence']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
    );
  }
}

class CurriculumResponse {
  final CurriculumInfo curriculum;
  final List<GeneratedLesson> lessons;
  final int tokensUsed;
  final String estimatedCost;

  CurriculumResponse({
    required this.curriculum,
    required this.lessons,
    required this.tokensUsed,
    required this.estimatedCost,
  });

  factory CurriculumResponse.fromJson(Map<String, dynamic> json) {
    return CurriculumResponse(
      curriculum: CurriculumInfo.fromJson(json['curriculum'] as Map<String, dynamic>),
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => GeneratedLesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tokensUsed: json['totalTokens'] ?? json['tokensUsed'] ?? 0,
      estimatedCost: json['totalCost']?.toString() ?? json['estimatedCost']?.toString() ?? '\$0.00',
    );
  }
}

class CurriculumInfo {
  final String title;
  final String description;
  final String level;
  final String language;
  final int unitsCount;
  final int lessonsCount;

  CurriculumInfo({
    required this.title,
    required this.description,
    required this.level,
    required this.language,
    required this.unitsCount,
    required this.lessonsCount,
  });

  factory CurriculumInfo.fromJson(Map<String, dynamic> json) {
    return CurriculumInfo(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      level: json['level']?.toString() ?? 'A1',
      language: json['language']?.toString() ?? '',
      unitsCount: json['unitsCount'] ?? 0,
      lessonsCount: json['lessonsCount'] ?? 0,
    );
  }
}

class EnhanceLessonResponse {
  final GeneratedLesson lesson;
  final AddedContent added;
  final int tokensUsed;
  final String estimatedCost;

  EnhanceLessonResponse({
    required this.lesson,
    required this.added,
    required this.tokensUsed,
    required this.estimatedCost,
  });

  factory EnhanceLessonResponse.fromJson(Map<String, dynamic> json) {
    return EnhanceLessonResponse(
      lesson: GeneratedLesson.fromJson(json['lesson'] as Map<String, dynamic>),
      added: AddedContent.fromJson(json['added'] as Map<String, dynamic>),
      tokensUsed: json['tokensUsed'] ?? 0,
      estimatedCost: json['estimatedCost']?.toString() ?? '\$0.00',
    );
  }
}

class AddedContent {
  final int content;
  final int exercises;

  AddedContent({
    required this.content,
    required this.exercises,
  });

  factory AddedContent.fromJson(Map<String, dynamic> json) {
    return AddedContent(
      content: json['content'] ?? 0,
      exercises: json['exercises'] ?? 0,
    );
  }
}

class LessonTemplatesResponse {
  final List<LessonTemplate> templates;
  final List<String> levels;
  final List<SupportedLanguage> supportedLanguages;

  LessonTemplatesResponse({
    required this.templates,
    required this.levels,
    required this.supportedLanguages,
  });

  factory LessonTemplatesResponse.fromJson(Map<String, dynamic> json) {
    return LessonTemplatesResponse(
      templates: (json['templates'] as List<dynamic>?)
              ?.map((e) => LessonTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      levels: (json['levels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
      supportedLanguages: (json['supportedLanguages'] as List<dynamic>?)
              ?.map((e) => SupportedLanguage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class LessonTemplate {
  final String category;
  final String icon;
  final List<String> exerciseTypes;
  final Map<String, int> exerciseDistribution;

  LessonTemplate({
    required this.category,
    required this.icon,
    required this.exerciseTypes,
    required this.exerciseDistribution,
  });

  factory LessonTemplate.fromJson(Map<String, dynamic> json) {
    return LessonTemplate(
      category: json['category']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      exerciseTypes: (json['exerciseTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      exerciseDistribution: (json['exerciseDistribution'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }
}

class SupportedLanguage {
  final String code;
  final String name;

  SupportedLanguage({
    required this.code,
    required this.name,
  });

  factory SupportedLanguage.fromJson(Map<String, dynamic> json) {
    return SupportedLanguage(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class LessonGenerationStats {
  final int totalAILessons;
  final List<CountByField> byLevel;
  final List<CountByField> byCategory;
  final List<CountByField> byLanguage;
  final TokenUsageStats tokenUsage;
  final int averageGenerationTime;

  LessonGenerationStats({
    required this.totalAILessons,
    required this.byLevel,
    required this.byCategory,
    required this.byLanguage,
    required this.tokenUsage,
    required this.averageGenerationTime,
  });

  factory LessonGenerationStats.fromJson(Map<String, dynamic> json) {
    return LessonGenerationStats(
      totalAILessons: json['totalAILessons'] ?? 0,
      byLevel: (json['byLevel'] as List<dynamic>?)
              ?.map((e) => CountByField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      byCategory: (json['byCategory'] as List<dynamic>?)
              ?.map((e) => CountByField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      byLanguage: (json['byLanguage'] as List<dynamic>?)
              ?.map((e) => CountByField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tokenUsage: TokenUsageStats.fromJson(json['tokenUsage'] as Map<String, dynamic>? ?? {}),
      averageGenerationTime: json['averageGenerationTime'] ?? 0,
    );
  }
}

class CountByField {
  final String id;
  final int count;

  CountByField({
    required this.id,
    required this.count,
  });

  factory CountByField.fromJson(Map<String, dynamic> json) {
    return CountByField(
      id: json['_id']?.toString() ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class TokenUsageStats {
  final int total;
  final int average;
  final String estimatedTotalCost;

  TokenUsageStats({
    required this.total,
    required this.average,
    required this.estimatedTotalCost,
  });

  factory TokenUsageStats.fromJson(Map<String, dynamic> json) {
    return TokenUsageStats(
      total: json['total'] ?? 0,
      average: json['average'] ?? 0,
      estimatedTotalCost: json['estimatedTotalCost']?.toString() ?? '\$0.00',
    );
  }
}

/// Request classes

class GenerateLessonRequest {
  final String language;
  final String topic;
  final String level;
  final String category;
  final int exerciseCount;
  final String? nativeLanguage;
  final int? unitNumber;
  final String? unitName;

  GenerateLessonRequest({
    required this.language,
    required this.topic,
    this.level = 'A1',
    this.category = 'vocabulary',
    this.exerciseCount = 10,
    this.nativeLanguage,
    this.unitNumber,
    this.unitName,
  });

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'topic': topic,
      'level': level,
      'category': category,
      'exerciseCount': exerciseCount,
      if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
      if (unitNumber != null) 'unitNumber': unitNumber,
      if (unitName != null) 'unitName': unitName,
    };
  }
}

class GenerateExercisesRequest {
  final String language;
  final String topic;
  final String level;
  final String? category;
  final List<String>? exerciseTypes;
  final int count;
  final List<String>? vocabulary;
  final String? context;

  GenerateExercisesRequest({
    required this.language,
    required this.topic,
    this.level = 'A1',
    this.category,
    this.exerciseTypes,
    this.count = 10,
    this.vocabulary,
    this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'topic': topic,
      'level': level,
      if (category != null) 'category': category,
      if (exerciseTypes != null) 'exerciseTypes': exerciseTypes,
      'count': count,
      if (vocabulary != null) 'vocabulary': vocabulary,
      if (context != null) 'context': context,
    };
  }
}

class GenerateVocabularyRequest {
  final String language;
  final String topic;
  final String level;
  final int count;
  final String? nativeLanguage;

  GenerateVocabularyRequest({
    required this.language,
    required this.topic,
    this.level = 'A1',
    this.count = 20,
    this.nativeLanguage,
  });

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'topic': topic,
      'level': level,
      'count': count,
      if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
    };
  }
}

class GenerateCurriculumRequest {
  final String language;
  final String level;
  final int lessonsPerUnit;
  final int unitsCount;
  final List<String>? categories;
  final String? nativeLanguage;

  GenerateCurriculumRequest({
    required this.language,
    this.level = 'A1',
    this.lessonsPerUnit = 5,
    this.unitsCount = 3,
    this.categories,
    this.nativeLanguage,
  });

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'level': level,
      'lessonsPerUnit': lessonsPerUnit,
      'unitsCount': unitsCount,
      if (categories != null) 'categories': categories,
      if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
    };
  }
}

class EnhanceLessonRequest {
  final int addExercises;
  final bool addContent;
  final bool addTips;

  EnhanceLessonRequest({
    this.addExercises = 5,
    this.addContent = true,
    this.addTips = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'addExercises': addExercises,
      'addContent': addContent,
      'addTips': addTips,
    };
  }
}
