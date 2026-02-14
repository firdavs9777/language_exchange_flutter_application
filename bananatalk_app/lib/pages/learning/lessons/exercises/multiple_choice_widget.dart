import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Multiple choice exercise widget
class MultipleChoiceWidget extends StatelessWidget {
  final Exercise exercise;
  final String? selectedAnswer;
  final bool showResult;
  final Function(String) onAnswer;
  final VoidCallback onNext;

  const MultipleChoiceWidget({
    super.key,
    required this.exercise,
    this.selectedAnswer,
    required this.showResult,
    required this.onAnswer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruction
        Text(
          exercise.instruction,
          style: context.bodySmall,
        ),
        Spacing.gapLG,
        // Question
        Container(
          width: double.infinity,
          padding: Spacing.paddingXL,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.borderLG,
            boxShadow: AppShadows.sm,
          ),
          child: Text(
            exercise.question,
            style: context.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Spacing.gapXL,
        // Options
        ...exercise.options.map((option) {
          final isSelected = selectedAnswer == option.id;
          final isCorrect = option.isCorrect;

          Color? backgroundColor;
          Color? borderColor;
          Color? textColor;

          if (showResult) {
            if (isCorrect) {
              backgroundColor = Colors.green.withOpacity(0.1);
              borderColor = Colors.green;
              textColor = Colors.green[700];
            } else if (isSelected && !isCorrect) {
              backgroundColor = Colors.red.withOpacity(0.1);
              borderColor = Colors.red;
              textColor = Colors.red[700];
            }
          } else if (isSelected) {
            backgroundColor = AppColors.primary.withOpacity(0.1);
            borderColor = AppColors.primary;
            textColor = AppColors.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: showResult ? null : () => onAnswer(option.id),
              borderRadius: AppRadius.borderMD,
              child: Container(
                width: double.infinity,
                padding: Spacing.paddingLG,
                decoration: BoxDecoration(
                  color: backgroundColor ?? context.surfaceColor,
                  borderRadius: AppRadius.borderMD,
                  border: Border.all(
                    color: borderColor ?? context.dividerColor,
                    width: isSelected || (showResult && isCorrect) ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected || (showResult && isCorrect)
                            ? (borderColor ?? context.dividerColor)
                            : context.containerColor,
                      ),
                      child: Center(
                        child: showResult
                            ? Icon(
                                isCorrect
                                    ? Icons.check
                                    : (isSelected
                                        ? Icons.close
                                        : Icons.circle_outlined),
                                size: 16,
                                color: isCorrect || isSelected
                                    ? Colors.white
                                    : context.textMuted,
                              )
                            : Text(
                                String.fromCharCode(65 +
                                    exercise.options.indexOf(option)),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : context.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    Spacing.hGapMD,
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor ?? context.textPrimary,
                          fontWeight: isSelected || (showResult && isCorrect)
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        // Explanation (shown after answer)
        if (showResult && exercise.explanation != null) ...[
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
                    exercise.explanation!,
                    style: context.bodySmall.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Next button
        if (showResult) ...[
          Spacing.gapXL,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
