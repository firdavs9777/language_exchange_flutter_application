import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';

// ==================== VOCABULARY PROVIDERS ====================

/// Vocabulary filter state
class VocabularyFilter {
  final String? language;
  final String? srsLevel;
  final String? search;
  final int limit;
  final int offset;

  const VocabularyFilter({
    this.language,
    this.srsLevel,
    this.search,
    this.limit = 50,
    this.offset = 0,
  });

  /// Copy with explicit null support using named parameters
  /// Use clearSrsLevel: true to explicitly set srsLevel to null
  /// Use clearSearch: true to explicitly set search to null
  VocabularyFilter copyWith({
    String? language,
    String? srsLevel,
    String? search,
    int? limit,
    int? offset,
    bool clearSrsLevel = false,
    bool clearSearch = false,
    bool clearLanguage = false,
  }) {
    return VocabularyFilter(
      language: clearLanguage ? null : (language ?? this.language),
      srsLevel: clearSrsLevel ? null : (srsLevel ?? this.srsLevel),
      search: clearSearch ? null : (search ?? this.search),
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VocabularyFilter &&
        other.language == language &&
        other.srsLevel == srsLevel &&
        other.search == search &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(language, srsLevel, search, limit, offset);
}

/// Vocabulary filter state provider
final vocabularyFilterProvider = StateProvider<VocabularyFilter>((ref) {
  return const VocabularyFilter();
});

/// Vocabulary list provider
final vocabularyListProvider =
    FutureProvider.family<List<VocabularyItem>, VocabularyFilter>(
        (ref, filter) async {
  try {
    final result = await LearningService.getVocabulary(
      language: filter.language,
      srsLevel: filter.srsLevel,
      search: filter.search,
      limit: filter.limit,
      offset: filter.offset,
    );
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List) {
        return data.map((e) => VocabularyItem.fromJson(e)).toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Filtered vocabulary list (uses current filter state)
final filteredVocabularyProvider =
    FutureProvider<List<VocabularyItem>>((ref) async {
  final filter = ref.watch(vocabularyFilterProvider);
  final result = await ref.watch(vocabularyListProvider(filter).future);
  return result;
});

/// Due reviews provider
final dueReviewsProvider =
    FutureProvider.family<DueWordsResponse?, String?>((ref, language) async {
  try {
    final result = await LearningService.getDueReviews(language: language);
    if (result['success'] == true && result['data'] != null) {
      return DueWordsResponse.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Vocabulary stats provider
final vocabularyStatsProvider =
    FutureProvider.family<VocabularyStats?, String?>((ref, language) async {
  try {
    final result = await LearningService.getVocabularyStats(language: language);
    if (result['success'] == true && result['data'] != null) {
      return VocabularyStats.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Vocabulary review session state
class VocabularyReviewState {
  final List<VocabularyItem> cards;
  final int currentIndex;
  final bool isFlipped;
  final int correctCount;
  final int incorrectCount;
  final bool isComplete;
  final int? xpEarned;

  const VocabularyReviewState({
    this.cards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.isComplete = false,
    this.xpEarned,
  });

  VocabularyItem? get currentCard =>
      cards.isNotEmpty && currentIndex < cards.length
          ? cards[currentIndex]
          : null;

  int get totalCards => cards.length;
  int get remaining => cards.length - currentIndex;

  VocabularyReviewState copyWith({
    List<VocabularyItem>? cards,
    int? currentIndex,
    bool? isFlipped,
    int? correctCount,
    int? incorrectCount,
    bool? isComplete,
    int? xpEarned,
  }) {
    return VocabularyReviewState(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      isComplete: isComplete ?? this.isComplete,
      xpEarned: xpEarned ?? this.xpEarned,
    );
  }
}

/// Vocabulary review session notifier
class VocabularyReviewNotifier extends StateNotifier<VocabularyReviewState> {
  VocabularyReviewNotifier() : super(const VocabularyReviewState());

  void startSession(List<VocabularyItem> cards) {
    state = VocabularyReviewState(cards: cards);
  }

  void flipCard() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  Future<void> submitAnswer(bool correct) async {
    if (state.currentCard == null) return;

    // Submit to backend
    final result = await LearningService.submitReview(
      vocabularyId: state.currentCard!.id,
      correct: correct,
    );

    final xpEarned = result['success'] == true
        ? (result['data']?['xpEarned'] ?? 0) as int
        : 0;

    // Update state
    final newCorrect = correct ? state.correctCount + 1 : state.correctCount;
    final newIncorrect =
        correct ? state.incorrectCount : state.incorrectCount + 1;
    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.cards.length;

    state = state.copyWith(
      currentIndex: nextIndex,
      isFlipped: false,
      correctCount: newCorrect,
      incorrectCount: newIncorrect,
      isComplete: isComplete,
      xpEarned: (state.xpEarned ?? 0) + xpEarned,
    );
  }

  void reset() {
    state = const VocabularyReviewState();
  }
}

/// Vocabulary review provider
final vocabularyReviewProvider =
    StateNotifierProvider<VocabularyReviewNotifier, VocabularyReviewState>(
        (ref) {
  return VocabularyReviewNotifier();
});
