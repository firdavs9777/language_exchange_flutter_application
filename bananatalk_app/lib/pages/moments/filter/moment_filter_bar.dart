import 'package:flutter/material.dart';

import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
import 'package:bananatalk_app/pages/moments/filter/moment_filter_sheet.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Opens the language / category / mood / time-period sheet.
void showMomentFilterSheet(
  BuildContext context, {
  required MomentFilter currentFilter,
  required ValueChanged<MomentFilter> onFilterChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => MomentFilterSheet(
        currentFilter: currentFilter,
        onApplyFilter: onFilterChanged,
      ),
    ),
  );
}

/// The filter icon at the end of the feed tab row, with a count when filters
/// are on. Replaces the old full-width bar whose Recent / Popular chips
/// re-sorted the feed client-side against each tab's own order.
class MomentFilterButton extends StatelessWidget {
  final MomentFilter currentFilter;
  final ValueChanged<MomentFilter> onFilterChanged;

  const MomentFilterButton({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = currentFilter.hasActiveFilters;
    final count = currentFilter.activeFilterCount;

    return IconButton(
      key: const Key('moments-filter-button'),
      tooltip: AppLocalizations.of(context)!.filters,
      onPressed: () => showMomentFilterSheet(
        context,
        currentFilter: currentFilter,
        onFilterChanged: onFilterChanged,
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: colorScheme.primary,
        textColor: colorScheme.onPrimary,
        child: Icon(
          Icons.tune,
          size: 22,
          color: active ? colorScheme.primary : context.textSecondary,
        ),
      ),
    );
  }
}

/// The filters in effect, each removable, plus "Clear all". Renders nothing
/// when no filter is on, so the feed header stays one row tall.
class MomentActiveFilters extends StatelessWidget {
  final MomentFilter currentFilter;
  final ValueChanged<MomentFilter> onFilterChanged;

  const MomentActiveFilters({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  /// Height of the row when it shows.
  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    if (!currentFilter.hasActiveFilters) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          ...currentFilter.languages.map((lang) {
            final langData = FilterOptions.languages.firstWhere(
              (item) => item['code'] == lang,
              orElse: () => {'code': lang, 'name': lang, 'flag': '🌍'},
            );
            return _chip(
              context,
              '${langData['flag']} ${langData['name']}',
              () => onFilterChanged(currentFilter.copyWith(
                languages: List<String>.from(currentFilter.languages)..remove(lang),
              )),
            );
          }),
          ...currentFilter.categories.map((category) {
            final icon = FilterOptions.categoryIcons[category] ?? '🌐';
            final label = FilterOptions.categoryLabels[category] ?? category;
            return _chip(
              context,
              '$icon $label',
              () => onFilterChanged(currentFilter.copyWith(
                categories: List<String>.from(currentFilter.categories)
                  ..remove(category),
              )),
            );
          }),
          ...currentFilter.moods.map((mood) {
            final emoji = FilterOptions.moodEmojis[mood] ?? '😊';
            return _chip(
              context,
              '$emoji ${mood.capitalize()}',
              () => onFilterChanged(currentFilter.copyWith(
                moods: List<String>.from(currentFilter.moods)..remove(mood),
              )),
            );
          }),
          TextButton(
            onPressed: () => onFilterChanged(currentFilter.clearAll()),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppLocalizations.of(context)!.clearAll,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, VoidCallback onRemove) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.close, size: 14, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
