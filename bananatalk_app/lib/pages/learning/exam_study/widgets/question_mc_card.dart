import 'package:bananatalk_app/providers/provider_models/exam/exam_question.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Multiple-choice question renderer. Stateless — the parent owns the
/// selected option, locked state (after submit), and correctness flag so
/// it can drive both the user's selection and the post-submit reveal of
/// the correct answer.
class QuestionMcCard extends StatelessWidget {
  const QuestionMcCard({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.onSelect,
    this.locked = false,
    this.correctOption,
  });

  final ExamQuestion question;

  /// Currently selected option label ("A", "B", …) or null if untouched.
  final String? selectedOption;

  /// Fired when the user picks an option. Ignored when [locked] is true.
  final ValueChanged<String> onSelect;

  /// True once the user has submitted — disables further changes and
  /// flips the colour scheme so the correct/incorrect option is obvious.
  final bool locked;

  /// Server-confirmed correct option (revealed only when [locked]).
  final String? correctOption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        for (final option in question.options) ...[
          _OptionTile(
            option: option,
            isSelected: _optionLabel(option) == selectedOption,
            isCorrect:
                locked && correctOption != null &&
                    _optionLabel(option) == correctOption,
            isWrongPick: locked &&
                _optionLabel(option) == selectedOption &&
                correctOption != null &&
                selectedOption != correctOption,
            locked: locked,
            onTap: locked ? null : () => onSelect(_optionLabel(option)),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// Options arrive as `"A) Plentiful"` — the leading letter is the
  /// canonical label sent back to the server. Falls back to the whole
  /// string when no leading-letter prefix is present.
  String _optionLabel(String option) {
    final m = RegExp(r'^\s*([A-Z])[\)\.]').firstMatch(option);
    return m?.group(1) ?? option;
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrongPick,
    required this.locked,
    this.onTap,
  });

  final String option;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrongPick;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color border = context.dividerColor;
    Color background = context.surfaceColor;
    Color textColor = context.textPrimary;
    IconData? trailingIcon;
    Color? iconColor;

    if (isCorrect) {
      border = const Color(0xFF22C55E);
      background = const Color(0xFF22C55E).withValues(alpha: 0.08);
      trailingIcon = Icons.check_circle_rounded;
      iconColor = const Color(0xFF22C55E);
    } else if (isWrongPick) {
      border = const Color(0xFFEF4444);
      background = const Color(0xFFEF4444).withValues(alpha: 0.08);
      trailingIcon = Icons.cancel_rounded;
      iconColor = const Color(0xFFEF4444);
    } else if (isSelected) {
      border = context.primaryColor;
      background = context.primaryColor.withValues(alpha: 0.08);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: isSelected || isCorrect || isWrongPick ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.35,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, color: iconColor, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
