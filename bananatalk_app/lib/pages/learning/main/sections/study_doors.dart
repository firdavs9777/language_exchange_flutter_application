import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_groups.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';
import 'package:bananatalk_app/pages/learning/main/study_more_screen.dart';
import 'package:bananatalk_app/pages/learning/my_words/my_words_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/my_words_providers.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/services/study/study_tracker.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// The hub's three doors (shown when `studyDoorsEnabled` is on): My words and
/// mistakes, Talk, More. They look like the hub's other cards (same radius and
/// padding as the vocab-packs card); each gradient door has its own colours,
/// dark enough for white text at 4.5:1 in either theme.

/// The card shell the gradient doors share.
class _GradientDoor extends StatelessWidget {
  const _GradientDoor({
    required this.cardKey,
    required this.colors,
    required this.emoji,
    required this.onTap,
    required this.child,
  });

  final Key cardKey;
  final List<Color> colors;
  final String emoji;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      key: cardKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(StudyHubMetrics.cardRadius),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(StudyHubMetrics.cardRadius),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // At least 52 square; grows with large text instead of
              // clipping the emoji.
              Container(
                constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(emoji, style: text.headlineSmall),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// "My words and mistakes": the counts of what the learner picked up in chats;
/// with none, the words due for review; with nothing due either, the "will
/// appear here" line, but only while capture (`studyFromChatsEnabled`) is on.
/// Shows only the title while the numbers load or fail.
class MyWordsDoorCard extends ConsumerWidget {
  const MyWordsDoorCard({super.key});

  // Its own (emerald), not the vocab-packs card's sky-to-teal. White text on
  // either stop is above 4.5:1.
  static const _gradient = [Color(0xFF047857), Color(0xFF065F46)];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final words = ref.watch(myWordsProvider).valueOrNull;
    final capturing = ref.watch(studyFromChatsEnabledProvider);
    String? line;
    if (words != null) {
      final w = words.candidateCount;
      final m = words.mistakeCount;
      line = switch ((w > 0, m > 0)) {
        (true, true) => l.myWordsCardBoth(
          l.myWordsCountWords(w),
          l.myWordsCountMistakes(m),
        ),
        (true, false) => l.myWordsCardOne(l.myWordsCountWords(w)),
        (false, true) => l.myWordsCardOne(l.myWordsCountMistakes(m)),
        (false, false) when words.dueWords > 0 => l.myWordsDueCount(
          words.dueWords,
        ),
        (false, false) => capturing ? l.myWordsCardEmpty : null,
      };
    }
    return _GradientDoor(
      cardKey: const Key('study-door-my-words'),
      colors: _gradient,
      emoji: '📝',
      onTap: () => Navigator.push(
        context,
        AppPageRoute(builder: (_) => const MyWordsScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.myWordsTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (line != null) ...[
            const SizedBox(height: 2),
            Text(
              line,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Talk": opens the tutor (persona picker first when none is chosen) through
/// the same path as the tutor tile, with the tile's badge; a text button opens
/// roleplay the same way.
class TalkDoorCard extends ConsumerWidget {
  const TalkDoorCard({super.key, this.navigate});

  /// Test seam, passed on to [openStudyFeature].
  final void Function(BuildContext context, Widget destination)? navigate;

  static const _gradient = [Color(0xFF667EEA), Color(0xFF764BA2)];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final isVip = ref.watch(userProvider).valueOrNull?.isVip ?? false;
    final vipOnly =
        ref.watch(appConfigProvider).valueOrNull?.studyVipOnlyFeatures ??
        const <String>{};
    final quota = ref.watch(tutorQuotaProvider);

    TileBadge? badgeOf(StudyFeature f) => badgeFor(
      f,
      isVip: isVip,
      vipOnly: vipOnly,
      quota: f.quotaKey == null ? null : quota.get(f.quotaKey!),
    );
    final tutorBadge = badgeOf(StudyFeature.tutor);
    final badgeText = switch (tutorBadge?.kind) {
      TileBadgeKind.locked => l.studyBadgeVip,
      TileBadgeKind.exhausted => l.tutorConversationsLeft(0),
      TileBadgeKind.low => l.tutorConversationsLeft(tutorBadge?.count ?? 0),
      _ => null,
    };

    return _GradientDoor(
      cardKey: const Key('study-door-talk'),
      colors: _gradient,
      emoji: '💬',
      onTap: () => openStudyFeature(
        context,
        ref,
        StudyFeature.tutor,
        badge: tutorBadge,
        navigate: navigate,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.studyDoorTalk,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.studyDoorTalkSubtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(height: 4),
            Text(
              badgeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('study-door-roleplay'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => openStudyFeature(
                context,
                ref,
                StudyFeature.roleplay,
                badge: badgeOf(StudyFeature.roleplay),
                navigate: navigate,
              ),
              child: Text(
                l.studyDoorRoleplay,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "More ways to study": opens [StudyMoreScreen], where everything the doors
/// do not show lives.
class MoreDoorRow extends StatelessWidget {
  const MoreDoorRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Material(
      key: const Key('study-door-more'),
      color: dark ? const Color(0xFF1E1E24) : Colors.white,
      borderRadius: BorderRadius.circular(StudyHubMetrics.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(StudyHubMetrics.cardRadius),
        onTap: () {
          studyLog(StudyEvent.featureOpened, kind: 'more');
          Navigator.push(
            context,
            AppPageRoute(builder: (_) => const StudyMoreScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StudyHubMetrics.cardRadius),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.studyDoorMore,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
