import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/vip_locked_feature.dart';
import 'package:bananatalk_app/widgets/learning/streak_widget.dart';
import 'package:bananatalk_app/widgets/learning/daily_goal_widget.dart';
import 'package:bananatalk_app/widgets/learning/challenge_card.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_screen.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_review_screen.dart';
import 'package:bananatalk_app/pages/learning/lessons/lessons_screen.dart';
import 'package:bananatalk_app/pages/learning/achievements_screen.dart';
import 'package:bananatalk_app/pages/learning/challenges_screen.dart';
import 'package:bananatalk_app/pages/learning/leaderboard_screen.dart';
import 'package:bananatalk_app/pages/ai/conversation/ai_conversation_screen.dart';
import 'package:bananatalk_app/pages/ai/grammar/grammar_feedback_screen.dart';
import 'package:bananatalk_app/pages/ai/pronunciation/pronunciation_screen.dart';
import 'package:bananatalk_app/pages/ai/translation/translation_screen.dart';
import 'package:bananatalk_app/pages/ai/quiz/ai_quiz_screen.dart';
import 'package:bananatalk_app/pages/ai/lesson_builder/lesson_builder_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Unified Study Hub - Combines Learning and AI Features
class LearningMain extends ConsumerStatefulWidget {
  const LearningMain({super.key});

  @override
  ConsumerState<LearningMain> createState() => _LearningMainState();
}

class _LearningMainState extends ConsumerState<LearningMain>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Study Hub',
          style: context.displaySmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            color: context.iconColor,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded),
            color: context.iconColor,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textSecondary,
          labelStyle: context.titleSmall,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 20,
                    color: _currentTab == 0
                        ? AppColors.primary
                        : context.textSecondary,
                  ),
                  Spacing.hGapSM,
                  const Text('Learn'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy_rounded,
                    size: 20,
                    color: _currentTab == 1
                        ? AppColors.primary
                        : context.textSecondary,
                  ),
                  Spacing.hGapSM,
                  const Text('AI Tools'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LearnTab(onSwitchToAI: () => _tabController.animateTo(1)),
          const _AIToolsTab(),
        ],
      ),
    );
  }
}

/// Learn Tab Content
class _LearnTab extends ConsumerWidget {
  final VoidCallback onSwitchToAI;

  const _LearnTab({required this.onSwitchToAI});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(learningProgressProvider);
    final challengesAsync = ref.watch(challengesProvider);
    final vocabStatsAsync = ref.watch(vocabularyStatsProvider(null));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(learningProgressProvider);
        ref.invalidate(challengesProvider);
        ref.invalidate(vocabularyStatsProvider(null));
      },
      child: progressAsync.when(
        data: (progress) {
          if (progress == null) {
            return _buildEmptyState(context);
          }
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Card
                _buildProgressCard(progress),
                Spacing.gapXL,

                // Quick Stats Row
                _buildQuickStats(progress),
                Spacing.gapXL,

                // Daily Goals
                DailyGoalWidget(progress: progress),
                Spacing.gapXXL,

                // AI Quick Access Card
                _buildAIQuickAccess(context, onSwitchToAI),
                Spacing.gapXXL,

                // Quick Actions
                _buildSectionHeader('Quick Actions'),
                Spacing.gapMD,
                _buildQuickActions(context, vocabStatsAsync),
                Spacing.gapXXL,

                // Daily Challenges
                _buildSectionHeader(
                  'Daily Challenges',
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChallengesScreen(),
                      ),
                    );
                  },
                ),
                Spacing.gapMD,
                challengesAsync.when(
                  data: (challenges) {
                    final dailyChallenges = challenges
                        .where((c) => c.type.toLowerCase() == 'daily')
                        .toList();
                    if (dailyChallenges.isEmpty) {
                      return _buildNoChallenges();
                    }
                    return Column(
                      children: dailyChallenges
                          .take(2)
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ChallengeCompactCard(
                                  challenge: c,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ChallengesScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                Spacing.gapXXL,

                // Continue Learning
                _buildSectionHeader('Continue Learning'),
                Spacing.gapMD,
                _buildLearningSections(context),
                Spacing.gapXXL,
              ],
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
                'Failed to load learning data',
                style: context.bodyMedium.copyWith(color: context.textSecondary),
              ),
              Spacing.gapLG,
              ElevatedButton(
                onPressed: () => ref.invalidate(learningProgressProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_rounded, size: 64, color: context.textMuted),
          Spacing.gapLG,
          Text(
            'Start your learning journey!',
            style: context.titleLarge,
          ),
          Spacing.gapSM,
          Text(
            'Complete lessons and build vocabulary',
            style: context.bodySmall,
          ),
          Spacing.gapXXL,
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LessonsScreen()),
              );
            },
            child: const Text('Start Learning'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(progress) {
    return Container(
      padding: Spacing.paddingXL,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.borderXL,
        boxShadow: AppShadows.colored,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${progress.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacing.gapXS,
                  Text(
                    '${progress.totalXP} XP total',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              StreakWidget(
                currentStreak: progress.currentStreak,
                compact: true,
              ),
            ],
          ),
          Spacing.gapXL,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${progress.level + 1}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${progress.levelInfo.xpNeeded} XP needed',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Spacing.gapSM,
              ClipRRect(
                borderRadius: AppRadius.borderSM,
                child: LinearProgressIndicator(
                  value: progress.levelInfo.progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(progress) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${progress.currentStreak}',
            label: 'Day Streak',
            color: AppColors.warning,
          ),
        ),
        Spacing.hGapMD,
        Expanded(
          child: _buildStatCard(
            icon: Icons.school_rounded,
            value: '${progress.stats.lessonsCompleted}',
            label: 'Lessons',
            color: AppColors.info,
          ),
        ),
        Spacing.hGapMD,
        Expanded(
          child: _buildStatCard(
            icon: Icons.text_fields_rounded,
            value: '${progress.stats.vocabularyLearned}',
            label: 'Words',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Builder(
      builder: (context) => Container(
        padding: Spacing.paddingLG,
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: AppRadius.borderLG,
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            Spacing.gapSM,
            Text(
              value,
              style: context.displaySmall,
            ),
            Spacing.gapXS,
            Text(
              label,
              style: context.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIQuickAccess(BuildContext context, VoidCallback onSwitchToAI) {
    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: AppRadius.borderLG,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppRadius.borderMD,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          Spacing.hGapLG,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice with AI',
                  style: context.titleMedium.copyWith(color: Colors.white),
                ),
                Text(
                  'Chat, quiz, grammar & more',
                  style: context.bodySmall.copyWith(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onSwitchToAI,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderSM,
              ),
            ),
            child: Text('Open', style: context.labelLarge.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: context.titleLarge,
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: context.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AsyncValue vocabStatsAsync) {
    final dueCount = vocabStatsAsync.valueOrNull?.dueToday ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.replay_rounded,
            title: 'Review',
            subtitle: dueCount > 0 ? '$dueCount due' : 'All caught up!',
            color: const Color(0xFFFF9800),
            badge: dueCount > 0 ? dueCount : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VocabularyReviewScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.add_rounded,
            title: 'Add Words',
            subtitle: 'Build vocabulary',
            color: const Color(0xFF00BFA5),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VocabularyScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    int? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderLG,
      child: Container(
        padding: Spacing.paddingLG,
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: AppRadius.borderLG,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: Spacing.paddingXS,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: context.captionSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            Spacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.labelLarge),
                  Text(subtitle, style: context.caption),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChallenges() {
    return Builder(
      builder: (context) => Container(
        padding: Spacing.paddingXL,
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: AppRadius.borderMD,
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
            Spacing.hGapMD,
            Text(
              'All challenges completed!',
              style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningSections(BuildContext context) {
    return Column(
      children: [
        _buildLearningItem(
          context,
          icon: Icons.school_rounded,
          title: 'Lessons',
          subtitle: 'Structured learning path',
          color: AppColors.info,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LessonsScreen()),
            );
          },
        ),
        Spacing.gapMD,
        _buildLearningItem(
          context,
          icon: Icons.text_fields_rounded,
          title: 'Vocabulary',
          subtitle: 'Your word collection',
          color: AppColors.accent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VocabularyScreen()),
            );
          },
        ),
        Spacing.gapMD,
        _buildLearningItem(
          context,
          icon: Icons.emoji_events_rounded,
          title: 'Achievements',
          subtitle: 'Your badges and milestones',
          color: AppColors.warning,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLearningItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMD,
      child: Container(
        padding: Spacing.paddingLG,
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: AppRadius.borderMD,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppRadius.borderMD,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Spacing.hGapLG,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.titleMedium),
                  Text(subtitle, style: context.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textMuted),
          ],
        ),
      ),
    );
  }
}

/// AI Tools Tab Content
class _AIToolsTab extends ConsumerWidget {
  const _AIToolsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weakAreasAsync = ref.watch(weakAreasProvider);
    final quizStatsAsync = ref.watch(aiQuizStatsProvider);
    final userAsync = ref.watch(userProvider);
    final isVip = userAsync.valueOrNull?.isVip ?? false;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(weakAreasProvider);
        ref.invalidate(aiQuizStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Chat Hero Card
            _buildAIChatHero(context, isVip),
            const SizedBox(height: 24),

            // AI Features Grid
            _buildSectionHeader('AI Features'),
            const SizedBox(height: 12),
            _buildFeaturesGrid(context, isVip),
            const SizedBox(height: 24),

            // Quick Stats
            quizStatsAsync.when(
              data: (stats) {
                if (stats == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Your AI Progress'),
                    const SizedBox(height: 12),
                    _buildStatsRow(stats),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Weak Areas Section
            weakAreasAsync.when(
              data: (areas) {
                if (areas.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Focus Areas'),
                    const SizedBox(height: 12),
                    _buildWeakAreas(context, areas),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAIChatHero(BuildContext context, bool isVip) {
    final heroContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: const Text(
                            'AI Conversation Partner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isVip) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Practice speaking with your AI tutor',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIConversationScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Conversation',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    return VipLockedFeature(
      isVip: isVip,
      featureName: 'AI Conversation Partner',
      description: 'Practice speaking with an AI language tutor. Get instant feedback and improve your fluency!',
      borderRadius: BorderRadius.circular(20),
      child: heroContent,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, bool isVip) {
    final features = [
      {
        'icon': Icons.menu_book_rounded,
        'title': 'AI Lessons',
        'subtitle': 'Learn with AI help',
        'color': const Color(0xFF8B5CF6),
        'vipOnly': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LessonsScreen()),
          );
        },
      },
      {
        'icon': Icons.spellcheck_rounded,
        'title': 'Grammar Check',
        'subtitle': 'Analyze your writing',
        'color': const Color(0xFF10B981),
        'vipOnly': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GrammarFeedbackScreen()),
          );
        },
      },
      {
        'icon': Icons.mic_rounded,
        'title': 'Pronunciation',
        'subtitle': 'Improve your speaking',
        'color': const Color(0xFFF59E0B),
        'vipOnly': true,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PronunciationScreen()),
          );
        },
      },
      {
        'icon': Icons.translate_rounded,
        'title': 'Translation',
        'subtitle': 'Smart translations',
        'color': const Color(0xFF3B82F6),
        'vipOnly': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TranslationScreen()),
          );
        },
      },
      {
        'icon': Icons.quiz_rounded,
        'title': 'AI Quizzes',
        'subtitle': 'Test your knowledge',
        'color': const Color(0xFFEF4444),
        'vipOnly': true,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIQuizScreen()),
          );
        },
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'Lesson Builder',
        'subtitle': 'Generate custom lessons',
        'color': const Color(0xFFEC4899),
        'vipOnly': true,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LessonBuilderScreen()),
          );
        },
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: features
          .map((f) => _buildFeatureCard(
                context,
                icon: f['icon'] as IconData,
                title: f['title'] as String,
                subtitle: f['subtitle'] as String,
                color: f['color'] as Color,
                onTap: f['onTap'] as VoidCallback,
                isVip: isVip,
                vipOnly: f['vipOnly'] as bool,
              ))
          .toList(),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isVip,
    required bool vipOnly,
  }) {
    final cardContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                if (vipOnly && !isVip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, size: 10, color: Colors.white),
                        SizedBox(width: 2),
                        Text(
                          'VIP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    // Apply VIP lock only for VIP-only features when user is not VIP
    if (vipOnly && !isVip) {
      return VipLockedFeature(
        isVip: isVip,
        featureName: title,
        description: 'Upgrade to VIP to unlock $title and boost your language learning!',
        borderRadius: BorderRadius.circular(16),
        showLabel: false,
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildStatsRow(stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '${stats.completedQuizzes}',
            'Quizzes Done',
            const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            '${stats.averageScore.toStringAsFixed(0)}%',
            'Avg Score',
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            '${stats.currentStreak}',
            'Day Streak',
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeakAreas(BuildContext context, List areas) {
    return Column(
      children: areas.take(3).map((area) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(area.accuracy * 100).toStringAsFixed(0)}% accuracy',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AIQuizScreen()),
                  );
                },
                child: const Text('Practice'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
