import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

/// "Step N of M" dual-segment progress pill shown at the top of
/// [RegisterTwo]. The left segment represents the overall wizard step 1
/// (always filled); the right segment shows fractional progress through
/// the sub-steps of wizard step 2.
class RegisterTwoProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const RegisterTwoProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Step 1 of overall flow (always filled)
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Spacing.hGapSM,
          // Step 2 progress (sub-steps)
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: totalSteps > 0
                      ? (currentStep + 1) / totalSteps
                      : 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small text label "Step {current} of {total}" using the [stepProgress]
/// l10n key (int-templated, added in C2).
class StepProgressLabel extends StatelessWidget {
  final int current;
  final int total;

  const StepProgressLabel({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context)!.stepProgress(current, total),
      style: TextStyle(
        color: context.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
