import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/ai/grammar/grammar_feedback_screen.dart';
import 'package:bananatalk_app/pages/ai/pronunciation/pronunciation_screen.dart';
import 'package:bananatalk_app/pages/ai/quiz/ai_quiz_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/image_vocab_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/persona_picker_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/scenario_picker_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/story_setup_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/tutor_chat_screen.dart';
import 'package:bananatalk_app/pages/learning/challenges/challenges_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/exam_study_screen.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/leaderboard_screen.dart';
import 'package:bananatalk_app/pages/learning/lessons/lessons_screen.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_labels.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_tile.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_review_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/feature_seen_store.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/study/study_upgrade_sheet.dart';

Widget destinationFor(StudyFeature f) => switch (f) {
      StudyFeature.tutor => const TutorChatScreen(),
      StudyFeature.roleplay => const ScenarioPickerScreen(),
      StudyFeature.story => const StorySetupScreen(),
      StudyFeature.photo => const ImageVocabScreen(),
      StudyFeature.speak => const PronunciationScreen(),
      StudyFeature.review => const VocabularyReviewScreen(),
      StudyFeature.writing => const GrammarFeedbackScreen(),
      StudyFeature.quizzes => const AIQuizScreen(),
      StudyFeature.exam => const ExamStudyScreen(),
      StudyFeature.lessons => const LessonsScreen(),
      StudyFeature.challenges => const ChallengesScreen(),
      StudyFeature.leaderboard => const LeaderboardScreen(),
    };

/// The three Explore groups (spec §4). Tap order: badge-gated sheet first,
/// then the persona picker for Talk tiles without a persona, then the
/// destination.
class StudyFeatureGroups extends ConsumerWidget {
  const StudyFeatureGroups({super.key, this.navigate});

  /// Test seam; defaults to pushing an [AppPageRoute].
  final void Function(BuildContext context, Widget destination)? navigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final user = ref.watch(userProvider).valueOrNull;
    final isVip = user?.isVip ?? false;
    final vipOnly = ref.watch(appConfigProvider).valueOrNull?.studyVipOnlyFeatures ?? const <String>{};
    final quota = ref.watch(tutorQuotaProvider);
    final due = ref.watch(vocabularyStatsProvider(null)).valueOrNull?.dueToday ?? 0;
    // Loading: treat everything as seen so badges do not flash in.
    final seen = ref.watch(featureSeenProvider).valueOrNull
        ?? StudyFeature.values.map((f) => f.slug).toSet();
    final fresh = newBadgeFeatures(seen);
    final examLangs = ref.watch(examLanguagesProvider).valueOrNull;
    final target = user?.language_to_learn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in StudyGroup.values) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: StudyHubMetrics.groupLabelGap),
            child: Text(
              studyGroupLabel(l, group).toUpperCase(),
              style: text.labelLarge?.copyWith(
                letterSpacing: 0.9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _Grid(children: [
            for (final f in studyFeatureGroups[group]!)
              Builder(builder: (context) {
                final badge = badgeFor(f,
                    isVip: isVip,
                    vipOnly: vipOnly,
                    quota: f.quotaKey == null ? null : quota.get(f.quotaKey!),
                    dueCount: due,
                    isNew: fresh.contains(f));
                final englishOnly = featureCoverage(f, target, examLanguages: examLangs) ==
                    FeatureCoverage.englishOnly;
                return StudyFeatureTile(
                  feature: f,
                  description: englishOnly ? l.studyEnglishOnly : studyFeatureDescription(l, f),
                  badge: badge,
                  onTap: () => _onTap(context, ref, f, badge),
                );
              }),
          ]),
          const SizedBox(height: StudyHubMetrics.groupGap),
        ],
      ],
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, StudyFeature f, TileBadge? badge) async {
    AnalyticsService.instance.studyTileTap(feature: f.slug, badge: badge?.analyticsName);
    // The tile may be gone when markSeen resolves; `ref` would throw then,
    // so invalidate through the container captured now.
    final container = ProviderScope.containerOf(context, listen: false);
    FeatureSeenStore.markSeen(f.slug).then((_) => container.invalidate(featureSeenProvider));

    if (badge?.kind == TileBadgeKind.locked) {
      await showStudyUpgradeSheet(context, feature: f, reason: StudyUpgradeReason.locked);
      return;
    }
    if (badge?.kind == TileBadgeKind.exhausted) {
      final unlocked = await showStudyUpgradeSheet(context,
          feature: f, reason: StudyUpgradeReason.exhausted);
      if (!unlocked || !context.mounted) return;
    }
    if (!context.mounted) return;
    _open(context, ref, f);
  }

  void _open(BuildContext context, WidgetRef ref, StudyFeature f) {
    final push = navigate ??
        (BuildContext c, Widget w) => Navigator.push(c, AppPageRoute(builder: (_) => w));
    var dest = destinationFor(f);
    // Talk tiles need a persona; the picker forwards to the chosen feature
    // (same rule as the old _TutorModeChips._open).
    if (f.group == StudyGroup.talk &&
        ref.read(tutorMemoryProvider).valueOrNull?.persona == null) {
      dest = PersonaPickerScreen(destinationAfterPick: dest);
    }
    push(context, dest);
  }
}

/// 2-column grid with fixed gaps; rows size to their tallest tile so text
/// scale never clips.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: children[i]),
          const SizedBox(width: StudyHubMetrics.tileGap),
          Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
        ]),
      ));
      if (i + 2 < children.length) rows.add(const SizedBox(height: StudyHubMetrics.tileGap));
    }
    return Column(children: rows);
  }
}
