import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Translation exercise widget
class TranslationWidget extends StatefulWidget {
  final Exercise exercise;
  final String? currentAnswer;
  final bool showResult;
  final Function(String) onAnswer;
  final VoidCallback onNext;

  const TranslationWidget({
    super.key,
    required this.exercise,
    this.currentAnswer,
    required this.showResult,
    required this.onAnswer,
    required this.onNext,
  });

  @override
  State<TranslationWidget> createState() => _TranslationWidgetState();
}

class _TranslationWidgetState extends State<TranslationWidget> {
  final TextEditingController _controller = TextEditingController();
  List<String> _selectedWords = [];
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentAnswer != null) {
      _controller.text = widget.currentAnswer!;
    }
  }

  @override
  void didUpdateWidget(TranslationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear the input when moving to a new exercise
    if (widget.exercise.question != oldWidget.exercise.question) {
      _controller.clear();
      _selectedWords.clear();
      _isCorrect = false;
      // If there's a saved answer for this exercise, restore it
      if (widget.currentAnswer != null && widget.currentAnswer!.isNotEmpty) {
        _controller.text = widget.currentAnswer!;
      }
    }

    if (widget.showResult && !oldWidget.showResult) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final correctAnswer = widget.exercise.correctAnswer?.toLowerCase().trim();
    final userAnswer = _controller.text.toLowerCase().trim();
    // Allow for some flexibility in translation
    _isCorrect = correctAnswer == userAnswer ||
        _normalizeText(correctAnswer ?? '') == _normalizeText(userAnswer);
  }

  String _normalizeText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasWordBank = widget.exercise.options.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruction
        Text(
          widget.exercise.instruction,
          style: context.bodySmall,
        ),
        Spacing.gapLG,
        // Source text to translate
        Container(
          width: double.infinity,
          padding: Spacing.paddingXL,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.borderLG,
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              Icon(
                Icons.translate_rounded,
                color: context.textMuted,
                size: 28,
              ),
              Spacing.gapMD,
              Text(
                widget.exercise.question,
                style: context.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Spacing.gapXL,
        // Translation input area
        if (hasWordBank) ...[
          // Word bank mode - tap to build translation
          Text(
            'Your translation:',
            style: context.labelLarge,
          ),
          Spacing.gapSM,
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
            padding: Spacing.paddingLG,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: AppRadius.borderMD,
              border: Border.all(
                color: widget.showResult
                    ? (_isCorrect ? AppColors.success : AppColors.error)
                    : context.dividerColor,
                width: widget.showResult ? 2 : 1,
              ),
            ),
            child: _selectedWords.isEmpty
                ? Text(
                    'Tap words below to build your translation',
                    style: context.bodySmall.copyWith(fontStyle: FontStyle.italic),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedWords.asMap().entries.map((entry) {
                      return InkWell(
                        onTap: widget.showResult
                            ? null
                            : () {
                                setState(() {
                                  _selectedWords.removeAt(entry.key);
                                  _controller.text = _selectedWords.join(' ');
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: AppRadius.borderSM,
                            border: Border.all(
                              color: AppColors.primary,
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          Spacing.gapLG,
          // Word bank
          if (!widget.showResult) ...[
            Text(
              'Word Bank:',
              style: context.labelLarge,
            ),
            Spacing.gapSM,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.exercise.options.map((option) {
                final isUsed = _selectedWords.contains(option.text);
                return InkWell(
                  onTap: isUsed
                      ? null
                      : () {
                          setState(() {
                            _selectedWords.add(option.text);
                            _controller.text = _selectedWords.join(' ');
                          });
                        },
                  borderRadius: AppRadius.borderSM,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isUsed ? context.containerColor : context.surfaceColor,
                      borderRadius: AppRadius.borderSM,
                      border: Border.all(
                        color: isUsed ? context.dividerColor : context.textMuted,
                      ),
                    ),
                    child: Text(
                      option.text,
                      style: TextStyle(
                        color: isUsed ? context.textMuted : context.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ] else ...[
          // Free text input mode
          Text(
            'Your translation:',
            style: context.labelLarge,
          ),
          Spacing.gapSM,
          TextField(
            controller: _controller,
            enabled: !widget.showResult,
            maxLines: 3,
            style: TextStyle(
              fontSize: 16,
              color: widget.showResult
                  ? (_isCorrect ? AppColors.success : AppColors.error)
                  : context.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Type your translation here...',
              filled: true,
              fillColor: widget.showResult
                  ? (_isCorrect
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1))
                  : context.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMD,
                borderSide: BorderSide(
                  color: widget.showResult
                      ? (_isCorrect ? AppColors.success : AppColors.error)
                      : context.dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMD,
                borderSide: BorderSide(color: context.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMD,
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMD,
                borderSide: BorderSide(
                  color: _isCorrect ? AppColors.success : AppColors.error,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        // Result feedback
        if (widget.showResult) ...[
          Spacing.gapLG,
          Container(
            width: double.infinity,
            padding: Spacing.paddingLG,
            decoration: BoxDecoration(
              color: _isCorrect
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: AppRadius.borderMD,
              border: Border.all(
                color: _isCorrect ? AppColors.success : AppColors.error,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect ? AppColors.success : AppColors.error,
                ),
                Spacing.hGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCorrect ? 'Correct!' : 'Incorrect',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              _isCorrect ? AppColors.success : AppColors.error,
                        ),
                      ),
                      if (!_isCorrect && widget.exercise.correctAnswer != null)
                        Text(
                          'Correct answer: ${widget.exercise.correctAnswer}',
                          style: context.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        // Explanation
        if (widget.showResult && widget.exercise.explanation != null) ...[
          Spacing.gapLG,
          Container(
            width: double.infinity,
            padding: Spacing.paddingLG,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: AppRadius.borderMD,
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
                Spacing.hGapMD,
                Expanded(
                  child: Text(
                    widget.exercise.explanation!,
                    style: context.bodySmall.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Submit/Next button
        Spacing.gapXL,
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.showResult
                ? widget.onNext
                : (_controller.text.isNotEmpty
                    ? () => widget.onAnswer(_controller.text)
                    : null),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderMD,
              ),
            ),
            child: Text(
              widget.showResult ? 'Continue' : 'Check',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
