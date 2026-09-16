import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/gatherings/my_gatherings_screen.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The way into the gatherings this person hosts or joined, on their own
/// profile.
///
/// Sits directly under the completion card and, unlike that card, never hides
/// itself: completion disappears at 100% because it is a task, whereas this is
/// a permanent destination. It was previously only in the drawer, where a host
/// had to already know it existed to find it.
class MyGatheringsEntry extends StatelessWidget {
  const MyGatheringsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const color = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('profile-my-gatherings'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            AppPageRoute(builder: (_) => const MyGatheringsScreen()),
          ),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              // Same gradient-over-tint treatment as the completion card
              // above, so the two read as one stack rather than two designs.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.gatheringsMine,
                        style: context.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.gatheringsMineSubtitle,
                        style: context.captionSmall.copyWith(
                          color: context.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
