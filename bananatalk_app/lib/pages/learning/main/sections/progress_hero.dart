import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/pages/learning/models/weekly_digest.dart';
import 'package:bananatalk_app/pages/learning/streak/streak_freeze_dialog.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/widgets/learning/streak_widget.dart';

/// Composite progress hero card: level ring + 7-day XP bar chart + streak.
class ProgressHero extends ConsumerWidget {
  const ProgressHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressAsync = ref.watch(learningProgressProvider);
    final digestAsync = ref.watch(weeklyDigestProvider);

    return progressAsync.when(
      data: (progress) {
        if (progress == null) return const SizedBox.shrink();
        return _ProgressHeroCard(
          progress: progress,
          digestAsync: digestAsync,
          isDark: isDark,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProgressHeroCard extends StatelessWidget {
  final LearningProgress progress;
  final AsyncValue<WeeklyDigest> digestAsync;
  final bool isDark;

  const _ProgressHeroCard({
    required this.progress,
    required this.digestAsync,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LevelRing(progress: progress),
              const SizedBox(width: 16),
              Expanded(child: _HeroStats(progress: progress)),
              _StreakSection(progress: progress),
            ],
          ),
          const SizedBox(height: 16),
          _XpProgressBar(progress: progress),
          const SizedBox(height: 16),
          _WeeklyChart(progress: progress, digestAsync: digestAsync),
        ],
      ),
    );
  }
}

// ── Level ring ───────────────────────────────────────────────────────────────

class _LevelRing extends StatelessWidget {
  final LearningProgress progress;
  const _LevelRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fill = progress.levelInfo.progress.clamp(0.0, 1.0);

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CircularProgressIndicator(
              value: fill,
              strokeWidth: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.learningProgressLevelLabel,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
              Text(
                '${progress.level}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Hero stats (XP + xp-to-next) ─────────────────────────────────────────────

class _HeroStats extends StatelessWidget {
  final LearningProgress progress;
  const _HeroStats({required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final xpNeeded = progress.levelInfo.xpNeeded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on_rounded, color: Color(0xFFFFD700), size: 20),
            const SizedBox(width: 4),
            Text(
              '${progress.totalXP} XP',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        if (xpNeeded > 0) ...[
          const SizedBox(height: 2),
          Text(
            l10n.learningProgressXpToNextLevel(xpNeeded),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Streak section (compact) ──────────────────────────────────────────────────

class _StreakSection extends StatelessWidget {
  final LearningProgress progress;
  const _StreakSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreakWidget(
          currentStreak: progress.currentStreak,
          compact: true,
        ),
        if (progress.streakFreezes > 0) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => const StreakFreezeDialog(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.lightBlue.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ac_unit_rounded, size: 14, color: Colors.lightBlue),
                  const SizedBox(width: 4),
                  Text(
                    '${progress.streakFreezes}',
                    style: const TextStyle(
                      color: Colors.lightBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── XP progress bar (level current → next) ───────────────────────────────────

class _XpProgressBar extends StatelessWidget {
  final LearningProgress progress;
  const _XpProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fill = progress.levelInfo.progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.nextLevel(progress.level + 1),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              l10n.xpToGo(progress.levelInfo.xpNeeded),
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
            value: fill,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ── 7-day XP bar chart ────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  final LearningProgress progress;
  final AsyncValue<WeeklyDigest> digestAsync;

  const _WeeklyChart({required this.progress, required this.digestAsync});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    // Build date objects for the last 7 days (Mon..today or 6 days ago..today)
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    // Today's XP is available directly on the model
    final todayXp = progress.dailyXP;

    // Weekly XP (this week) from the digest if available, fallback to model
    final weeklyXp = digestAsync.maybeWhen(
      data: (d) => d.xpEarned,
      orElse: () => progress.weeklyXP,
    );

    // Distribute remaining XP evenly across the other 6 days as a placeholder
    final restXp = (weeklyXp - todayXp).clamp(0, weeklyXp);
    final perDay = restXp > 0 ? restXp ~/ 6 : 0;

    final dayValues = List.generate(7, (i) {
      final d = days[i];
      final isToday =
          d.day == now.day && d.month == now.month && d.year == now.year;
      return isToday ? todayXp : perDay;
    });

    var maxXp = dayValues.fold(0, (a, b) => a > b ? a : b);
    if (maxXp == 0) maxXp = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.learningProgressWeeklyChartTitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final v = dayValues[i];
              final barHeight = (v / maxXp * 50).clamp(2.0, 50.0);
              final isToday = i == 6;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: isToday ? 0.95 : 0.35,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _shortDay(days[i].weekday),
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: isToday ? 1.0 : 0.55,
                          ),
                          fontSize: 10,
                          height: 1.2,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  static String _shortDay(int weekday) {
    const abbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return abbr[(weekday - 1) % 7];
  }
}
