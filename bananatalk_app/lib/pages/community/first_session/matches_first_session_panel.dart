import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/guides/guide_card.dart';

/// The first-session nudge on the Matches tab.
///
/// Deliberately a list header, not an overlay: the growth spec argues against
/// adding friction at the moment someone is deciding whether to stay, and an
/// overlay is the largest way to build the thing it argues against. It points
/// at one action instead of narrating the screen.
///
/// No dismiss control — a dismiss invites dismissal instead of acting, and
/// `kMaxGuidanceViews` already bounds how often this appears.
///
/// Carries no CTA of its own: the button it is talking about is Say hi on the
/// card directly below, which `MatchCard.highlightSayHi` rings while this is
/// on screen. A second button here would compete with the one it points at.
///
/// Renders through [GuideCard] so it cannot drift from the four generic page
/// guides visually, while keeping its own prefs keys and its own funnel
/// events — those are reported against the registration funnel and must not
/// be merged into `guide_shown`.
class MatchesFirstSessionPanel extends StatelessWidget {
  const MatchesFirstSessionPanel({super.key, required this.matchCount});

  final int matchCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GuideCard(
      icon: Icons.waving_hand_rounded,
      accent: AppColors.primary,
      title: l10n.firstSessionMatchesTitle(matchCount),
      body: l10n.firstSessionMatchesBody,
    );
  }
}
