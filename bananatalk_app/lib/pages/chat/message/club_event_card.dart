import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/date_format_locale.dart';
import 'package:bananatalk_app/utils/gathering_time.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// A club gathering's milestone in the club chat ("New meetup", "Confirmed",
/// "Starts in 10 min", "Cancelled", "New time"), posted by the server as a
/// system message. Centered like a date chip, not a bubble from anyone, and
/// one tap from the gathering.
class ClubEventCard extends StatelessWidget {
  const ClubEventCard({super.key, required this.event});

  final GatheringEvent event;

  (IconData, String) _headline(AppLocalizations l10n) => switch (event.kind) {
        'scheduled' => (Icons.event_outlined, l10n.clubEventScheduled),
        'confirmed' => (Icons.check_circle_outline, l10n.gatheringConfirmed(event.going)),
        'starting' => (Icons.alarm, l10n.gatheringStartsIn(10)),
        'cancelled' => (Icons.event_busy_outlined, l10n.gatheringCancelled),
        _ => (Icons.schedule, l10n.clubEventMoved),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, headline) = _headline(l10n);
    final cancelled = event.kind == 'cancelled';
    final startsAt = event.startsAt;
    final accent = cancelled ? context.textSecondary : context.primaryColor;

    return Padding(
      key: Key('club-event-${event.kind}-${event.gatheringId}'),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Material(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/gathering/${event.gatheringId}'),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.dividerColor),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: context.labelSmall.copyWith(color: accent, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.titleSmall.copyWith(
                          decoration: cancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (startsAt != null && !cancelled)
                        Text(
                          '${formatMonthDayForLocale(context, startsAt)} · ${formatLocalClock(startsAt)}',
                          style: context.bodySmall.copyWith(color: context.textSecondary),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  key: Key('club-event-open-${event.gatheringId}'),
                  onPressed: () => context.push('/gathering/${event.gatheringId}'),
                  child: Text(l10n.details),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
