import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Ordering/reordering exercise widget
class OrderingWidget extends StatefulWidget {
  final Exercise exercise;
  final bool showResult;
  final Function(String) onAnswer;
  final VoidCallback onNext;

  const OrderingWidget({
    super.key,
    required this.exercise,
    required this.showResult,
    required this.onAnswer,
    required this.onNext,
  });

  @override
  State<OrderingWidget> createState() => _OrderingWidgetState();
}

class _OrderingWidgetState extends State<OrderingWidget> {
  List<String> _items = [];
  List<String> _correctOrder = [];
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  void _initializeItems() {

    // Try to get items from scrambledItems first (most specific for ordering)
    if (widget.exercise.scrambledItems != null && widget.exercise.scrambledItems!.isNotEmpty) {
      _items = List.from(widget.exercise.scrambledItems!);
    }
    // Then try options
    else if (widget.exercise.options.isNotEmpty) {
      _items = widget.exercise.options.map((o) => o.text).toList();
    }

    // Try to get correct order from exercise.correctOrder first
    if (widget.exercise.correctOrder != null && widget.exercise.correctOrder!.isNotEmpty) {
      _correctOrder = List.from(widget.exercise.correctOrder!);
    }
    // If correctAnswer is provided, parse it
    else if (widget.exercise.correctAnswer != null) {
      final ca = widget.exercise.correctAnswer!;
      // Check if it's a JSON array string like "[item1, item2, item3]"
      if (ca.startsWith('[') && ca.endsWith(']')) {
        final inner = ca.substring(1, ca.length - 1);
        _correctOrder = inner.split(',').map((s) => s.trim()).toList();
      } else if (ca.contains('|')) {
        // Pipe-separated format
        _correctOrder = ca.split('|').map((s) => s.trim()).toList();
      } else if (ca.contains('/')) {
        // Slash-separated format (common in questions like "Put in order: a / b / c")
        _correctOrder = ca.split('/').map((s) => s.trim()).toList();
      } else {
        // Single value
        _correctOrder = [ca.trim()];
      }
    }

    // If items is empty but we have correct order, use that
    if (_items.isEmpty && _correctOrder.isNotEmpty) {
      _items = List.from(_correctOrder);
    }

    // Last resort: try to parse items from the question (e.g., "Put in order: 가족 / 나에게 / 모든 것")
    if (_items.isEmpty) {
      final question = widget.exercise.question;
      // Look for pattern after colon with slash-separated items
      final colonIndex = question.indexOf(':');
      if (colonIndex != -1 && question.contains('/')) {
        final itemsPart = question.substring(colonIndex + 1).trim();
        _items = itemsPart.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        // If we got items from question and no correct order, use items order as correct
        if (_correctOrder.isEmpty) {
          _correctOrder = List.from(_items);
        }
      }
    }


    // Shuffle items for the exercise (only if we have items)
    if (_items.isNotEmpty) {
      _items.shuffle();
    }
  }

  @override
  void didUpdateWidget(OrderingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showResult && !oldWidget.showResult) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    _isCorrect = _listEquals(_items, _correctOrder);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
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
          'Drag and drop to reorder the items',
          style: context.caption.copyWith(fontStyle: FontStyle.italic),
        ),
        Spacing.gapLG,
        // Question/context
        if (widget.exercise.question.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: Spacing.paddingLG,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: AppRadius.borderMD,
              boxShadow: AppShadows.sm,
            ),
            child: Text(
              widget.exercise.question,
              style: context.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Spacing.gapXL,
        ],
        // Reorderable list
        widget.showResult
            ? _buildResultList()
            : _buildReorderableList(),
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
                      if (!_isCorrect) ...[
                        Spacing.gapXS,
                        Text(
                          'Correct order: ${_correctOrder.join(' → ')}',
                          style: context.bodySmall,
                        ),
                      ],
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
        // Reset button
        if (!widget.showResult) ...[
          Spacing.gapLG,
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _items.shuffle();
                });
              },
              icon: const Icon(Icons.shuffle, size: 18),
              label: const Text('Shuffle'),
              style: TextButton.styleFrom(
                foregroundColor: context.textSecondary,
              ),
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
                : () => widget.onAnswer(_items.join('|')),
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

  Widget _buildReorderableList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        return _buildOrderItem(
          key: ValueKey(_items[index]),
          index: index,
          item: _items[index],
          isReorderable: true,
        );
      },
    );
  }

  Widget _buildResultList() {
    return Column(
      children: _items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isCorrectPosition = index < _correctOrder.length &&
            _correctOrder[index] == item;

        return _buildOrderItem(
          key: ValueKey(item),
          index: index,
          item: item,
          isReorderable: false,
          isCorrect: isCorrectPosition,
        );
      }).toList(),
    );
  }

  Widget _buildOrderItem({
    required Key key,
    required int index,
    required String item,
    required bool isReorderable,
    bool? isCorrect,
  }) {
    return Builder(
      builder: (context) {
        Color backgroundColor = context.surfaceColor;
        Color borderColor = context.dividerColor;
        Color numberColor = AppColors.primary;

        if (isCorrect != null) {
          if (isCorrect) {
            backgroundColor = AppColors.success.withOpacity(0.1);
            borderColor = AppColors.success;
            numberColor = AppColors.success;
          } else {
            backgroundColor = AppColors.error.withOpacity(0.1);
            borderColor = AppColors.error;
            numberColor = AppColors.error;
          }
        }

        return Padding(
          key: key,
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadius.borderMD,
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: numberColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: numberColor,
                    ),
                  ),
                ),
              ),
              title: Text(
                item,
                style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
              trailing: isReorderable
                  ? Icon(
                      Icons.drag_handle,
                      color: context.textMuted,
                    )
                  : (isCorrect != null
                      ? Icon(
                          isCorrect ? Icons.check : Icons.close,
                          color: isCorrect ? AppColors.success : AppColors.error,
                        )
                      : null),
            ),
          ),
        );
      },
    );
  }
}
