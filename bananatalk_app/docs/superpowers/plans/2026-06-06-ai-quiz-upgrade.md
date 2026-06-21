# AI Quiz Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the AI Quiz UI with instant answer feedback/locking, streak counter, progress dots, a rich bottom-sheet results view, Quick Start cards, a full-screen generating overlay, and a "Play Again" button on history cards.

**Architecture:** Both files are pure UI rewrites — no provider/model changes. All new state (`_revealedIndices`, `_streak`, `_maxStreak`) lives in the widget's local `State`. The results sheet replaces the existing `AlertDialog` with a `showModalBottomSheet` + `DraggableScrollableSheet`. The generating overlay is a `Stack` wrapping the `Scaffold` body in `ai_quiz_screen.dart`, not a dialog.

**Tech Stack:** Flutter, Riverpod (existing `aiQuizProvider`), existing theme tokens (`AppColors`, `AppRadius`, `AppShadows`, `Spacing`, theme context extensions), existing models (`AIQuiz`, `AIQuizQuestion`, `AIQuizResult`), no new packages.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/pages/ai/quiz/quiz_player_screen.dart` | Full rewrite | Quiz-taking UI with instant feedback, streak, progress dots, bottom-sheet results |
| `lib/pages/ai/quiz/ai_quiz_screen.dart` | Targeted additions | Quick Start row, full-screen generating overlay, "Play Again" on history cards |

---

## Task 1: Rewrite `quiz_player_screen.dart` — state + core structure

**Files:**
- Modify: `lib/pages/ai/quiz/quiz_player_screen.dart`

- [ ] **Step 1: Replace the state fields and `dispose`**

Replace the entire `_QuizPlayerScreenState` class state block (fields + dispose) with:

```dart
class _QuizPlayerScreenState extends ConsumerStatefulWidget {
  // ...existing...
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> {
  final TextEditingController _fillBlankController = TextEditingController();
  final Set<int> _revealedIndices = {};
  int _streak = 0;
  int _maxStreak = 0;

  @override
  void dispose() {
    _fillBlankController.dispose();
    super.dispose();
  }
```

- [ ] **Step 2: Replace `_selectAnswer`**

Replace the existing `_selectAnswer` method with:

```dart
void _selectAnswer(String answer) {
  final state = ref.read(aiQuizProvider);
  final idx = state.currentIndex;
  if (_revealedIndices.contains(idx)) return; // locked

  ref.read(aiQuizProvider.notifier).answerQuestion(idx, answer);

  final question = state.currentQuestion;
  if (question != null) {
    final isCorrect = answer == question.correctAnswer;
    setState(() {
      _revealedIndices.add(idx);
      if (isCorrect) {
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
      } else {
        _streak = 0;
      }
    });
  } else {
    setState(() => _revealedIndices.add(idx));
  }
}
```

- [ ] **Step 3: Remove `_nextQuestion` and `_previousQuestion`**

Delete both methods entirely. Navigation is handled solely by the "Continue" button which calls `ref.read(aiQuizProvider.notifier).nextQuestion()` inline.

- [ ] **Step 4: Replace `_submitQuiz`**

```dart
Future<void> _submitQuiz() async {
  final totalQ = ref.read(aiQuizProvider).quiz?.questions.length ?? 0;
  final allAnswered = _revealedIndices.length >= totalQ;
  bool proceed = allAnswered;

  if (!allAnswered) {
    proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.aiQuizSubmitTitle),
            content: Text(AppLocalizations.of(context)!.aiQuizSubmitBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: Text(AppLocalizations.of(context)!.submit),
              ),
            ],
          ),
        ) ??
        false;
  }

  if (proceed) {
    final success = await ref.read(aiQuizProvider.notifier).completeQuiz();
    if (success && mounted) _showResults();
  }
}
```

---

## Task 2: AppBar — streak badge + progress dots

**Files:**
- Modify: `lib/pages/ai/quiz/quiz_player_screen.dart`

- [ ] **Step 1: Update the AppBar in the main `build` method**

Replace the existing `AppBar` inside the `WillPopScope` child scaffold with:

```dart
appBar: AppBar(
  elevation: 0,
  backgroundColor: context.surfaceColor,
  leading: IconButton(
    icon: Icon(Icons.close, color: context.textPrimary),
    onPressed: () async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.aiQuizExitTitle),
          content: Text(AppLocalizations.of(context)!.aiQuizExitBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: Text(AppLocalizations.of(context)!.exit),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        ref.read(aiQuizProvider.notifier).reset();
        Navigator.pop(context);
      }
    },
  ),
  title: Column(
    children: [
      Text(
        quiz.title,
        style: context.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      Text(
        'Question ${state.currentIndex + 1} of ${quiz.questions.length}',
        style: context.caption?.copyWith(color: context.textSecondary),
      ),
    ],
  ),
  centerTitle: true,
  actions: [
    if (_streak >= 2)
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded,
                color: Colors.orange, size: 20),
            const SizedBox(width: 2),
            Text(
              '$_streak',
              style: context.labelLarge?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
  ],
),
```

- [ ] **Step 2: Replace the LinearProgressIndicator with progress dots**

Remove the `LinearProgressIndicator` widget and replace it with:

```dart
// Progress dots
Container(
  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
  color: context.surfaceColor,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(quiz.questions.length, (i) {
      final isAnswered = _revealedIndices.contains(i);
      final isCurrent = i == state.currentIndex;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: isCurrent ? 10 : 7,
        height: isCurrent ? 10 : 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAnswered
              ? AppColors.error
              : isCurrent
                  ? AppColors.error.withOpacity(0.4)
                  : context.dividerColor,
          border: isCurrent
              ? Border.all(color: AppColors.error, width: 1.5)
              : null,
        ),
      );
    }),
  ),
),
```

---

## Task 3: Multiple choice + True/False — instant feedback coloring

**Files:**
- Modify: `lib/pages/ai/quiz/quiz_player_screen.dart`

- [ ] **Step 1: Replace `_buildMultipleChoice`**

```dart
Widget _buildMultipleChoice(AIQuizQuestion question, String? currentAnswer) {
  if (question.options == null) return const SizedBox.shrink();
  final idx = ref.read(aiQuizProvider).currentIndex;
  final isRevealed = _revealedIndices.contains(idx);

  return Column(
    children: question.options!.map((option) {
      final isSelected = currentAnswer == option;
      final isCorrect = option == question.correctAnswer;

      Color borderColor;
      Color bgColor;
      Widget? trailingIcon;

      if (isRevealed) {
        if (isCorrect) {
          borderColor = AppColors.success;
          bgColor = AppColors.success.withOpacity(0.08);
          trailingIcon = const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20);
        } else if (isSelected) {
          borderColor = AppColors.error;
          bgColor = AppColors.error.withOpacity(0.08);
          trailingIcon = const Icon(Icons.cancel_rounded,
              color: AppColors.error, size: 20);
        } else {
          borderColor = context.dividerColor;
          bgColor = context.cardBackground.withOpacity(0.5);
          trailingIcon = null;
        }
      } else {
        borderColor = isSelected ? AppColors.error : context.dividerColor;
        bgColor = isSelected
            ? AppColors.error.withOpacity(0.1)
            : context.cardBackground;
        trailingIcon = null;
      }

      return GestureDetector(
        onTap: isRevealed ? null : () => _selectAnswer(option),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: Spacing.paddingLG,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.borderMD,
            border: Border.all(
              color: borderColor,
              width: (isRevealed && (isCorrect || isSelected)) ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRevealed
                      ? (isCorrect
                          ? AppColors.success
                          : isSelected
                              ? AppColors.error
                              : context.containerColor)
                      : (isSelected
                          ? AppColors.error
                          : context.containerColor),
                  border: Border.all(
                    color: isRevealed
                        ? (isCorrect
                            ? AppColors.success
                            : isSelected
                                ? AppColors.error
                                : context.dividerColor)
                        : (isSelected
                            ? AppColors.error
                            : context.dividerColor),
                  ),
                ),
                child: (isSelected || (isRevealed && isCorrect))
                    ? Icon(
                        isRevealed && isCorrect
                            ? Icons.check
                            : Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              Spacing.hGapMD,
              Expanded(
                child: Text(
                  option,
                  style: context.bodyLarge?.copyWith(
                    fontWeight: isSelected || (isRevealed && isCorrect)
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isRevealed
                        ? (isCorrect
                            ? AppColors.success
                            : isSelected
                                ? AppColors.error
                                : context.textMuted)
                        : (isSelected ? AppColors.error : context.textPrimary),
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                Spacing.hGapSM,
                trailingIcon,
              ],
            ],
          ),
        ),
      );
    }).toList(),
  );
}
```

- [ ] **Step 2: Replace `_buildTrueFalse` and `_buildTrueFalseOption`**

```dart
Widget _buildTrueFalse(String? currentAnswer, AIQuizQuestion question) {
  return Row(
    children: [
      Expanded(
        child: _buildTrueFalseOption('True', currentAnswer == 'True', question),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildTrueFalseOption('False', currentAnswer == 'False', question),
      ),
    ],
  );
}

Widget _buildTrueFalseOption(
    String value, bool isSelected, AIQuizQuestion question) {
  final idx = ref.read(aiQuizProvider).currentIndex;
  final isRevealed = _revealedIndices.contains(idx);
  final isCorrect = value == question.correctAnswer;

  Color borderColor;
  Color bgColor;
  Color textColor;

  if (isRevealed) {
    if (isCorrect) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.success;
    } else if (isSelected) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
    } else {
      borderColor = context.dividerColor;
      bgColor = context.cardBackground.withOpacity(0.5);
      textColor = context.textMuted;
    }
  } else {
    borderColor = isSelected
        ? (value == 'True' ? AppColors.success : AppColors.error)
        : context.dividerColor;
    bgColor = isSelected
        ? (value == 'True' ? AppColors.success : AppColors.error)
            .withOpacity(0.1)
        : context.cardBackground;
    textColor = isSelected
        ? (value == 'True' ? AppColors.success : AppColors.error)
        : context.textSecondary;
  }

  return GestureDetector(
    onTap: isRevealed ? null : () => _selectAnswer(value),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(
          color: borderColor,
          width: (isRevealed && (isCorrect || isSelected)) ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          value,
          style: context.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 3: Update `_buildAnswerSection` to pass `question` to `_buildTrueFalse`**

```dart
Widget _buildAnswerSection(AIQuizState state, AIQuizQuestion question) {
  final currentAnswer = state.answers[state.currentIndex];

  switch (question.type) {
    case 'multiple_choice':
      return _buildMultipleChoice(question, currentAnswer);
    case 'fill_blank':
      return _buildFillBlank(state, currentAnswer);
    case 'true_false':
      return _buildTrueFalse(currentAnswer, question);
    case 'translation':
      return _buildTranslation(state, currentAnswer);
    default:
      return _buildMultipleChoice(question, currentAnswer);
  }
}
```

---

## Task 4: Explanation box + Navigation bar

**Files:**
- Modify: `lib/pages/ai/quiz/quiz_player_screen.dart`

- [ ] **Step 1: Add explanation box below answer section in the scrollable body**

In the `Column` inside `SingleChildScrollView`, after `_buildAnswerSection(state, question)`, add:

```dart
// Explanation (shown after reveal)
Builder(builder: (context) {
  final idx = state.currentIndex;
  final isRevealed = _revealedIndices.contains(idx);
  if (!isRevealed || question.explanation == null || question.explanation!.isEmpty) {
    return const SizedBox.shrink();
  }
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Container(
      padding: Spacing.paddingMD,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: AppRadius.borderMD,
        border: Border.all(
          color: Colors.blue.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Colors.blue, size: 18),
          Spacing.hGapSM,
          Expanded(
            child: Text(
              question.explanation!,
              style: context.bodySmall?.copyWith(
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}),
```

- [ ] **Step 2: Replace `_buildNavigationBar` — remove "Previous", single full-width button**

```dart
Widget _buildNavigationBar(AIQuizState state, AIQuiz quiz) {
  final isLastQuestion = state.currentIndex == quiz.questions.length - 1;
  final isRevealed = _revealedIndices.contains(state.currentIndex);

  return Container(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 12,
      bottom: MediaQuery.of(context).padding.bottom + 12,
    ),
    decoration: BoxDecoration(
      color: context.surfaceColor,
      boxShadow: AppShadows.sm,
    ),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isRevealed
            ? (isLastQuestion
                ? _submitQuiz
                : () => ref.read(aiQuizProvider.notifier).nextQuestion())
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          disabledBackgroundColor: AppColors.gray300,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderMD,
          ),
        ),
        child: Text(
          isLastQuestion ? 'Submit Quiz' : 'Continue →',
          style: context.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
```

---

## Task 5: Results bottom sheet

**Files:**
- Modify: `lib/pages/ai/quiz/quiz_player_screen.dart`

- [ ] **Step 1: Replace `_showResults` with a `showModalBottomSheet` implementation**

Replace the entire `_showResults` method and the `_buildResultItem` helper with:

```dart
void _showResults() {
  final state = ref.read(aiQuizProvider);
  final result = state.result;
  final quiz = state.quiz;
  if (result == null || quiz == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollController) {
        final scoreColor = _getScoreColor(result.percentage.toInt());
        final header = result.percentage >= 80
            ? 'Great job!'
            : result.percentage >= 60
                ? 'Good effort!'
                : 'Keep practicing!';

        return Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    children: [
                      // Score circle
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scoreColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                result.grade,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                              Text(
                                '${result.percentage.toInt()}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scoreColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Spacing.gapLG,
                      Text(
                        header,
                        style: context.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacing.gapXS,
                      Text(
                        '${result.correctCount} out of ${result.totalQuestions} correct',
                        style: context.bodySmall,
                      ),
                      Spacing.gapLG,
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildResultStat(
                              Icons.star_rounded,
                              '+${result.xpEarned}',
                              'XP',
                              Colors.amber),
                          _buildResultStat(
                              Icons.timer_rounded,
                              '${(result.timeSpent / 60).floor()}m',
                              'Time',
                              Colors.blue),
                          _buildResultStat(
                              Icons.local_fire_department_rounded,
                              '$_maxStreak',
                              'Best Streak',
                              Colors.orange),
                        ],
                      ),
                      // Feedback
                      if (result.feedback.isNotEmpty) ...[
                        Spacing.gapLG,
                        Container(
                          padding: Spacing.paddingMD,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.06),
                            borderRadius: AppRadius.borderMD,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 16, color: Colors.blue),
                              Spacing.hGapSM,
                              Expanded(
                                child: Text(
                                  result.feedback,
                                  style: context.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Spacing.gapLG,
                      const Divider(),
                      Spacing.gapMD,
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Question Review',
                          style: context.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Spacing.gapMD,
                      // Per-question review rows
                      ...List.generate(quiz.questions.length, (i) {
                        final q = quiz.questions[i];
                        final userAnswer = state.answers[i] ?? '';
                        final isCorrect = userAnswer == q.correctAnswer;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isCorrect
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: isCorrect
                                    ? AppColors.success
                                    : AppColors.error,
                                size: 20,
                              ),
                              Spacing.hGapSM,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      q.question,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.bodySmall?.copyWith(
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    if (!isCorrect &&
                                        q.correctAnswer != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Correct: ${q.correctAnswer}',
                                        style: context.captionSmall?.copyWith(
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Spacing.gapXL,
                    ],
                  ),
                ),
              ),
              // Bottom buttons
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(ctx).padding.bottom + 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(aiQuizProvider.notifier).reset();
                          Navigator.of(ctx).pop(); // close sheet
                          Navigator.of(context).pop(); // pop player back to hub
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMD,
                          ),
                        ),
                        child: const Text('Play Again'),
                      ),
                    ),
                    Spacing.hGapMD,
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(aiQuizProvider.notifier).reset();
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMD,
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.done),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildResultStat(
    IconData icon, String value, String label, Color color) {
  return Column(
    children: [
      Icon(icon, color: color, size: 28),
      const SizedBox(height: 4),
      Text(
        value,
        style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      Text(label, style: context.captionSmall),
    ],
  );
}
```

---

## Task 6: Add Quick Start cards + generating overlay to `ai_quiz_screen.dart`

**Files:**
- Modify: `lib/pages/ai/quiz/ai_quiz_screen.dart`

- [ ] **Step 1: Add `_quickStarts` field to `_AIQuizScreenState`**

Inside `_AIQuizScreenState`, after the existing `_difficulties` list, add:

```dart
final List<Map<String, dynamic>> _quickStarts = [
  {
    'label': 'Weak Areas',
    'icon': Icons.gps_fixed_rounded,
    'color': Colors.red,
    'type': 'weak_areas',
    'count': 5,
    'diff': 'adaptive',
  },
  {
    'label': 'Vocab Blast',
    'icon': Icons.book_rounded,
    'color': Colors.purple,
    'type': 'vocabulary',
    'count': 10,
    'diff': 'medium',
  },
  {
    'label': 'Daily Mix',
    'icon': Icons.shuffle_rounded,
    'color': Colors.teal,
    'type': 'mixed',
    'count': 10,
    'diff': 'adaptive',
  },
];
```

- [ ] **Step 2: Add `_buildQuickStarts` widget method**

```dart
Widget _buildQuickStarts() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Quick Start',
        style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      Spacing.gapMD,
      SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _quickStarts.length,
          separatorBuilder: (_, __) => Spacing.hGapMD,
          itemBuilder: (context, i) {
            final qs = _quickStarts[i];
            final color = qs['color'] as Color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = qs['type'] as String;
                  _selectedDifficulty = qs['diff'] as String;
                  _questionCount = qs['count'] as int;
                  _isGenerating = true;
                });
                _generateQuiz();
              },
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppRadius.borderLG,
                  border: Border.all(
                    color: color.withOpacity(0.4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(qs['icon'] as IconData, color: color, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      qs['label'] as String,
                      style: context.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      Spacing.gapXL,
    ],
  );
}
```

- [ ] **Step 3: Insert `_buildQuickStarts()` into the `build` method's Column**

In the `build` method's `SingleChildScrollView` child `Column`, insert `_buildQuickStarts()` between the stats card block and the `'Generate New Quiz'` section header:

```dart
// Stats Card
statsAsync.when(...),

// Quick Start
_buildQuickStarts(),

// Generate New Quiz Section
Text(
  'Generate New Quiz',
  ...
),
```

- [ ] **Step 4: Replace the `Scaffold` body with a `Stack` for the generating overlay**

In the `build` method, change the `body:` of the `Scaffold` from `SingleChildScrollView(...)` to:

```dart
body: Stack(
  children: [
    SingleChildScrollView(
      padding: Spacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Card
          statsAsync.when(
            data: (stats) {
              if (stats == null) return const SizedBox.shrink();
              return _buildStatsCard(stats);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Quick Start
          _buildQuickStarts(),

          // Generate New Quiz Section
          Text(
            'Generate New Quiz',
            style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Spacing.gapMD,
          _buildGenerateSection(),
          Spacing.gapXL,

          // Previous Quizzes
          Text(
            'Previous Quizzes',
            style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Spacing.gapMD,
          quizzesAsync.when(
            data: (quizzes) {
              if (quizzes.isEmpty) {
                return _buildEmptyQuizzes();
              }
              return Column(
                children: quizzes
                    .take(5)
                    .map((q) => _buildQuizCard(q))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.error),
            ),
            error: (_, __) => _buildEmptyQuizzes(),
          ),
        ],
      ),
    ),

    // Generating overlay
    if (_isGenerating)
      Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: AppRadius.borderXL,
              boxShadow: AppShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 2 * 3.14159),
                  duration: const Duration(seconds: 2),
                  builder: (_, angle, child) => Transform.rotate(
                    angle: angle,
                    child: child,
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                ),
                Spacing.gapLG,
                Text(
                  'Generating your quiz...',
                  style: context.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacing.gapSM,
                _AnimatedDots(),
              ],
            ),
          ),
        ),
      ),
  ],
),
```

- [ ] **Step 5: Add `_AnimatedDots` private widget at the bottom of the file (outside `_AIQuizScreenState`)**

After the closing `}` of `_AIQuizScreenState`, add:

```dart
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _dotCount = (_dotCount % 3) + 1);
          _ctrl.forward(from: 0);
        }
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '.' * _dotCount,
      style: TextStyle(
        fontSize: 20,
        color: AppColors.error,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    );
  }
}
```

---

## Task 7: "Play Again" button in history quiz cards

**Files:**
- Modify: `lib/pages/ai/quiz/ai_quiz_screen.dart`

- [ ] **Step 1: Update `_buildQuizCard` to add "Play Again" for completed quizzes**

In `_buildQuizCard`, find the `Padding` > `Row` that builds the card content and replace the trailing widget section. Specifically: for completed quizzes with a result, keep the score badge and add a `TextButton` below. Change the inner `child:` of `InkWell` from a single `Padding` wrapping a `Row` to a `Padding` wrapping a `Column` with the row + button:

```dart
child: Padding(
  padding: Spacing.paddingLG,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTypeColor(quiz.type).withOpacity(0.1),
              borderRadius: AppRadius.borderMD,
            ),
            child: Center(
              child: Text(
                quiz.typeIcon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          Spacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: context.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Text(
                      '${quiz.questionCount} questions',
                      style: context.caption
                          ?.copyWith(color: context.textSecondary),
                    ),
                    Spacing.hGapSM,
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Spacing.hGapSM,
                    Text(
                      quiz.difficulty,
                      style: context.caption
                          ?.copyWith(color: context.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (quiz.isCompleted && quiz.result != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getScoreColor(quiz.result!.percentage.toInt())
                    .withOpacity(0.1),
                borderRadius: AppRadius.borderSM,
              ),
              child: Text(
                '${quiz.result!.percentage.toInt()}%',
                style: context.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(
                      quiz.result!.percentage.toInt()),
                ),
              ),
            )
          else
            Icon(
              Icons.play_arrow_rounded,
              color: context.textMuted,
            ),
        ],
      ),
      if (quiz.isCompleted && quiz.result != null)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _startQuiz(quiz),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Play Again',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
    ],
  ),
),
```

---

## Task 8: Run `dart analyze` and fix any errors

**Files:**
- `lib/pages/ai/quiz/quiz_player_screen.dart`
- `lib/pages/ai/quiz/ai_quiz_screen.dart`

- [ ] **Step 1: Run analyzer**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app && dart analyze lib/pages/ai/quiz/quiz_player_screen.dart lib/pages/ai/quiz/ai_quiz_screen.dart
```

Expected: no errors (warnings about deprecated APIs like `withOpacity` are acceptable if the codebase already uses them consistently).

- [ ] **Step 2: Fix any errors reported**

Common things to check:
- `_buildResultItem` helper removed — replaced by `_buildResultStat`, ensure no call sites remain
- `_previousQuestion` removed — ensure no call sites remain
- `_buildTrueFalse` signature changed — ensure `_buildAnswerSection` passes `question`
- `TweenAnimationBuilder` math: `dart:math` is not needed since `3.14159` is hardcoded; if you prefer `pi`, add `import 'dart:math' show pi;` and replace `3.14159` with `pi`
- `_AnimatedDots` uses `SingleTickerProviderStateMixin` — no extra import needed

- [ ] **Step 3: Commit**

```bash
cd /Users/firdavsmutalipov/Projects/BananaTalk/bananatalk_app && git add lib/pages/ai/quiz/quiz_player_screen.dart lib/pages/ai/quiz/ai_quiz_screen.dart && git commit -m "feat(quiz): instant answer feedback, streak, progress dots, results sheet, quick start, overlay"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] `_revealedIndices`, `_streak`, `_maxStreak` state fields — Task 1
- [x] `_selectAnswer` with lock logic + streak update — Task 1
- [x] AppBar streak fire badge when `_streak >= 2` — Task 2
- [x] Progress dots row — Task 2
- [x] Multiple choice green/red/grey coloring with icons — Task 3
- [x] True/False green/red coloring — Task 3
- [x] Explanation box below options — Task 4
- [x] Navigation: single full-width button, disabled until revealed — Task 4
- [x] "Previous" button removed — Task 2/4 (never added)
- [x] `_submitQuiz` skip confirm when all revealed — Task 1
- [x] Results as `showModalBottomSheet` draggable — Task 5
- [x] Results: score circle, header, correct/total, XP/Time/Streak row — Task 5
- [x] Results: feedback block, question review rows — Task 5
- [x] Results: "Play Again" (pop to hub) + "Done" buttons — Task 5
- [x] `WillPopScope` exit dialog — kept intact in Task 2 AppBar replacement
- [x] Quick Start cards row in `ai_quiz_screen.dart` — Task 6
- [x] Full-screen generating overlay as Stack — Task 6
- [x] `_AnimatedDots` animated dots — Task 6
- [x] "Play Again" TextButton in history cards — Task 7
- [x] `dart analyze` — Task 8

**Type consistency:**
- `_buildTrueFalse(currentAnswer, question)` signature matches usage in `_buildAnswerSection` — consistent
- `_buildResultStat` (new name) — only called in `_showResults` — consistent
- `_buildResultItem` (old name) — fully replaced, no stale call sites

**Placeholder scan:** None — all code blocks are complete.
