import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/user_limits.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class LimitIndicator extends StatelessWidget {
  final LimitInfo limit;
  final String label;
  final bool compact;

  const LimitIndicator({
    super.key,
    required this.limit,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;
    final secondaryText = context.textSecondary;

    if (limit.isUnlimited) {
      return compact
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.all_inclusive, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Unlimited',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.all_inclusive, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Unlimited $label',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
    }

    final percentage = limit.usagePercentage;
    Color progressColor;
    if (percentage >= 1.0) {
      progressColor = colorScheme.error;
    } else if (percentage >= 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = colorScheme.primary;
    }

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${limit.remainingInt} left',
            style: TextStyle(
              fontSize: 12,
              color: secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                limit.displayText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: percentage >= 1.0
                      ? colorScheme.error
                      : percentage >= 0.8
                          ? Colors.orange
                          : textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            limit.remainingText,
            style: TextStyle(
              fontSize: 12,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display all limits in a compact view
class AllLimitsIndicator extends StatelessWidget {
  final UserLimits limits;

  const AllLimitsIndicator({
    super.key,
    required this.limits,
  });

  @override
  Widget build(BuildContext context) {
    if (limits.isVIP) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.all_inclusive, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'VIP - Unlimited',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LimitIndicator(
          limit: limits.messages,
          label: 'Messages',
          compact: true,
        ),
        const SizedBox(height: 8),
        LimitIndicator(
          limit: limits.moments,
          label: 'Moments',
          compact: true,
        ),
        const SizedBox(height: 8),
        LimitIndicator(
          limit: limits.comments,
          label: 'Comments',
          compact: true,
        ),
      ],
    );
  }
}

