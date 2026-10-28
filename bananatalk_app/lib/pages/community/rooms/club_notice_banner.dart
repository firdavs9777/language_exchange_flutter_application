import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Clubs v2: the organizers' notice (공지), atop the club chat and on the club
/// page. Renders nothing when there is no notice.
class ClubNoticeBanner extends StatelessWidget {
  const ClubNoticeBanner({super.key, required this.notice});

  final String notice;

  @override
  Widget build(BuildContext context) {
    if (notice.trim().isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('club-notice-banner'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, 0),
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMD,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_rounded, size: 18, color: context.primaryColor),
          Spacing.hGapSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.clubNoticeTitle,
                    style: context.captionSmall.copyWith(fontWeight: FontWeight.w700)),
                Text(notice, style: context.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
