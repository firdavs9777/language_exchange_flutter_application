import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/widgets/learning/vocabulary_card.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_add_screen.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_review_screen.dart';
import 'package:bananatalk_app/pages/learning/widgets/learning_empty_state.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';

enum _MasteryFilter { all, brandNew, learning, mastered }

enum _SortOption { recent, alphabetical, mastery }

/// Vocabulary list screen
class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  final TextEditingController _searchController = TextEditingController();
  _MasteryFilter _selectedFilter = _MasteryFilter.all;
  _SortOption _sort = _SortOption.recent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 0 = new, 1 = learning, 2 = mastered
  int _classifyMastery(VocabularyItem v) {
    final lvl = v.srsLevel;
    if (lvl <= 0) return 0;
    if (lvl >= 9) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(vocabularyFilterProvider);
    final vocabularyAsync = ref.watch(vocabularyListProvider(filter));
    final statsAsync = ref.watch(vocabularyStatsProvider(null));

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        title: Text(
          'Vocabulary',
          style: context.titleLarge,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _SortOption.recent,
                child: Text(l10n.learningVocabularySortRecent),
              ),
              PopupMenuItem(
                value: _SortOption.alphabetical,
                child: Text(l10n.learningVocabularySortAlphabetical),
              ),
              PopupMenuItem(
                value: _SortOption.mastery,
                child: Text(l10n.learningVocabularySortMastery),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.replay_rounded),
            color: AppColors.primary,
            onPressed: () {
              Navigator.push(
                context,
                AppPageRoute(
                  builder: (_) => const VocabularyReviewScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats and Search Bar
          Container(
            color: context.surfaceColor,
            padding: Spacing.paddingLG,
            child: Column(
              children: [
                // Stats Row
                statsAsync.when(
                  data: (stats) {
                    if (stats == null) return const SizedBox.shrink();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total', stats.total, Colors.blue),
                        _buildStatItem('Learning', stats.learning, Colors.orange),
                        _buildStatItem('Mastered', stats.mastered, Colors.green),
                        _buildStatItem(
                            'Due', stats.dueToday, Colors.red),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height: 40),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                Spacing.gapLG,
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.learningVocabularySearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              ref.read(vocabularyFilterProvider.notifier).state =
                                  filter.copyWith(clearSearch: true);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: context.containerColor,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderMD,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    ref.read(vocabularyFilterProvider.notifier).state =
                        filter.copyWith(search: value.isEmpty ? null : value);
                  },
                ),
                Spacing.gapMD,
                // Mastery Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMasteryChip(l10n.learningVocabularyFilterAll, _MasteryFilter.all),
                      _buildMasteryChip(l10n.learningVocabularyFilterNew, _MasteryFilter.brandNew),
                      _buildMasteryChip(l10n.learningVocabularyFilterLearning, _MasteryFilter.learning),
                      _buildMasteryChip(l10n.learningVocabularyFilterMastered, _MasteryFilter.mastered),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Vocabulary List
          Expanded(
            child: vocabularyAsync.when(
              data: (items) {
                // Apply local mastery filter
                final filtered = items.where((v) {
                  final masteryClass = _classifyMastery(v);
                  return switch (_selectedFilter) {
                    _MasteryFilter.all => true,
                    _MasteryFilter.brandNew => masteryClass == 0,
                    _MasteryFilter.learning => masteryClass == 1,
                    _MasteryFilter.mastered => masteryClass == 2,
                  };
                }).toList();

                // Apply local sort
                switch (_sort) {
                  case _SortOption.recent:
                    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  case _SortOption.alphabetical:
                    filtered.sort((a, b) =>
                        a.word.toLowerCase().compareTo(b.word.toLowerCase()));
                  case _SortOption.mastery:
                    filtered.sort(
                        (a, b) => b.srsLevel.compareTo(a.srsLevel));
                }

                if (filtered.isEmpty) {
                  return LearningEmptyState(
                    icon: _searchController.text.isNotEmpty ||
                            _selectedFilter != _MasteryFilter.all
                        ? Icons.search_off
                        : Icons.text_fields_rounded,
                    message: _searchController.text.isNotEmpty ||
                            _selectedFilter != _MasteryFilter.all
                        ? l10n.learningEmptySearchResults
                        : l10n.learningEmptyVocab,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(vocabularyListProvider(filter));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return VocabularyCard(
                        item: item,
                        masteryChip: _MasteryChip(srsLevel: item.srsLevel),
                        onTap: () {
                          // TODO: Open vocabulary detail/edit
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Word'),
                              content: Text(
                                  'Are you sure you want to delete "${item.word}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            // TODO: Delete vocabulary
                            ref.invalidate(vocabularyListProvider(filter));
                          }
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: context.textMuted),
                    Spacing.gapLG,
                    Text(
                      'Failed to load vocabulary',
                      style: context.bodyMedium.copyWith(color: context.textSecondary),
                    ),
                    Spacing.gapLG,
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(vocabularyListProvider(filter)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            AppPageRoute(builder: (_) => const VocabularyAddScreen()),
          ).then((_) {
            ref.invalidate(vocabularyListProvider(filter));
            ref.invalidate(vocabularyStatsProvider(null));
          });
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Word'),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Builder(
      builder: (context) => Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: context.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryChip(String label, _MasteryFilter value) {
    final isSelected = _selectedFilter == value;
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedFilter = value),
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : context.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

class _MasteryChip extends StatelessWidget {
  final int srsLevel;
  const _MasteryChip({required this.srsLevel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, label) = _classify(context, l10n, srsLevel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _classify(
      BuildContext context, AppLocalizations l10n, int lvl) {
    if (lvl <= 0) {
      return (Theme.of(context).colorScheme.outline,
          l10n.learningVocabularyMasteryNew);
    }
    if (lvl >= 9) {
      return (Colors.green, l10n.learningVocabularyMasteryMastered);
    }
    return (Colors.orange, l10n.learningVocabularyMasteryLearning);
  }
}
