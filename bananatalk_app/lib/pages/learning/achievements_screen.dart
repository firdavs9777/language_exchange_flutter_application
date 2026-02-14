import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/widgets/learning/achievement_card.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Achievements gallery screen
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        title: Text(
          'Achievements',
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
            Tab(text: 'All'),
            Tab(text: 'Unlocked'),
            Tab(text: 'Locked'),
          ],
        ),
      ),
      body: achievementsAsync.when(
        data: (achievements) {
          final unlocked =
              achievements.where((a) => a.isUnlocked).toList();
          final locked =
              achievements.where((a) => !a.isUnlocked).toList();

          return Column(
            children: [
              // Stats header
              Container(
                color: context.surfaceColor,
                padding: Spacing.paddingXL,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Unlocked',
                      '${unlocked.length}',
                      AppColors.primary,
                      Icons.emoji_events_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: context.dividerColor,
                    ),
                    _buildStatItem(
                      'Total',
                      '${achievements.length}',
                      context.textSecondary,
                      Icons.stars_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: context.dividerColor,
                    ),
                    _buildStatItem(
                      'Progress',
                      achievements.isNotEmpty
                          ? '${(unlocked.length / achievements.length * 100).round()}%'
                          : '0%',
                      AppColors.accent,
                      Icons.trending_up_rounded,
                    ),
                  ],
                ),
              ),
              // Achievement lists
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // All achievements
                    _buildAchievementList(achievements),
                    // Unlocked achievements
                    _buildAchievementList(unlocked, emptyMessage: 'No achievements unlocked yet'),
                    // Locked achievements
                    _buildAchievementList(locked, emptyMessage: 'You\'ve unlocked all achievements!'),
                  ],
                ),
              ),
            ],
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
              Text('Failed to load achievements',
                  style: context.bodyMedium.copyWith(color: context.textSecondary)),
              Spacing.gapLG,
              ElevatedButton(
                onPressed: () => ref.invalidate(achievementsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        Spacing.gapSM,
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: context.caption,
        ),
      ],
    );
  }

  Widget _buildAchievementList(
    List achievements, {
    String? emptyMessage,
  }) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: context.textMuted,
            ),
            Spacing.gapLG,
            Text(
              emptyMessage ?? 'No achievements',
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    // Group achievements by category
    final Map<String, List> grouped = {};
    for (var achievement in achievements) {
      final category = achievement.category ?? 'Other';
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(achievement);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(achievementsProvider);
      },
      child: ListView.builder(
        padding: Spacing.paddingLG,
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final category = grouped.keys.elementAt(index);
          final categoryAchievements = grouped[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) Spacing.gapXXL,
              // Category header
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                    size: 20,
                  ),
                  Spacing.hGapSM,
                  Text(
                    _formatCategory(category),
                    style: context.titleMedium,
                  ),
                  Spacing.hGapSM,
                  Text(
                    '(${categoryAchievements.where((a) => a.isUnlocked).length}/${categoryAchievements.length})',
                    style: context.bodySmall,
                  ),
                ],
              ),
              Spacing.gapMD,
              // Achievement cards
              ...categoryAchievements.map((achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AchievementCard(
                      achievement: achievement,
                      onTap: () => _showAchievementDetail(achievement),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _showAchievementDetail(dynamic achievement) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Container(
        padding: Spacing.paddingXXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? _getCategoryColor(achievement.category ?? 'other')
                        .withOpacity(0.1)
                    : ctx.containerColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: achievement.iconUrl != null
                    ? Image.network(
                        achievement.iconUrl!,
                        width: 48,
                        height: 48,
                        errorBuilder: (_, __, ___) => Icon(
                          _getCategoryIcon(achievement.category ?? 'other'),
                          size: 40,
                          color: achievement.isUnlocked
                              ? _getCategoryColor(achievement.category ?? 'other')
                              : ctx.textMuted,
                        ),
                      )
                    : Icon(
                        _getCategoryIcon(achievement.category ?? 'other'),
                        size: 40,
                        color: achievement.isUnlocked
                            ? _getCategoryColor(achievement.category ?? 'other')
                            : ctx.textMuted,
                      ),
              ),
            ),
            Spacing.gapLG,
            Text(
              achievement.title,
              style: ctx.displaySmall,
            ),
            Spacing.gapSM,
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: ctx.bodySmall,
            ),
            Spacing.gapLG,
            if (!achievement.isUnlocked && achievement.progress != null) ...[
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadius.borderSM,
                      child: LinearProgressIndicator(
                        value: achievement.progress!.currentValue /
                            achievement.progress!.targetValue,
                        backgroundColor: ctx.containerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(achievement.category ?? 'other'),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  Spacing.hGapMD,
                  Text(
                    '${achievement.progress!.currentValue}/${achievement.progress!.targetValue}',
                    style: ctx.labelLarge.copyWith(color: ctx.textSecondary),
                  ),
                ],
              ),
              Spacing.gapLG,
            ],
            // XP reward
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: AppRadius.borderXL,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  Spacing.hGapSM,
                  Text(
                    '+${achievement.xpReward} XP',
                    style: ctx.labelLarge.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              Spacing.gapMD,
              Text(
                'Unlocked on ${_formatDate(achievement.unlockedAt!)}',
                style: ctx.caption,
              ),
            ],
            Spacing.gapXXL,
          ],
        ),
      ),
    );
  }

  String _formatCategory(String category) {
    switch (category.toLowerCase()) {
      case 'vocabulary':
        return 'Vocabulary';
      case 'lessons':
        return 'Lessons';
      case 'streak':
        return 'Streak';
      case 'social':
        return 'Social';
      case 'messaging':
        return 'Messaging';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vocabulary':
        return Icons.text_fields_rounded;
      case 'lessons':
        return Icons.school_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'messaging':
        return Icons.chat_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vocabulary':
        return const Color(0xFF2196F3);
      case 'lessons':
        return const Color(0xFF9C27B0);
      case 'streak':
        return const Color(0xFFFF9800);
      case 'social':
        return const Color(0xFF4CAF50);
      case 'messaging':
        return const Color(0xFF00BFA5);
      default:
        return const Color(0xFF607D8B);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
