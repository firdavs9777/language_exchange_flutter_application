import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_labels.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';

/// One Explore tile (spec §4.2): tinted icon, title, one-line description,
/// at most one badge. The whole tile is the tap target.
class StudyFeatureTile extends StatelessWidget {
  const StudyFeatureTile({
    super.key,
    required this.feature,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  final StudyFeature feature;
  final String description;
  final TileBadge? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final colors = studyGroupColors(feature.group, dark: dark);
    final title = studyFeatureTitle(l, feature);
    final badgeText = badge == null ? null : _badgeLabel(l, badge!);

    return Semantics(
      button: true,
      label: [title, description, if (badgeText != null) badgeText].join(', '),
      excludeSemantics: true,
      child: Material(
        color: dark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(StudyHubMetrics.tileRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(StudyHubMetrics.tileRadius),
          child: Container(
            constraints: const BoxConstraints(minHeight: StudyHubMetrics.tileHeight),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(StudyHubMetrics.tileRadius),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              Container(
                width: StudyHubMetrics.tileIconSize,
                height: StudyHubMetrics.tileIconSize,
                decoration: BoxDecoration(
                    color: colors.fill, borderRadius: BorderRadius.circular(10)),
                child: Icon(studyFeatureIcon(feature), color: colors.fg, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      if (badge != null) _Badge(badge: badge!, text: badgeText!),
                    ]),
                    Text(description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  static String _badgeLabel(AppLocalizations l, TileBadge b) => switch (b.kind) {
        TileBadgeKind.locked => l.studyBadgeVip,
        TileBadgeKind.exhausted => l.studyBadgeLeft(0),
        TileBadgeKind.low => l.studyBadgeLeft(b.count ?? 0),
        TileBadgeKind.due => l.studyBadgeDue(b.count ?? 0),
        TileBadgeKind.isNew => l.studyBadgeNew,
      };
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge, required this.text});
  final TileBadge badge;
  final String text;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (badge.kind) {
      TileBadgeKind.exhausted => (AppColors.error, Colors.white),
      TileBadgeKind.locked => (const Color(0xFF2B2B33), const Color(0xFFFFD54F)),
      TileBadgeKind.isNew => (const Color(0xFF6D3FE0), Colors.white),
      _ => (const Color(0xFFFEF0D9), const Color(0xFF8A4B00)),
    };
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (badge.kind == TileBadgeKind.locked)
          Icon(Icons.lock_rounded, size: 12, color: fg),
        Text(text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
