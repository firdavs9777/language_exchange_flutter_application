import 'package:flutter/material.dart';

import 'moment_filter_model.dart';
import 'filter_chips.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class FilterSortSection extends StatelessWidget {
  final MomentFilter tempFilter;
  final ValueChanged<MomentFilter> onChanged;

  const FilterSortSection({
    super.key,
    required this.tempFilter,
    required this.onChanged,
  });

  String _localizedSortLabel(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'recent':
        return l10n.mostRecent;
      case 'popular':
        return l10n.mostPopular;
      case 'trending':
        return l10n.trending;
      default:
        return value;
    }
  }

  String _localizedDateLabel(BuildContext context, DateFilterType value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case DateFilterType.allTime:
        return l10n.allTime;
      case DateFilterType.today:
        return l10n.today;
      case DateFilterType.thisWeek:
        return l10n.thisWeek;
      case DateFilterType.thisMonth:
        return l10n.thisMonth;
    }
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    String value,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    switch (value) {
      case 'recent':
        icon = Icons.access_time;
        break;
      case 'popular':
        icon = Icons.favorite;
        break;
      case 'trending':
        icon = Icons.local_fire_department;
        break;
      default:
        icon = Icons.sort;
    }

    return InkWell(
      onTap: () => onChanged(tempFilter.copyWith(sortBy: value)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  isSelected ? colorScheme.primary : context.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected ? colorScheme.primary : context.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filterSectionTitle(
            context,
            AppLocalizations.of(context)!.sortBy,
            Icons.sort,
          ),
          const SizedBox(height: 12),
          ...FilterOptions.sortOptions.map((option) {
            final value = option['value']!;
            final label = _localizedSortLabel(context, value);
            final isSelected = tempFilter.sortBy == value;
            return _buildSortOption(context, label, value, isSelected);
          }),
          const SizedBox(height: 24),
          filterSectionTitle(
            context,
            AppLocalizations.of(context)!.timePeriod,
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FilterOptions.dateFilters.map((filter) {
              final value = filter['value'] as DateFilterType;
              final label = _localizedDateLabel(context, value);
              final isSelected = tempFilter.dateFilter == value;

              return filterChip(
                context: context,
                label: label,
                isSelected: isSelected,
                onTap: () =>
                    onChanged(tempFilter.copyWith(dateFilter: value)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
