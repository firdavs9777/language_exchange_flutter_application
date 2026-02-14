import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/widgets/learning/vocabulary_card.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Vocabulary review screen with SRS flashcards
class VocabularyReviewScreen extends ConsumerStatefulWidget {
  const VocabularyReviewScreen({super.key});

  @override
  ConsumerState<VocabularyReviewScreen> createState() =>
      _VocabularyReviewScreenState();
}

class _VocabularyReviewScreenState
    extends ConsumerState<VocabularyReviewScreen> {
  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() async {
    final result = await ref.read(dueReviewsProvider(null).future);
    if (result != null && result.dueWords.isNotEmpty) {
      ref.read(vocabularyReviewProvider.notifier).startSession(result.dueWords);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(vocabularyReviewProvider);
    final dueAsync = ref.watch(dueReviewsProvider(null));

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.textPrimary),
          onPressed: () {
            ref.read(vocabularyReviewProvider.notifier).reset();
            Navigator.pop(context);
          },
        ),
        title: reviewState.cards.isNotEmpty
            ? Text(
                '${reviewState.currentIndex + 1}/${reviewState.totalCards}',
                style: context.titleLarge,
              )
            : Text(
                'Review',
                style: context.titleLarge,
              ),
        actions: [
          if (reviewState.cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${reviewState.correctCount}',
                      style: TextStyle(color: Colors.green[400]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.cancel, size: 16, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${reviewState.incorrectCount}',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: dueAsync.when(
        data: (dueResponse) {
          if (dueResponse == null || dueResponse.dueWords.isEmpty) {
            return _buildAllDone();
          }

          if (reviewState.isComplete) {
            return _buildResults(reviewState);
          }

          if (reviewState.currentCard == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return _buildReviewCard(reviewState);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.textMuted),
              Spacing.gapLG,
              Text('Failed to load reviews', style: context.bodyMedium.copyWith(color: context.textSecondary)),
              Spacing.gapLG,
              ElevatedButton(
                onPressed: () => ref.invalidate(dueReviewsProvider(null)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllDone() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            Spacing.gapXL,
            Text(
              'All caught up!',
              style: context.displaySmall,
            ),
            Spacing.gapSM,
            Text(
              'No words due for review right now',
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
            Spacing.gapXXL,
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(VocabularyReviewState state) {
    final card = state.currentCard!;

    return Builder(
      builder: (context) => Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: state.currentIndex / state.totalCards,
            backgroundColor: context.containerColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
          Expanded(
            child: Padding(
              padding: Spacing.paddingXL,
              child: VocabularyFlashcard(
                item: card,
                isFlipped: state.isFlipped,
                onFlip: () {
                  ref.read(vocabularyReviewProvider.notifier).flipCard();
                },
              ),
            ),
          ),
          // Answer buttons
          if (state.isFlipped)
            Padding(
              padding: Spacing.paddingXL,
              child: Row(
                children: [
                  Expanded(
                    child: _buildAnswerButton(
                      label: "Didn't know",
                      color: AppColors.error,
                      icon: Icons.close_rounded,
                      onPressed: () {
                        ref
                            .read(vocabularyReviewProvider.notifier)
                            .submitAnswer(false);
                      },
                    ),
                  ),
                  Spacing.hGapLG,
                  Expanded(
                    child: _buildAnswerButton(
                      label: 'Got it!',
                      color: AppColors.primary,
                      icon: Icons.check_rounded,
                      onPressed: () {
                        ref
                            .read(vocabularyReviewProvider.notifier)
                            .submitAnswer(true);
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: Spacing.paddingXL,
              child: Text(
                'Tap card to reveal answer',
                style: context.bodySmall,
              ),
            ),
          Spacing.gapLG,
        ],
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLG,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          Spacing.hGapSM,
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(VocabularyReviewState state) {
    final total = state.totalCards;
    final correct = state.correctCount;
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;

    return Builder(
      builder: (context) => Center(
        child: Padding(
          padding: Spacing.paddingXL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$accuracy%',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Spacing.gapXL,
              Text(
                'Session Complete!',
                style: context.displaySmall,
              ),
              Spacing.gapLG,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildResultStat(
                    'Correct',
                    '$correct',
                    AppColors.success,
                  ),
                  Spacing.hGapLG,
                  _buildResultStat(
                    'Incorrect',
                    '${state.incorrectCount}',
                    AppColors.error,
                  ),
                  Spacing.hGapLG,
                  _buildResultStat(
                    'XP Earned',
                    '+${state.xpEarned ?? 0}',
                    AppColors.primary,
                  ),
                ],
              ),
              Spacing.gapXXL,
              ElevatedButton(
                onPressed: () {
                  ref.read(vocabularyReviewProvider.notifier).reset();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderLG,
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Builder(
      builder: (context) => Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: context.bodySmall.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}
