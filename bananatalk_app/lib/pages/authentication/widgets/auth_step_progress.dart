import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Segmented progress bar for multi-step auth wizards.
/// Replaces the simple "Step N of M" pill with a horizontal node-and-segment
/// indicator that shows completed / current / future visually.
///
/// Example:
///   ●━━━━━●━━━━━○━━━━━○
///   Personal  Native  Learn  Done
class AuthStepProgress extends StatelessWidget {
  final int currentStep; // 0-indexed
  final int totalSteps;
  final List<String>? labels;

  /// Optional labels for named *segments* (e.g. "About you" / "Languages" /
  /// "Photo") shown centered under the whole bar, distinct from [labels]
  /// which annotate each individual step node. When provided, the label
  /// matching the segment containing [currentStep] is shown, bolded, below
  /// the bar. Purely additive — existing call sites that only pass
  /// [currentStep]/[totalSteps]/[labels] are unaffected.
  final List<String>? segmentLabels;

  /// Duration of the fill/segment animation when [currentStep] changes.
  /// Defaults to a quick, unobtrusive 300ms.
  final Duration animationDuration;

  const AuthStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
    this.segmentLabels,
    this.animationDuration = const Duration(milliseconds: 300),
  })  : assert(totalSteps > 0),
        assert(currentStep >= 0);

  @override
  Widget build(BuildContext context) {
    final hasLabels = labels != null && labels!.length == totalSteps;
    final hasSegmentLabels = segmentLabels != null && segmentLabels!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (i) {
              final isFirst = i == 0;
              return Expanded(
                child: Row(
                  children: [
                    if (!isFirst)
                      Expanded(
                        child: _Segment(
                          filled: i <= currentStep,
                          duration: animationDuration,
                        ),
                      ),
                    _Node(state: _stateFor(i), duration: animationDuration),
                  ],
                ),
              );
            }),
          ),
          if (hasLabels) ...[
            const SizedBox(height: 8),
            Row(
              children: List.generate(totalSteps, (i) {
                return Expanded(
                  child: Text(
                    labels![i],
                    textAlign: TextAlign.center,
                    style: context.captionSmall.copyWith(
                      color: i == currentStep
                          ? AppColors.primary
                          : context.textMuted,
                      fontWeight: i == currentStep
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ),
          ] else if (hasSegmentLabels) ...[
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: animationDuration,
              child: Text(
                _currentSegmentLabel(),
                key: ValueKey(_currentSegmentLabel()),
                textAlign: TextAlign.center,
                style: context.captionSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Maps the current 0-indexed step to one of [segmentLabels] proportionally
  /// across [totalSteps], so callers don't need to keep a label-per-step list
  /// in sync with a dynamically computed step count.
  String _currentSegmentLabel() {
    final segments = segmentLabels!;
    if (totalSteps <= 0) return segments.first;
    final ratio = currentStep / totalSteps;
    final index = (ratio * segments.length).floor().clamp(0, segments.length - 1);
    return segments[index];
  }

  _NodeState _stateFor(int i) {
    if (i < currentStep) return _NodeState.completed;
    if (i == currentStep) return _NodeState.current;
    return _NodeState.future;
  }
}

enum _NodeState { completed, current, future }

class _Node extends StatelessWidget {
  final _NodeState state;
  final Duration duration;
  const _Node({required this.state, required this.duration});

  @override
  Widget build(BuildContext context) {
    final size = state == _NodeState.current ? 14.0 : 10.0;
    final mutedColor = context.dividerColor.withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (state) {
          _NodeState.completed => AppColors.primary,
          _NodeState.current => AppColors.primary,
          _NodeState.future => mutedColor,
        },
        border: state == _NodeState.future
            ? null
            : Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: state == _NodeState.current ? 3 : 0,
              ),
        boxShadow: state == _NodeState.current
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: state == _NodeState.completed
          ? const Icon(Icons.check, size: 7, color: Colors.white)
          : null,
    );
  }
}

class _Segment extends StatelessWidget {
  final bool filled;
  final Duration duration;
  const _Segment({required this.filled, required this.duration});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: filled
            ? AppColors.primary
            : context.dividerColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
