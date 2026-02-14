import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/widgets/learning/vocabulary_card.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_add_screen.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_review_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Vocabulary list screen
class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.replay_rounded),
            color: AppColors.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
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
                    hintText: 'Search vocabulary...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
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
                    ref.read(vocabularyFilterProvider.notifier).state =
                        filter.copyWith(search: value.isEmpty ? null : value);
                  },
                ),
                Spacing.gapMD,
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      _buildFilterChip('New', '0'),
                      _buildFilterChip('Learning', '1-3'),
                      _buildFilterChip('Known', '4-8'),
                      _buildFilterChip('Mastered', '9'),
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
                if (items.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(vocabularyListProvider(filter));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return VocabularyCard(
                        item: item,
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
            MaterialPageRoute(builder: (_) => const VocabularyAddScreen()),
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

  Widget _buildFilterChip(String label, String? srsLevel) {
    final filter = ref.watch(vocabularyFilterProvider);
    final isSelected = filter.srsLevel == srsLevel;

    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              // Apply filter or clear if "All" (srsLevel is null)
              ref.read(vocabularyFilterProvider.notifier).state = srsLevel == null
                  ? filter.copyWith(clearSrsLevel: true)
                  : filter.copyWith(srsLevel: srsLevel);
            } else {
              // Deselecting - clear the filter
              ref.read(vocabularyFilterProvider.notifier).state =
                  filter.copyWith(clearSrsLevel: true);
            }
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : context.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_fields_rounded, size: 64, color: context.textMuted),
            Spacing.gapLG,
            Text(
              'No vocabulary yet',
              style: context.titleLarge,
            ),
            Spacing.gapSM,
            Text(
              'Start adding words to build your collection',
              style: context.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
