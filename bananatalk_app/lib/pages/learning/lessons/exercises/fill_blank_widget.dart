import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Fill in the blank exercise widget
class FillBlankWidget extends StatefulWidget {
  final Exercise exercise;
  final String? currentAnswer;
  final bool showResult;
  final Function(String) onAnswer;
  final VoidCallback onNext;

  const FillBlankWidget({
    super.key,
    required this.exercise,
    this.currentAnswer,
    required this.showResult,
    required this.onAnswer,
    required this.onNext,
  });

  @override
  State<FillBlankWidget> createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentAnswer != null) {
      _controller.text = widget.currentAnswer!;
    }
  }

  @override
  void didUpdateWidget(FillBlankWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear the input when moving to a new exercise
    if (widget.exercise.question != oldWidget.exercise.question) {
      _controller.clear();
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
    _isCorrect = correctAnswer == userAnswer;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Parse the question to find the blank position
    final question = widget.exercise.question;
    final blankRegex = RegExp(r'_{2,}|\[blank\]|\{blank\}');
    final parts = question.split(blankRegex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruction
        Text(
          widget.exercise.instruction,
          style: context.bodySmall,
        ),
        Spacing.gapLG,
        // Question with blank
        Container(
          width: double.infinity,
          padding: Spacing.paddingXL,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.borderLG,
            boxShadow: AppShadows.sm,
          ),
          child: parts.length > 1
              ? Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      parts[0],
                      style: context.titleMedium,
                    ),
                    Container(
                      width: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildInputField(),
                    ),
                    if (parts.length > 1)
                      Text(
                        parts.sublist(1).join(' '),
                        style: context.titleMedium,
                      ),
                  ],
                )
              : Column(
                  children: [
                    Text(
                      question,
                      style: context.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    Spacing.gapLG,
                    _buildInputField(),
                  ],
                ),
        ),
        Spacing.gapXL,
        // Word bank (if options available)
        if (widget.exercise.options.isNotEmpty && !widget.showResult) ...[
          Text(
            'Word Bank',
            style: context.labelLarge,
          ),
          Spacing.gapMD,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.exercise.options.map((option) {
              return InkWell(
                onTap: () {
                  _controller.text = option.text;
                  setState(() {});
                },
                borderRadius: AppRadius.borderRound,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _controller.text == option.text
                        ? AppColors.primary.withOpacity(0.1)
                        : context.surfaceColor,
                    borderRadius: AppRadius.borderRound,
                    border: Border.all(
                      color: _controller.text == option.text
                          ? AppColors.primary
                          : context.dividerColor,
                    ),
                  ),
                  child: Text(
                    option.text,
                    style: TextStyle(
                      color: _controller.text == option.text
                          ? AppColors.primary
                          : context.textPrimary,
                      fontWeight: _controller.text == option.text
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Spacing.gapXL,
        ],
        // Result feedback
        if (widget.showResult) ...[
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
                          color: _isCorrect ? AppColors.success : AppColors.error,
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

  Widget _buildInputField() {
    return Builder(
      builder: (context) {
        Color borderColor = context.dividerColor;
        if (widget.showResult) {
          borderColor = _isCorrect ? AppColors.success : AppColors.error;
        }

        return TextField(
          controller: _controller,
          enabled: !widget.showResult,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: widget.showResult
                ? (_isCorrect ? AppColors.success : AppColors.error)
                : context.textPrimary,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderSM,
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderSM,
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderSM,
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderSM,
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            filled: true,
            fillColor: widget.showResult
                ? (_isCorrect
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1))
                : context.containerColor,
          ),
          onChanged: (_) => setState(() {}),
        );
      },
    );
  }
}
