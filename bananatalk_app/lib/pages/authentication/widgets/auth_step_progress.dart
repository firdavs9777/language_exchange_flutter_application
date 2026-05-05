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

  const AuthStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
  })  : assert(totalSteps > 0),
        assert(currentStep >= 0);

  @override
  Widget build(BuildContext context) {
    final hasLabels = labels != null && labels!.length == totalSteps;

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
                    if (!isFirst) Expanded(child: _Segment(filled: i <= currentStep)),
                    _Node(state: _stateFor(i)),
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
          ],
        ],
      ),
    );
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
  const _Node({required this.state});

  @override
  Widget build(BuildContext context) {
    final size = state == _NodeState.current ? 14.0 : 10.0;
    final mutedColor = context.dividerColor.withValues(alpha: 0.6);

    return Container(
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
  const _Segment({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
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
