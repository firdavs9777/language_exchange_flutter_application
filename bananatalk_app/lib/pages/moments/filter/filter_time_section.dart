import 'package:flutter/material.dart';

import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
import 'package:bananatalk_app/pages/moments/filter/filter_chips.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Time-period filter (today / this week / this month / all time).
///
/// There is no "Sort by" here any more: each feed tab has its own order (For
/// You and Trending ranked by the server, Following newest first), and a
/// client-side re-sort only ever reordered the pages already loaded.
class FilterTimeSection extends StatelessWidget {
  final MomentFilter tempFilter;
  final ValueChanged<MomentFilter> onChanged;

  const FilterTimeSection({
    super.key,
    required this.tempFilter,
    required this.onChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              return filterChip(
                context: context,
                label: _localizedDateLabel(context, value),
                isSelected: tempFilter.dateFilter == value,
                onTap: () => onChanged(tempFilter.copyWith(dateFilter: value)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
