import 'package:flutter/material.dart';

import 'moment_filter_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class MomentFilterSheet extends StatefulWidget {
  final MomentFilter currentFilter;
  final ValueChanged<MomentFilter> onApplyFilter;

  const MomentFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApplyFilter,
  });

  @override
  State<MomentFilterSheet> createState() => _MomentFilterSheetState();
}

class _MomentFilterSheetState extends State<MomentFilterSheet> {
  late MomentFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
  }

  void _toggleLanguage(String langCode) {
    setState(() {
      final languages = List<String>.from(_tempFilter.languages);
      if (languages.contains(langCode)) {
        languages.remove(langCode);
      } else {
        languages.add(langCode);
      }
      _tempFilter = _tempFilter.copyWith(languages: languages);
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      final categories = List<String>.from(_tempFilter.categories);
      if (categories.contains(category)) {
        categories.remove(category);
      } else {
        categories.add(category);
      }
      _tempFilter = _tempFilter.copyWith(categories: categories);
    });
  }

  void _toggleMood(String mood) {
    setState(() {
      final moods = List<String>.from(_tempFilter.moods);
      if (moods.contains(mood)) {
        moods.remove(mood);
      } else {
        moods.add(mood);
      }
      _tempFilter = _tempFilter.copyWith(moods: moods);
    });
  }

  void _setSortBy(String sortBy) {
    setState(() {
      _tempFilter = _tempFilter.copyWith(sortBy: sortBy);
    });
  }

  void _setDateFilter(DateFilterType dateFilter) {
    setState(() {
      _tempFilter = _tempFilter.copyWith(dateFilter: dateFilter);
    });
  }

  void _clearAll() {
    setState(() {
      _tempFilter = const MomentFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;
    final secondaryText = context.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onApplyFilter(_tempFilter);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Sort By'),
                    const SizedBox(height: 12),
                    _buildSortOptions(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Date'),
                    const SizedBox(height: 12),
                    _buildDateFilters(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Language'),
                    const SizedBox(height: 12),
                    _buildLanguageChips(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Category'),
                    const SizedBox(height: 12),
                    _buildCategoryChips(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Mood'),
                    const SizedBox(height: 12),
                    _buildMoodChips(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildSortOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: FilterOptions.sortOptions.map((option) {
        final value = option['value']!;
        final label = option['label']!;
        final isSelected = _tempFilter.sortBy == value;
        return RadioListTile<String>(
          value: value,
          groupValue: _tempFilter.sortBy,
          onChanged: (val) => _setSortBy(val!),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? colorScheme.primary : context.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          activeColor: colorScheme.primary,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildDateFilters(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FilterOptions.dateFilters.map((filter) {
        final label = filter['label'] as String;
        final value = filter['value'] as DateFilterType;
        final isSelected = _tempFilter.dateFilter == value;

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => _setDateFilter(value),
          backgroundColor: colorScheme.surfaceVariant,
          selectedColor: colorScheme.primary.withOpacity(0.2),
          checkmarkColor: colorScheme.primary,
          labelStyle: TextStyle(
            fontSize: 13,
            color: isSelected ? colorScheme.primary : context.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FilterOptions.languages.map((lang) {
        final code = lang['code']!;
        final name = lang['name']!;
        final flag = lang['flag']!;
        final isSelected = _tempFilter.languages.contains(code);

        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(name),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => _toggleLanguage(code),
          backgroundColor: colorScheme.surfaceVariant,
          selectedColor: colorScheme.primary.withOpacity(0.2),
          checkmarkColor: colorScheme.primary,
          labelStyle: TextStyle(
            fontSize: 13,
            color: isSelected ? colorScheme.primary : context.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FilterOptions.categories.map((category) {
        final isSelected = _tempFilter.categories.contains(category);
        final icon = FilterOptions.categoryIcons[category] ?? '🌐';
        final label = FilterOptions.categoryLabels[category] ?? category;

        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => _toggleCategory(category),
          backgroundColor: colorScheme.surfaceVariant,
          selectedColor: colorScheme.primary.withOpacity(0.2),
          checkmarkColor: colorScheme.primary,
          labelStyle: TextStyle(
            fontSize: 13,
            color: isSelected ? colorScheme.primary : context.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildMoodChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FilterOptions.moods.map((mood) {
        final isSelected = _tempFilter.moods.contains(mood);
        final emoji = FilterOptions.moodEmojis[mood] ?? '😊';

        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(mood.capitalize()),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => _toggleMood(mood),
          backgroundColor: colorScheme.surfaceVariant,
          selectedColor: colorScheme.primary.withOpacity(0.2),
          checkmarkColor: colorScheme.primary,
          labelStyle: TextStyle(
            fontSize: 13,
            color: isSelected ? colorScheme.primary : context.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        );
      }).toList(),
    );
  }
}

