import 'dart:async';

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
import 'package:bananatalk_app/utils/theme_extensions.dart';

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

  /// How long a cold start waits for app-config before giving up on the
  /// flag and showing the legacy page.
  static const configWait = Duration(milliseconds: 1500);
  Timer? _configTimer;

  /// Set once config failed or took longer than [configWait]: this mount
  /// stays on the legacy page so it never swaps under the user.
  bool _legacyLocked = false;

  @override
  void initState() {
    super.initState();
    _configTimer = Timer(configWait, () {
      if (!mounted || ref.read(appConfigProvider).hasValue) return;
      setState(() => _legacyLocked = true);
    });
  }

  @override
  void dispose() {
    _configTimer?.cancel();
    super.dispose();
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

    final config = ref.watch(appConfigProvider);
    if (_legacyLocked) return const LegacyStudyHub();
    if (config.hasValue) {
      _configTimer?.cancel();
      return (config.value?.studyHubEnabled ?? false)
          ? const StudyHub()
          : const LegacyStudyHub();
    }
    if (config.hasError) {
      _legacyLocked = true;
      _configTimer?.cancel();
      return const LegacyStudyHub();
    }
    // Cold start: a neutral page rather than the legacy hub, which would
    // otherwise flash and then be replaced (losing scroll and refetching).
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
