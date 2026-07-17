import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/learning/achievements/achievements_screen.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/leaderboard_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/learning/main/sections/learn_tab.dart';
import 'package:bananatalk_app/pages/learning/main/sections/ai_tools_tab.dart';
import 'package:bananatalk_app/pages/learning/animations/streak_milestone_celebration.dart';
import 'package:bananatalk_app/pages/learning/animations/achievement_unlock_overlay.dart';
import 'package:bananatalk_app/pages/learning/animations/level_up_sequence.dart';
import 'package:bananatalk_app/providers/provider_root/learning/progress_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/achievements_providers.dart';
import 'package:bananatalk_app/widgets/vip_up_pill.dart';
import 'package:bananatalk_app/widgets/coins/coin_balance_pill.dart';
import 'package:bananatalk_app/widgets/notifications/notification_bell.dart';
import 'package:bananatalk_app/pages/learning/exam_study/exam_study_tab.dart';

/// Unified Study Hub — composes the Learn tab and AI Tools tab.
class LearningMain extends ConsumerStatefulWidget {
  const LearningMain({super.key});

  @override
  ConsumerState<LearningMain> createState() => _LearningMainState();
}

class _LearningMainState extends ConsumerState<LearningMain>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _previousStreak;
  int? _previousLevel;
  // Tracks achievement IDs already shown this session to avoid re-triggering
  // the overlay. There is no server-side mark-seen API, so this is
  // client-side only; unseen achievements will re-fire on the next cold start.
  final Set<String> _seenAchievementIds = {};

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
    final isDark = context.isDarkMode;

    ref.listen(learningProgressProvider, (previous, next) {
      next.whenData((progress) {
        if (progress == null) return;
        final newStreak = progress.currentStreak;
        if (_previousStreak != null && newStreak > _previousStreak!) {
          StreakMilestoneCelebration.showIfMilestone(
            context,
            newStreak: newStreak,
            previousStreak: _previousStreak!,
          );
        }
        _previousStreak = newStreak;

        // Level-up detection
        final newLevel = progress.level;
        LevelUpSequence.showIfChanged(
          context,
          newLevel: newLevel,
          previousLevel: _previousLevel,
        );
        _previousLevel = newLevel;
      });
    });

    ref.listen(achievementsProvider, (previous, next) {
      next.whenData((achievements) async {
        // Find achievements that are newly unlocked and not yet shown
        final newlyUnlocked = achievements
            .where((a) => a.isUnlocked && !_seenAchievementIds.contains(a.id))
            .toList();

        if (newlyUnlocked.isEmpty) return;

        // Mark all as seen immediately to prevent duplicate triggers
        for (final a in newlyUnlocked) {
          _seenAchievementIds.add(a.id);
        }

        // Show overlays sequentially; guard each iteration with context.mounted
        for (final a in newlyUnlocked) {
          if (!context.mounted) break;
          await AchievementUnlockOverlay.show(
            context,
            name: a.name,
            description: a.description,
          );
        }
        // NOTE: No server-side markAchievementsSeen API exists. Overlays are
        // deduplicated within the session via _seenAchievementIds only.
      });
    });

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
                                style: const TextStyle(
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
                    Tab(text: AppLocalizations.of(context)!.examStudy),
                    Tab(text: AppLocalizations.of(context)!.aiTools),
                    Tab(text: AppLocalizations.of(context)!.learnTab),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            const ExamStudyTab(),
            const AIToolsTab(),
            LearnTab(onSwitchToAI: () => _tabController.animateTo(1)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Row(
      children: [
        // VIP upgrade entry — passes onLight: false because the AI Study
        // header sits on a purple gradient, so the "Up" badge needs a
        // white border to read cleanly.
        const VipUpPill(onLight: false),
        const SizedBox(width: 4),
        const CoinBalancePill(onLight: false),
        const SizedBox(width: 4),
        // Notification inbox — white icon to read on the purple gradient.
        const NotificationBell(color: Colors.white),
        const SizedBox(width: 8),
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
