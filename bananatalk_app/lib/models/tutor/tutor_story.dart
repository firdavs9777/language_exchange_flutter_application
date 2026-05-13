// DTOs matching the backend tutorStoryService output.

class StoryQuestion {
  final String q;
  final List<String> options;
  final int correctIdx;

  StoryQuestion({
    required this.q,
    required this.options,
    required this.correctIdx,
  });

  factory StoryQuestion.fromJson(Map<String, dynamic> j) => StoryQuestion(
        q: j['q']?.toString() ?? '',
        options: ((j['options'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        correctIdx: (j['correctIdx'] as num?)?.toInt() ?? 0,
      );
}

class StoryParagraph {
  final String text;
  final StoryQuestion? question;

  StoryParagraph({required this.text, required this.question});

  factory StoryParagraph.fromJson(Map<String, dynamic> j) => StoryParagraph(
        text: j['text']?.toString() ?? '',
        question: j['question'] is Map<String, dynamic>
            ? StoryQuestion.fromJson(j['question'] as Map<String, dynamic>)
            : null,
      );
}

class StoryVocabEntry {
  final String word;
  final String definition;
  StoryVocabEntry({required this.word, required this.definition});
  factory StoryVocabEntry.fromJson(Map<String, dynamic> j) => StoryVocabEntry(
        word: j['word']?.toString() ?? '',
        definition: j['definition']?.toString() ?? '',
      );
}

class TutorStory {
  final String title;
  final String theme;
  final String level;
  final String targetLanguage;
  final List<StoryParagraph> paragraphs;
  final List<StoryVocabEntry> vocabUsed;

  TutorStory({
    required this.title,
    required this.theme,
    required this.level,
    required this.targetLanguage,
    required this.paragraphs,
    required this.vocabUsed,
  });

  factory TutorStory.fromJson(Map<String, dynamic> j) => TutorStory(
        title: j['title']?.toString() ?? 'Untitled',
        theme: j['theme']?.toString() ?? 'free',
        level: j['level']?.toString() ?? 'A2',
        targetLanguage: j['targetLanguage']?.toString() ?? '',
        paragraphs: ((j['paragraphs'] as List?) ?? const [])
            .map((e) => StoryParagraph.fromJson(e as Map<String, dynamic>))
            .toList(),
        vocabUsed: ((j['vocabUsed'] as List?) ?? const [])
            .map((e) => StoryVocabEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
