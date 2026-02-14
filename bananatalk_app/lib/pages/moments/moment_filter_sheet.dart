import 'package:flutter/material.dart';

import 'moment_filter_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

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

class _MomentFilterSheetState extends State<MomentFilterSheet>
    with SingleTickerProviderStateMixin {
  late MomentFilter _tempFilter;
  late TabController _tabController;
  final TextEditingController _languageSearchController =
      TextEditingController();
  String _languageQuery = '';

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _languageSearchController.dispose();
    super.dispose();
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

  List<Map<String, String>> get _filteredLanguages {
    if (_languageQuery.isEmpty) {
      return FilterOptions.languages;
    }
    return FilterOptions.languages
        .where((lang) =>
            lang['name']!.toLowerCase().contains(_languageQuery.toLowerCase()) ||
            lang['code']!.toLowerCase().contains(_languageQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            _buildHeader(context),
            Divider(height: 1, color: colorScheme.outlineVariant),
            // Tab bar
            Container(
              color: colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: colorScheme.primary,
                unselectedLabelColor: context.textSecondary,
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 16),
                        const SizedBox(width: 4),
                        const Text('Sort'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.translate, size: 16),
                        const SizedBox(width: 4),
                        const Text('Language'),
                        if (_tempFilter.languages.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          _buildBadge(_tempFilter.languages.length),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category, size: 16),
                        const SizedBox(width: 4),
                        const Text('Category'),
                        if (_tempFilter.categories.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          _buildBadge(_tempFilter.categories.length),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_emotions, size: 16),
                        const SizedBox(width: 4),
                        const Text('Mood'),
                        if (_tempFilter.moods.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          _buildBadge(_tempFilter.moods.length),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSortTab(context),
                  _buildLanguageTab(context),
                  _buildCategoryTab(context),
                  _buildMoodTab(context),
                ],
              ),
            ),
            // Apply button
            _buildApplyButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;
    final secondaryText = context.textSecondary;

    return Padding(
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
          Row(
            children: [
              Icon(Icons.tune, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              if (_tempFilter.activeFilterCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_tempFilter.activeFilterCount} active',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
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
    );
  }

  Widget _buildSortTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Sort By', Icons.sort),
          const SizedBox(height: 12),
          ...FilterOptions.sortOptions.map((option) {
            final value = option['value']!;
            final label = option['label']!;
            final isSelected = _tempFilter.sortBy == value;
            return _buildSortOption(context, label, value, isSelected);
          }),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Time Period', Icons.calendar_today),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FilterOptions.dateFilters.map((filter) {
              final label = filter['label'] as String;
              final value = filter['value'] as DateFilterType;
              final isSelected = _tempFilter.dateFilter == value;

              return _buildFilterChip(
                context: context,
                label: label,
                isSelected: isSelected,
                onTap: () => _setDateFilter(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(
      BuildContext context, String label, String value, bool isSelected) {
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
      onTap: () => _setSortBy(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? colorScheme.primary : context.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected ? colorScheme.primary : context.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

  Widget _buildLanguageTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredLangs = _filteredLanguages;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _languageSearchController,
            onChanged: (value) => setState(() => _languageQuery = value),
            decoration: InputDecoration(
              hintText: 'Search languages...',
              prefixIcon: Icon(Icons.search, color: context.textSecondary),
              filled: true,
              fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _languageQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _languageSearchController.clear();
                        setState(() => _languageQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        // Selected languages
        if (_tempFilter.languages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Selected',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_tempFilter.languages.length}',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tempFilter.languages.map((langCode) {
                    final langData = FilterOptions.languages.firstWhere(
                      (item) => item['code'] == langCode,
                      orElse: () =>
                          {'code': langCode, 'name': langCode, 'flag': '🌍'},
                    );
                    return Chip(
                      label: Text(
                          '${langData['flag']} ${langData['name']}'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _toggleLanguage(langCode),
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      side: BorderSide(color: colorScheme.primary),
                      labelStyle: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Divider(color: colorScheme.outlineVariant),
              ],
            ),
          ),
        // Language list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredLangs.length,
            itemBuilder: (context, index) {
              final lang = filteredLangs[index];
              final isSelected =
                  _tempFilter.languages.contains(lang['code']);

              return ListTile(
                onTap: () => _toggleLanguage(lang['code']!),
                leading: Text(
                  lang['flag']!,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  lang['name']!,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected ? colorScheme.primary : context.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : Icon(Icons.circle_outlined,
                        color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected
                    ? colorScheme.primary.withOpacity(0.05)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Categories', Icons.category),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: FilterOptions.categories.map((category) {
              final isSelected = _tempFilter.categories.contains(category);
              final icon = FilterOptions.categoryIcons[category] ?? '🌐';
              final label = FilterOptions.categoryLabels[category] ?? category;

              return _buildFilterChip(
                context: context,
                label: '$icon $label',
                isSelected: isSelected,
                onTap: () => _toggleCategory(category),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Moods', Icons.emoji_emotions),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: FilterOptions.moods.map((mood) {
              final isSelected = _tempFilter.moods.contains(mood);
              final emoji = FilterOptions.moodEmojis[mood] ?? '😊';

              return _buildMoodChip(
                context: context,
                emoji: emoji,
                label: mood.capitalize(),
                isSelected: isSelected,
                onTap: () => _toggleMood(mood),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.15)
              : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? colorScheme.primary : context.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChip({
    required BuildContext context,
    required String emoji,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.15)
              : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colorScheme.primary : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              widget.onApplyFilter(_tempFilter);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check, size: 20),
                const SizedBox(width: 8),
                Text(
                  _tempFilter.activeFilterCount > 0
                      ? 'Apply ${_tempFilter.activeFilterCount} Filters'
                      : 'Apply Filters',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
