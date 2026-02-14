import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/widgets/learning/lesson_card.dart';
import 'package:bananatalk_app/pages/learning/lessons/lesson_player_screen.dart';
import 'package:bananatalk_app/pages/ai/lesson_builder/lesson_builder_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Lessons browse screen
class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  String? _selectedLevel;

  final List<String> _categories = [
    'all',
    'grammar',
    'vocabulary',
    'conversation',
    'reading',
    'writing',
    'listening',
    'culture',
  ];

  final List<String> _levels = ['all', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(lessonFilterProvider);
    final lessonsAsync = ref.watch(lessonsProvider(filter));
    final recommendedAsync = ref.watch(recommendedLessonsProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        title: Text(
          'Lessons',
          style: context.titleLarge,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Recommended'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Browse Tab
          Column(
            children: [
              // Filters
              Container(
                color: context.surfaceColor,
                padding: Spacing.paddingLG,
                child: Column(
                  children: [
                    // Category Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category ||
                              (_selectedCategory == null && category == 'all');
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(_formatCategory(category)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory =
                                      selected && category != 'all'
                                          ? category
                                          : null;
                                });
                                ref.read(lessonFilterProvider.notifier).state =
                                    filter.copyWith(
                                  category: _selectedCategory,
                                );
                              },
                              selectedColor:
                                  AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : context.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Spacing.gapMD,
                    // Level Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _levels.map((level) {
                          final isSelected = _selectedLevel == level ||
                              (_selectedLevel == null && level == 'all');
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_formatLevel(level)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedLevel =
                                      selected && level != 'all' ? level : null;
                                });
                                ref.read(lessonFilterProvider.notifier).state =
                                    filter.copyWith(
                                  level: _selectedLevel,
                                );
                              },
                              selectedColor: _getLevelColor(level),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : context.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              // Lessons List
              Expanded(
                child: lessonsAsync.when(
                  data: (lessons) {
                    debugPrint('📚 Lessons list count: ${lessons.length}');
                    if (lessons.isEmpty) {
                      return _buildEmptyState();
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(lessonsProvider(filter));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = lessons[index];
                          return LessonCard(
                            lesson: lesson,
                            onTap: () => _openLesson(lesson.id),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (error, stack) => _buildErrorState(
                    onRetry: () => ref.invalidate(lessonsProvider(filter)),
                  ),
                ),
              ),
            ],
          ),
          // Recommended Tab
          recommendedAsync.when(
            data: (lessons) {
              if (lessons.isEmpty) {
                return _buildEmptyState(
                    message: 'No recommended lessons available');
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(recommendedLessonsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return LessonCard(
                      lesson: lesson,
                      onTap: () => _openLesson(lesson.id),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, stack) => _buildErrorState(
              onRetry: () => ref.invalidate(recommendedLessonsProvider),
            ),
          ),
        ],
      ),
    );
  }

  void _openLesson(String lessonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPlayerScreen(lessonId: lessonId),
      ),
    ).then((_) {
      ref.invalidate(lessonsProvider(ref.read(lessonFilterProvider)));
      ref.invalidate(recommendedLessonsProvider);
    });
  }

  String _formatCategory(String category) {
    if (category == 'all') return 'All';
    return category[0].toUpperCase() + category.substring(1);
  }

  String _formatLevel(String level) {
    if (level == 'all') return 'All Levels';
    switch (level) {
      case 'A1':
        return 'A1 Beginner';
      case 'A2':
        return 'A2 Elementary';
      case 'B1':
        return 'B1 Intermediate';
      case 'B2':
        return 'B2 Upper-Int';
      case 'C1':
        return 'C1 Advanced';
      case 'C2':
        return 'C2 Proficient';
      default:
        return level;
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return const Color(0xFF4CAF50); // Green
      case 'A2':
        return const Color(0xFF8BC34A); // Light Green
      case 'B1':
        return const Color(0xFFFF9800); // Orange
      case 'B2':
        return const Color(0xFFFF5722); // Deep Orange
      case 'C1':
        return const Color(0xFFE91E63); // Pink
      case 'C2':
        return const Color(0xFF9C27B0); // Purple
      default:
        return AppColors.primary;
    }
  }

  Widget _buildEmptyState({String? message}) {
    return Builder(
      builder: (context) => Center(
        child: Padding(
          padding: Spacing.paddingXXL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: AppRadius.borderXL,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  size: 50,
                  color: AppColors.accent,
                ),
              ),
              Spacing.gapXL,
              Text(
                message ?? 'No lessons found',
                style: context.titleLarge,
              ),
              Spacing.gapSM,
              Text(
                'Create your own custom lesson with AI',
                textAlign: TextAlign.center,
                style: context.bodySmall,
              ),
              Spacing.gapXXL,
              ElevatedButton.icon(
                onPressed: _openLessonBuilder,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Create Lesson with AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMD,
                  ),
                ),
              ),
              Spacing.gapMD,
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedLevel = null;
                  });
                  ref.read(lessonFilterProvider.notifier).state =
                      const LessonFilter();
                },
                child: Text(
                  'Clear filters',
                  style: TextStyle(color: context.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLessonBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LessonBuilderScreen(),
      ),
    ).then((_) {
      // Refresh lessons list when returning from Lesson Builder
      ref.invalidate(lessonsProvider(ref.read(lessonFilterProvider)));
      ref.invalidate(recommendedLessonsProvider);
    });
  }

  Widget _buildErrorState({required VoidCallback onRetry}) {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.textMuted),
            Spacing.gapLG,
            Text(
              'Failed to load lessons',
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
            Spacing.gapLG,
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
