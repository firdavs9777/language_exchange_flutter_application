import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
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
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

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
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.studyHub,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocalizations.of(context)!.dailyLearningJourney,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildHeaderActions(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF667EEA),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorPadding: const EdgeInsets.only(bottom: 0),
                  labelColor: isDark ? Colors.white : const Color(0xFF667EEA),
                  unselectedLabelColor: context.textSecondary,
                  labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  dividerHeight: 0,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(AppLocalizations.of(context)!.learnTab),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(AppLocalizations.of(context)!.aiTools),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _LearnTab(onSwitchToAI: () => _tabController.animateTo(1)),
            const _AIToolsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Row(
      children: [
        _HeaderIconButton(
          icon: Icons.leaderboard_rounded,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(builder: (_) => const LeaderboardScreen()),
          ),
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.emoji_events_rounded,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(builder: (_) => const AchievementsScreen()),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
    final isDark = context.isDarkMode;

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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Hero Card
                _buildProgressHero(context, progress, isDark),
                const SizedBox(height: 16),

                // Ad Banner
                const BannerAdWidget(),
                const SizedBox(height: 16),

                // Quick Stats
                _buildQuickStats(context, progress, isDark),
                const SizedBox(height: 24),

                // Daily Goals
                DailyGoalWidget(progress: progress),
                const SizedBox(height: 28),

                // Quick Actions — prominent, 2-column
                _buildSectionHeader(context, AppLocalizations.of(context)!.quickActions),
                const SizedBox(height: 12),
                _buildQuickActions(context, vocabStatsAsync, isDark),
                const SizedBox(height: 28),

                // AI Quick Access
                _buildAIBanner(context, onSwitchToAI, isDark),
                const SizedBox(height: 28),

                // Daily Challenges
                _buildSectionHeader(
                  context,
                  AppLocalizations.of(context)!.dailyChallenges,
                  onSeeAll: () => Navigator.push(
                    context,
                    AppPageRoute(builder: (_) => const ChallengesScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                challengesAsync.when(
                  data: (challenges) {
                    final daily = challenges
                        .where((c) => c.type.toLowerCase() == 'daily')
                        .toList();
                    if (daily.isEmpty) return _buildNoChallenges(context, isDark);
                    return Column(
                      children: daily
                          .take(2)
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ChallengeCompactCard(
                                  challenge: c,
                                  onTap: () => Navigator.push(
                                    context,
                                    AppPageRoute(
                                      builder: (_) => const ChallengesScreen(),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 28),

                // Continue Learning
                _buildSectionHeader(context, AppLocalizations.of(context)!.continueLearning),
                const SizedBox(height: 12),
                _buildLearningSections(context, isDark),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF667EEA)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 56, color: context.textMuted),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.failedToLoadLearningData,
                style: context.bodyMedium.copyWith(color: context.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(learningProgressProvider),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.rocket_launch_rounded, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.startYourJourney,
              style: context.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.startJourneyDescription,
              style: context.bodySmall.copyWith(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  AppPageRoute(builder: (_) => const LessonsScreen()),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.startLearning,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHero(BuildContext context, progress, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D2B55), const Color(0xFF1B1B3A)]
              : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF2D2B55) : const Color(0xFF667EEA))
                .withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${progress.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.levelN(progress.level),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.xpEarned(progress.totalXP),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              StreakWidget(
                currentStreak: progress.currentStreak,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // XP Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.nextLevel(progress.level + 1),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.xpToGo(progress.levelInfo.xpNeeded),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.levelInfo.progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, progress, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.local_fire_department_rounded,
            value: '${progress.currentStreak}',
            label: AppLocalizations.of(context)!.streak,
            color: const Color(0xFFFF6B6B),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.menu_book_rounded,
            value: '${progress.stats.lessonsCompleted}',
            label: AppLocalizations.of(context)!.lessons,
            color: const Color(0xFF667EEA),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.abc_rounded,
            value: '${progress.stats.vocabularyLearned}',
            label: AppLocalizations.of(context)!.words,
            color: const Color(0xFF00BFA5),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              AppLocalizations.of(context)!.seeAll,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667EEA),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AsyncValue vocabStatsAsync, bool isDark) {
    final dueCount = vocabStatsAsync.valueOrNull?.dueToday ?? 0;

    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.replay_circle_filled_rounded,
            title: AppLocalizations.of(context)!.review,
            subtitle: dueCount > 0
                ? AppLocalizations.of(context)!.wordsDue(dueCount)
                : AppLocalizations.of(context)!.allCaughtUp,
            gradient: const [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
            iconColor: const Color(0xFFFF6B6B),
            badge: dueCount > 0 ? dueCount : null,
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              AppPageRoute(builder: (_) => const VocabularyReviewScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.library_add_rounded,
            title: AppLocalizations.of(context)!.addWords,
            subtitle: AppLocalizations.of(context)!.buildVocabulary,
            gradient: const [Color(0xFFA1C4FD), Color(0xFFC2E9FB)],
            iconColor: const Color(0xFF667EEA),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              AppPageRoute(builder: (_) => const VocabularyScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIBanner(BuildContext context, VoidCallback onSwitchToAI, bool isDark) {
    return GestureDetector(
      onTap: onSwitchToAI,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.practiceWithAI,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.aiPracticeDescription,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChallenges(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 14),
          Text(
            AppLocalizations.of(context)!.allChallengesCompleted,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningSections(BuildContext context, bool isDark) {
    return Column(
      children: [
        _LearningNavCard(
          icon: Icons.school_rounded,
          title: AppLocalizations.of(context)!.lessons,
          subtitle: AppLocalizations.of(context)!.structuredLearningPath,
          color: const Color(0xFF667EEA),
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(builder: (_) => const LessonsScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _LearningNavCard(
          icon: Icons.translate_rounded,
          title: AppLocalizations.of(context)!.vocabulary,
          subtitle: AppLocalizations.of(context)!.yourWordCollection,
          color: const Color(0xFF00BFA5),
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(builder: (_) => const VocabularyScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _LearningNavCard(
          icon: Icons.emoji_events_rounded,
          title: AppLocalizations.of(context)!.achievements,
          subtitle: AppLocalizations.of(context)!.badgesAndMilestones,
          color: const Color(0xFFF59E0B),
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(builder: (_) => const AchievementsScreen()),
          ),
        ),
      ],
    );
  }
}

// ========== Reusable sub-widgets ==========

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color iconColor;
  final int? badge;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.iconColor,
    this.badge,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? context.cardBackground : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: isDark ? 0.1 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    if (badge != null && badge! > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Text(
                            badge! > 99 ? '99+' : '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _LearningNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? context.cardBackground : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
            ),
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
    final isDark = context.isDarkMode;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(weakAreasProvider);
        ref.invalidate(aiQuizStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Chat Hero Card
            _buildAIChatHero(context, isVip, isDark),
            const SizedBox(height: 24),

            // AI Features Grid
            _buildSectionHeader(context, AppLocalizations.of(context)!.aiFeatures),
            const SizedBox(height: 12),
            _buildFeaturesGrid(context, isVip, isDark),
            const SizedBox(height: 24),

            // Quick Stats
            quizStatsAsync.when(
              data: (stats) {
                if (stats == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, AppLocalizations.of(context)!.yourAIProgress),
                    const SizedBox(height: 12),
                    _buildStatsRow(context, stats, isDark),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Weak Areas
            weakAreasAsync.when(
              data: (areas) {
                if (areas.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, AppLocalizations.of(context)!.focusAreas),
                    const SizedBox(height: 12),
                    _buildWeakAreas(context, areas, isDark),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: context.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildAIChatHero(BuildContext context, bool isVip, bool isDark) {
    final heroContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 20,
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.aiConversationPartner,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
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
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.practiceWithAITutor,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
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
              onPressed: () => Navigator.push(
                context,
                AppPageRoute(builder: (_) => const AIConversationScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.startConversation,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );

    return VipLockedFeature(
      isVip: isVip,
      featureName: AppLocalizations.of(context)!.aiConversationPartner,
      description: 'Practice speaking with an AI language tutor. Get instant feedback and improve your fluency!',
      borderRadius: BorderRadius.circular(22),
      child: heroContent,
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, bool isVip, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final features = [
      _AIFeature(Icons.menu_book_rounded, l10n.aiLessons, l10n.learnWithAI, const Color(0xFF8B5CF6), true,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const LessonsScreen()))),
      _AIFeature(Icons.spellcheck_rounded, l10n.grammar, l10n.checkWriting, const Color(0xFF10B981), false,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const GrammarFeedbackScreen()))),
      _AIFeature(Icons.mic_rounded, l10n.pronunciation, l10n.improveSpeaking, const Color(0xFFF59E0B), true,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const PronunciationScreen()))),
      _AIFeature(Icons.translate_rounded, l10n.translation, l10n.smartTranslate, const Color(0xFF3B82F6), false,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const TranslationScreen()))),
      _AIFeature(Icons.quiz_rounded, l10n.aiQuizzes, l10n.testKnowledge, const Color(0xFFEF4444), true,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const AIQuizScreen()))),
      _AIFeature(Icons.auto_awesome_rounded, l10n.lessonBuilder, l10n.customLessons, const Color(0xFFEC4899), true,
          () => Navigator.push(context, AppPageRoute(builder: (_) => const LessonBuilderScreen()))),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: features.map((f) {
        final card = GestureDetector(
          onTap: f.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? context.cardBackground : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: f.color.withValues(alpha: isDark ? 0.1 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: f.color.withValues(alpha: isDark ? 0.15 : 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: f.color.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(f.icon, color: f.color, size: 24),
                    ),
                    if (f.vipOnly && !isVip)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text('VIP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  f.title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  f.subtitle,
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ],
            ),
          ),
        );

        if (f.vipOnly && !isVip) {
          return VipLockedFeature(
            isVip: isVip,
            featureName: f.title,
            description: 'Upgrade to VIP to unlock ${f.title}!',
            borderRadius: BorderRadius.circular(18),
            showLabel: false,
            child: card,
          );
        }
        return card;
      }).toList(),
    );
  }

  Widget _buildStatsRow(BuildContext context, stats, bool isDark) {
    return Row(
      children: [
        Expanded(child: _MiniStatCard('${stats.completedQuizzes}', AppLocalizations.of(context)!.quizzes, const Color(0xFF6366F1), isDark)),
        const SizedBox(width: 10),
        Expanded(child: _MiniStatCard('${stats.averageScore.toStringAsFixed(0)}%', AppLocalizations.of(context)!.avgScore, const Color(0xFF10B981), isDark)),
        const SizedBox(width: 10),
        Expanded(child: _MiniStatCard('${stats.currentStreak}', AppLocalizations.of(context)!.streak, const Color(0xFFF59E0B), isDark)),
      ],
    );
  }

  Widget _buildWeakAreas(BuildContext context, List areas, bool isDark) {
    return Column(
      children: areas.take(3).map((area) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? context.cardBackground : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.gps_fixed_rounded, color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.name,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimary),
                    ),
                    Text(
                      AppLocalizations.of(context)!.accuracyPercent((area.accuracy * 100).toStringAsFixed(0)),
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.push(
                  context,
                  AppPageRoute(builder: (_) => const AIQuizScreen()),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: Text(AppLocalizations.of(context)!.practice),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AIFeature {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool vipOnly;
  final VoidCallback onTap;

  const _AIFeature(this.icon, this.title, this.subtitle, this.color, this.vipOnly, this.onTap);
}

class _MiniStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _MiniStatCard(this.value, this.label, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? context.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.15 : 0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
