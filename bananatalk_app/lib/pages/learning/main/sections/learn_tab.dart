import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/widgets/learning/daily_goal_widget.dart';
import 'package:bananatalk_app/widgets/learning/challenge_card.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_screen.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_review_screen.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/srs_dashboard_screen.dart';
import 'package:bananatalk_app/pages/learning/lessons/lessons_screen.dart';
import 'package:bananatalk_app/pages/learning/achievements/achievements_screen.dart';
import 'package:bananatalk_app/pages/learning/challenges/challenges_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/learning/main/sections/weekly_digest_card.dart';
import 'package:bananatalk_app/pages/learning/main/sections/progress_hero.dart';
import 'package:bananatalk_app/pages/learning/main/sections/daily_practice_card.dart';

/// The "Learn" tab inside the Study Hub.
class LearnTab extends ConsumerWidget {
  final VoidCallback onSwitchToAI;

  const LearnTab({super.key, required this.onSwitchToAI});

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
                const ProgressHero(),
                const SizedBox(height: 16),

                // ── Snapshot zone: stats + daily goals, grouped under hero ──
                _buildQuickStats(context, progress, isDark),
                const SizedBox(height: 20),
                DailyGoalWidget(progress: progress),
                const SizedBox(height: 24),

                // ── Today zone: weekly digest + AI daily practice ──
                const WeeklyDigestCard(),
                const DailyPracticeCard(),
                const SizedBox(height: 8),
                const BannerAdWidget(),
                const SizedBox(height: 20),

                // Quick Actions — prominent, 2-column
                _buildSectionHeader(context, AppLocalizations.of(context)!.quickActions),
                const SizedBox(height: 12),
                _buildQuickActions(context, vocabStatsAsync, isDark),
                const SizedBox(height: 28),

                // AI Quick Access
                _buildAIBanner(context, onSwitchToAI, isDark),
                const SizedBox(height: 28),

                // Native ad between sections
                const NativeAdWidget(),
                const SizedBox(height: 28),

                // Daily Challenges
                _buildSectionHeader(
                  context,
                  AppLocalizations.of(context)!.dailyChallenges,
                  accent: const Color(0xFFF59E0B),
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
                _buildSectionHeader(
                  context,
                  AppLocalizations.of(context)!.continueLearning,
                  accent: const Color(0xFF00BFA5),
                ),
                const SizedBox(height: 12),
                _buildLearningSections(context, isDark),
                const SizedBox(height: 28),

                // Native ad after the last section
                const NativeAdWidget(),
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
    Color accent = const Color(0xFF667EEA),
  }) {
    return Row(
      children: [
        // Accent bar — consistent, "designed" section headers across tabs.
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (onSeeAll != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              AppLocalizations.of(context)!.seeAll,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
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
          icon: Icons.auto_stories,
          title: AppLocalizations.of(context)!.learningSrsDashboardTitle,
          subtitle: AppLocalizations.of(context)!.learningSrsStartReview,
          color: const Color(0xFFFF6B6B),
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(builder: (_) => const SrsDashboardScreen()),
          ),
        ),
        const SizedBox(height: 10),
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

// ========== LearnTab private sub-widgets ==========

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
