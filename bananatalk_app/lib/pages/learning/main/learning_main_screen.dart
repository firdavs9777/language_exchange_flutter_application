import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/learning/main/legacy_study_hub.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub.dart';
import 'package:bananatalk_app/pages/learning/animations/streak_milestone_celebration.dart';
import 'package:bananatalk_app/pages/learning/animations/achievement_unlock_overlay.dart';
import 'package:bananatalk_app/pages/learning/animations/level_up_sequence.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/progress_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/achievements_providers.dart';
import 'package:bananatalk_app/services/study_hub_flag_cache.dart';

/// The AI Study tab. Owns the streak / level-up / achievement celebration
/// listeners and renders [StudyHub] or, while `studyHubEnabled` is off,
/// [LegacyStudyHub] (spec 2026-10-13 §10).
class LearningMain extends ConsumerStatefulWidget {
  const LearningMain({super.key});

  @override
  ConsumerState<LearningMain> createState() => _LearningMainState();
}

class _LearningMainState extends ConsumerState<LearningMain> {
  int? _previousStreak;
  int? _previousLevel;
  // Tracks achievement IDs already shown this session to avoid re-triggering
  // the overlay. There is no server-side mark-seen API, so this is
  // client-side only; unseen achievements will re-fire on the next cold start.
  final Set<String> _seenAchievementIds = {};

  /// Which page this mount shows, decided once in [initState] and never
  /// changed, so the page cannot swap under the user (see
  /// [StudyHubFlagCache]).
  late final bool _showHub;

  @override
  void initState() {
    super.initState();
    final config = ref.read(appConfigProvider);
    _showHub = config.hasValue
        ? (config.value?.studyHubEnabled ?? false)
        : (StudyHubFlagCache.lastKnown ?? false);
    // Remember the server's answer for the next launch -- including a value
    // that was already loaded before this page mounted (e.g. after re-login).
    ref.listenManual(appConfigProvider, (previous, next) {
      final value = next.valueOrNull;
      if (value != null) StudyHubFlagCache.remember(value.studyHubEnabled);
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {

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

    return _showHub ? const StudyHub() : const LegacyStudyHub();
  }
}
