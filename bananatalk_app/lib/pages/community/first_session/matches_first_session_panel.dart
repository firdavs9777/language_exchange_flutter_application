import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The first-session nudge on the Matches tab.
///
/// Deliberately a list header, not an overlay: the growth spec argues against
/// adding friction at the moment someone is deciding whether to stay, and an
/// overlay is the largest way to build the thing it argues against. It points
/// at one action instead of narrating the screen.
///
/// No dismiss control — a dismiss invites dismissal instead of acting, and
/// `kMaxGuidanceViews` already bounds how often this appears.
class MatchesFirstSessionPanel extends StatelessWidget {
  const MatchesFirstSessionPanel({super.key, required this.matchCount});

  final int matchCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.waving_hand_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          // Flexible so a longer localized string wraps instead of overflowing
          // — the same failure the chat app bar hit on 2026-10-09.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.firstSessionMatchesTitle(matchCount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.firstSessionMatchesBody,
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
