import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// A story's multiple-choice quiz sticker.
///
/// Controlled: the viewer holds the answered quiz (keyed by story id) and
/// passes it back in. Results are revealed for the owner, or once the server
/// sent `correctIndex` -- never from `hasAnswered`, which the owner never has.
class StoryQuizStickerWidget extends StatefulWidget {
  final StoryQuizSticker quiz;
  final bool isOwner;

  /// Expired / archived / highlighted story: the server refuses answers.
  final bool readOnly;

  /// Sends the answer; `true` when the viewer should now see the result
  /// (the viewer has replaced [quiz] with the answered one), `false` to roll
  /// the optimistic selection back.
  final Future<bool> Function(int optionIndex)? onAnswer;

  /// `true` when an answer is sent (playback pauses), `false` once it settles.
  final ValueChanged<bool>? onInteracting;

  const StoryQuizStickerWidget({
    super.key,
    required this.quiz,
    this.isOwner = false,
    this.readOnly = false,
    this.onAnswer,
    this.onInteracting,
  });

  @override
  State<StoryQuizStickerWidget> createState() => _StoryQuizStickerWidgetState();
}

class _StoryQuizStickerWidgetState extends State<StoryQuizStickerWidget> {
  int? _pending;

  bool get _revealed => widget.isOwner || widget.quiz.correctIndex != null;

  Future<void> _answer(int index) async {
    if (widget.readOnly ||
        widget.isOwner ||
        _revealed ||
        widget.quiz.hasAnswered ||
        _pending != null ||
        widget.onAnswer == null) {
      return;
    }
    setState(() => _pending = index);
    widget.onInteracting?.call(true);
    try {
      await widget.onAnswer!(index);
    } finally {
      if (mounted) {
        setState(() => _pending = null);
        widget.onInteracting?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final q = widget.quiz;
    final revealed = _revealed;
    final answer = q.userAnswerIndex;
    final correct = q.correctIndex;

    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: constraints.maxHeight),
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  q.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                for (final o in q.options) ...[
                  _option(
                    o,
                    revealed: revealed,
                    correct: correct,
                    answer: answer,
                  ),
                  const SizedBox(height: 8),
                ],
                if (!widget.isOwner &&
                    revealed &&
                    answer != null &&
                    correct != null)
                  Text(
                    answer == correct
                        ? l10n.storyQuizCorrect
                        : l10n.storyQuizWrong,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: answer == correct
                          ? Colors.lightGreenAccent
                          : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _option(
    StoryQuizOption o, {
    required bool revealed,
    required int? correct,
    required int? answer,
  }) {
    final isCorrect = revealed && o.index == correct;
    final isWrongPick = revealed && o.index == answer && o.index != correct;
    final isPending = _pending == o.index;
    final fraction = revealed
        ? ((o.percentage ?? 0) / 100).clamp(0.0, 1.0)
        : 0.0;

    Widget? trailing;
    if (isCorrect) {
      trailing = KeyedSubtree(
        key: Key('quiz-correct-${o.index}'),
        child: const Icon(
          Icons.check_circle,
          color: Colors.lightGreenAccent,
          size: 20,
        ),
      );
    } else if (isWrongPick) {
      trailing = const Icon(Icons.cancel, color: Colors.orangeAccent, size: 20);
    } else if (!revealed && o.index == widget.quiz.userAnswerIndex) {
      // Answered, but the server sent no results: just mark the pick.
      trailing = const Icon(Icons.check, color: Colors.white, size: 20);
    } else if (isPending) {
      trailing = KeyedSubtree(
        key: Key('quiz-pending-${o.index}'),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    final tappable = !revealed &&
        !widget.readOnly &&
        !widget.isOwner &&
        !widget.quiz.hasAnswered;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: tappable ? () => _answer(o.index) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCorrect
                  ? Colors.lightGreenAccent
                  : (isPending ? Colors.white : Colors.white38),
            ),
          ),
          child: Stack(
            children: [
              if (revealed)
                Positioned.fill(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: fraction,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color:
                              (isCorrect
                                      ? Colors.lightGreenAccent
                                      : Colors.white)
                                  .withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        o.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                    if (revealed && o.percentage != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${o.percentage}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
