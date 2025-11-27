import 'package:flutter/material.dart';

import 'moment_filter_model.dart';
import 'moment_filter_sheet.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class MomentFilterBar extends StatelessWidget {
  final MomentFilter currentFilter;
  final ValueChanged<MomentFilter> onFilterChanged;

  const MomentFilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  void _showFilterSheet(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;
    final secondaryText = context.textSecondary;

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildQuickTab(
                        context: context,
                        label: 'Recent',
                        icon: Icons.access_time,
                        isActive: currentFilter.sortBy == 'recent',
                        onTap: () =>
                            onFilterChanged(currentFilter.copyWith(sortBy: 'recent')),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickTab(
                        context: context,
                        label: 'Popular',
                        icon: Icons.trending_up,
                        isActive: currentFilter.sortBy == 'popular',
                        onTap: () =>
                            onFilterChanged(currentFilter.copyWith(sortBy: 'popular')),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickTab(
                        context: context,
                        label: 'Trending',
                        icon: Icons.local_fire_department,
                        isActive: currentFilter.sortBy == 'trending',
                        onTap: () =>
                            onFilterChanged(currentFilter.copyWith(sortBy: 'trending')),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showFilterSheet(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: currentFilter.hasActiveFilters
                          ? colorScheme.primary.withOpacity(0.15)
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: currentFilter.hasActiveFilters
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune,
                          size: 18,
                          color: currentFilter.hasActiveFilters
                              ? colorScheme.primary
                              : secondaryText,
                        ),
                        if (currentFilter.activeFilterCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${currentFilter.activeFilterCount}',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (currentFilter.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...currentFilter.languages.map((lang) {
                      final langData = FilterOptions.languages.firstWhere(
                        (item) => item['code'] == lang,
                        orElse: () => {'code': lang, 'name': lang, 'flag': '🌍'},
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildActiveFilterChip(
                          context: context,
                          label: '${langData['flag']} ${langData['name']}',
                          onRemove: () {
                            final languages = List<String>.from(currentFilter.languages)
                              ..remove(lang);
                            onFilterChanged(
                                currentFilter.copyWith(languages: languages));
                          },
                        ),
                      );
                    }),
                    ...currentFilter.categories.map((category) {
                      final icon = FilterOptions.categoryIcons[category] ?? '🌐';
                      final label = FilterOptions.categoryLabels[category] ?? category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildActiveFilterChip(
                          context: context,
                          label: '$icon $label',
                          onRemove: () {
                            final categories =
                                List<String>.from(currentFilter.categories)
                                  ..remove(category);
                            onFilterChanged(
                                currentFilter.copyWith(categories: categories));
                          },
                        ),
                      );
                    }),
                    ...currentFilter.moods.map((mood) {
                      final emoji = FilterOptions.moodEmojis[mood] ?? '😊';
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildActiveFilterChip(
                          context: context,
                          label: '$emoji ${mood.capitalize()}',
                          onRemove: () {
                            final moods = List<String>.from(currentFilter.moods)
                              ..remove(mood);
                            onFilterChanged(currentFilter.copyWith(moods: moods));
                          },
                        ),
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
                        'Clear All',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            height: 1,
            color: context.dividerColor,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required BuildContext context,
    required String label,
    required VoidCallback onRemove,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
        ),
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
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

