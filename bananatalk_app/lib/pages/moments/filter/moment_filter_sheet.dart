import 'package:flutter/material.dart';

import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
import 'package:bananatalk_app/pages/moments/filter/filter_chips.dart';
import 'package:bananatalk_app/pages/moments/filter/filter_sort_section.dart';
import 'package:bananatalk_app/pages/moments/filter/filter_language_section.dart';
import 'package:bananatalk_app/pages/moments/filter/filter_category_section.dart';
import 'package:bananatalk_app/pages/moments/filter/filter_mood_section.dart';
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

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _tempFilter = const MomentFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                        Text(AppLocalizations.of(context)!.sort),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.translate, size: 16),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context)!.language),
                        if (_tempFilter.languages.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          filterBadge(context, _tempFilter.languages.length),
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
                        Text(AppLocalizations.of(context)!.category),
                        if (_tempFilter.categories.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          filterBadge(context, _tempFilter.categories.length),
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
                        Text(AppLocalizations.of(context)!.mood),
                        if (_tempFilter.moods.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          filterBadge(context, _tempFilter.moods.length),
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
                  FilterSortSection(
                    tempFilter: _tempFilter,
                    onChanged: (f) => setState(() => _tempFilter = f),
                  ),
                  FilterLanguageSection(
                    tempFilter: _tempFilter,
                    onChanged: (f) => setState(() => _tempFilter = f),
                  ),
                  FilterCategorySection(
                    tempFilter: _tempFilter,
                    onChanged: (f) => setState(() => _tempFilter = f),
                  ),
                  FilterMoodSection(
                    tempFilter: _tempFilter,
                    onChanged: (f) => setState(() => _tempFilter = f),
                  ),
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
              AppLocalizations.of(context)!.clearAll,
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
                AppLocalizations.of(context)!.filters,
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
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_tempFilter.activeFilterCount} ${AppLocalizations.of(context)!.active}',
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
              AppLocalizations.of(context)!.momentsFilterApply,
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

  Widget _buildApplyButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                      ? AppLocalizations.of(context)!
                          .applyNFilters(_tempFilter.activeFilterCount)
                      : AppLocalizations.of(context)!.applyFilters,
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
