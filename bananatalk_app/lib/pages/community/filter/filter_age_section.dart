import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class FilterAgeSection extends StatelessWidget {
  final double minAge;
  final double maxAge;
  final ValueChanged<RangeValues> onChanged;

  const FilterAgeSection({
    super.key,
    required this.minAge,
    required this.maxAge,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.minAge(minAge.toInt()),
                  style: context.labelLarge.copyWith(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 1,
                color: context.dividerColor,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.maxAge(maxAge.toInt()),
                  style: context.labelLarge.copyWith(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(minAge, maxAge),
            min: 18,
            max: 100,
            divisions: 82,
            activeColor: context.primaryColor,
            inactiveColor: context.dividerColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
