import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Matching exercise widget
class MatchingWidget extends StatefulWidget {
  final Exercise exercise;
  final bool showResult;
  final Function(String) onAnswer;
  final VoidCallback onNext;

  const MatchingWidget({
    super.key,
    required this.exercise,
    required this.showResult,
    required this.onAnswer,
    required this.onNext,
  });

  @override
  State<MatchingWidget> createState() => _MatchingWidgetState();
}

class _MatchingWidgetState extends State<MatchingWidget> {
  String? _selectedLeft;
  final Map<String, String> _matches = {};
  List<String> _leftItems = [];
  List<String> _rightItems = [];
  Map<String, String> _correctMatches = {};
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  void _initializeItems() {
    // Extract pairs from matching pairs or options
    final pairs = widget.exercise.matchingPairs;

    // Log each pair
    for (int i = 0; i < pairs.length; i++) {
    }

    if (pairs.isNotEmpty) {
      _leftItems = pairs.map((p) => p.left).toList();
      _rightItems = pairs.map((p) => p.right).toList()..shuffle();
      _correctMatches = {for (var p in pairs) p.left: p.right};
    } else {
      // Fallback to options if no matching pairs

      _leftItems = widget.exercise.options
          .where((o) => o.id.startsWith('l'))
          .map((o) => o.text)
          .toList();
      _rightItems = widget.exercise.options
          .where((o) => o.id.startsWith('r'))
          .map((o) => o.text)
          .toList()
        ..shuffle();
      _correctMatches = {};

      // If still empty, try to use all options as left items (last resort)
      if (_leftItems.isEmpty && widget.exercise.options.isNotEmpty) {
        _leftItems = widget.exercise.options.map((o) => o.text).toList();
        _rightItems = [];
      }
    }

  }

  void _checkResults() {
    _correctCount = 0;
    for (var entry in _matches.entries) {
      if (_correctMatches[entry.key] == entry.value) {
        _correctCount++;
      }
    }
  }

  Widget _buildNoDataState() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            widget.exercise.question,
            style: context.titleLarge,
          ),
          Spacing.gapXL,
          // Error message
          Container(
            width: double.infinity,
            padding: Spacing.paddingXL,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: AppRadius.borderMD,
              border: Border.all(color: AppColors.warning.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.warning, size: 48),
                Spacing.gapMD,
                Text(
                  'Matching data not available',
                  style: context.titleMedium.copyWith(color: AppColors.warning),
                ),
                Spacing.gapSM,
                Text(
                  'This exercise could not load the matching pairs. Please try regenerating the lesson.',
                  textAlign: TextAlign.center,
                  style: context.bodySmall,
                ),
              ],
            ),
          ),
          Spacing.gapXL,
          // Skip button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
              child: const Text(
                'Skip Exercise',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(MatchingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showResult && !oldWidget.showResult) {
      _checkResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no items to match, show error state
    if (_leftItems.isEmpty || _rightItems.isEmpty) {
      return _buildNoDataState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruction
        Text(
          widget.exercise.instruction,
          style: context.bodySmall,
        ),
        Spacing.gapSM,
        Text(
          'Tap an item on the left, then tap its match on the right',
          style: context.caption.copyWith(fontStyle: FontStyle.italic),
        ),
        Spacing.gapXL,
        // Progress indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_matches.length}/${_leftItems.length} matched',
              style: context.labelLarge.copyWith(color: context.textSecondary),
            ),
          ],
        ),
        Spacing.gapLG,
        // Matching area
        Row(
          children: [
            // Left column
            Expanded(
              child: Column(
                children: _leftItems.map((item) {
                  final isSelected = _selectedLeft == item;
                  final isMatched = _matches.containsKey(item);
                  final isCorrect = widget.showResult &&
                      _matches[item] == _correctMatches[item];
                  final isIncorrect = widget.showResult &&
                      isMatched &&
                      _matches[item] != _correctMatches[item];

                  Color backgroundColor = context.surfaceColor;
                  Color borderColor = context.dividerColor;

                  if (widget.showResult) {
                    if (isCorrect) {
                      backgroundColor = AppColors.success.withOpacity(0.1);
                      borderColor = AppColors.success;
                    } else if (isIncorrect) {
                      backgroundColor = AppColors.error.withOpacity(0.1);
                      borderColor = AppColors.error;
                    }
                  } else if (isSelected) {
                    backgroundColor = AppColors.primary.withOpacity(0.1);
                    borderColor = AppColors.primary;
                  } else if (isMatched) {
                    backgroundColor = AppColors.info.withOpacity(0.1);
                    borderColor = AppColors.info;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: widget.showResult
                          ? null
                          : () {
                              setState(() {
                                if (_selectedLeft == item) {
                                  _selectedLeft = null;
                                } else {
                                  _selectedLeft = item;
                                }
                              });
                            },
                      borderRadius: AppRadius.borderMD,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: AppRadius.borderMD,
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected || isMatched
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                            ),
                            if (isMatched && !widget.showResult)
                              const Icon(
                                Icons.link,
                                size: 16,
                                color: AppColors.info,
                              ),
                            if (widget.showResult)
                              Icon(
                                isCorrect ? Icons.check : Icons.close,
                                size: 16,
                                color: isCorrect ? AppColors.success : AppColors.error,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Connection lines
            Spacing.hGapLG,
            // Right column
            Expanded(
              child: Column(
                children: _rightItems.map((item) {
                  final matchedLeft = _matches.entries
                      .where((e) => e.value == item)
                      .map((e) => e.key)
                      .firstOrNull;
                  final isMatched = matchedLeft != null;
                  final isCorrect = widget.showResult &&
                      isMatched &&
                      _correctMatches[matchedLeft] == item;
                  final isIncorrect = widget.showResult &&
                      isMatched &&
                      _correctMatches[matchedLeft] != item;

                  Color backgroundColor = context.surfaceColor;
                  Color borderColor = context.dividerColor;

                  if (widget.showResult) {
                    if (isCorrect) {
                      backgroundColor = AppColors.success.withOpacity(0.1);
                      borderColor = AppColors.success;
                    } else if (isIncorrect) {
                      backgroundColor = AppColors.error.withOpacity(0.1);
                      borderColor = AppColors.error;
                    }
                  } else if (isMatched) {
                    backgroundColor = AppColors.info.withOpacity(0.1);
                    borderColor = AppColors.info;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: widget.showResult || _selectedLeft == null
                          ? null
                          : () {
                              setState(() {
                                // Remove any existing match for this right item
                                _matches.removeWhere((k, v) => v == item);
                                // Add new match
                                _matches[_selectedLeft!] = item;
                                _selectedLeft = null;
                              });
                            },
                      borderRadius: AppRadius.borderMD,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: AppRadius.borderMD,
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isMatched && !widget.showResult)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.link,
                                  size: 16,
                                  color: AppColors.info,
                                ),
                              ),
                            if (widget.showResult && isMatched)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  isCorrect ? Icons.check : Icons.close,
                                  size: 16,
                                  color: isCorrect ? AppColors.success : AppColors.error,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isMatched ? FontWeight.w600 : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        // Clear button
        if (!widget.showResult && _matches.isNotEmpty) ...[
          Spacing.gapLG,
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _matches.clear();
                  _selectedLeft = null;
                });
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(
                foregroundColor: context.textSecondary,
              ),
            ),
          ),
        ],
        // Result summary
        if (widget.showResult) ...[
          Spacing.gapLG,
          Container(
            width: double.infinity,
            padding: Spacing.paddingLG,
            decoration: BoxDecoration(
              color: _correctCount == _leftItems.length
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: AppRadius.borderMD,
              border: Border.all(
                color: _correctCount == _leftItems.length
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _correctCount == _leftItems.length
                      ? Icons.check_circle
                      : Icons.info,
                  color: _correctCount == _leftItems.length
                      ? AppColors.success
                      : AppColors.warning,
                ),
                Spacing.hGapMD,
                Text(
                  '$_correctCount/${_leftItems.length} correct',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _correctCount == _leftItems.length
                        ? AppColors.success
                        : AppColors.warning,
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
                : (_matches.length == _leftItems.length
                    ? () {
                        // Encode matches as JSON string
                        final answer = _matches.entries
                            .map((e) => '${e.key}:${e.value}')
                            .join('|');
                        widget.onAnswer(answer);
                      }
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
