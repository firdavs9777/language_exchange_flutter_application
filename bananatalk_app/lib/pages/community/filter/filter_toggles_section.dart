import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// A single toggle row used by newUsersOnly and prioritizeNearby sections.
class FilterToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const FilterToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value
            ? activeColor.withValues(alpha: 0.08)
            : context.surfaceColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(
          color: value
              ? activeColor.withValues(alpha: 0.3)
              : context.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: value ? activeColor : context.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value ? activeColor : context.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: context.caption.copyWith(color: context.textMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
          ),
        ],
      ),
    );
  }
}

/// Slider row for "mutual interests minimum" (topicsAtLeast 0–5).
class FilterMutualInterestsSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const FilterMutualInterestsSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.mutualInterestsMin,
                  style: context.bodyMedium,
                ),
              ),
              Text(
                l10n.atLeastNTopics(value),
                style: context.bodySmall.copyWith(color: context.textSecondary),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            label: value.toString(),
            onChanged: (v) => onChanged(v.round()),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
