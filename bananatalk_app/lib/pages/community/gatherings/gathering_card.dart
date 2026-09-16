import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/gathering_time.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One gathering in the list.
///
/// The quorum line is the load-bearing element, not decoration. "2 more
/// needed to confirm" turns an RSVP from a gamble into a contribution;
/// "Confirmed · 4 going" makes joining socially cheap. Joining an empty room
/// is expensive, which is what 93 voice rooms with a maximum of one
/// participant actually measured.
class GatheringCard extends StatelessWidget {
  const GatheringCard({
    super.key,
    required this.gathering,
    required this.onTap,
    this.onRsvp,
    this.busy = false,
    this.now,
  });

  final Gathering gathering;
  final VoidCallback onTap;

  /// Null hides the inline button — used where RSVP has its own affordance,
  /// like the detail screen.
  final VoidCallback? onRsvp;

  final bool busy;

  /// Injectable clock, so the card's time line is testable without waiting.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clock = now ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      elevation: 0,
      color: context.containerColor,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLG),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLG,
        child: Padding(
          padding: Spacing.paddingLG,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _whenLine(context, l10n, clock),
              Spacing.gapSM,
              Text(
                gathering.title,
                style: context.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Language and level sit with the title, not with the time: they
              // describe what the gathering IS, and a Wrap means a long label
              // like "Chinese (Traditional)" pushes to its own line instead of
              // overflowing the row.
              if (_tags.isNotEmpty) ...[
                Spacing.gapXS,
                Wrap(
                  spacing: Spacing.xs,
                  runSpacing: Spacing.xs,
                  children: [for (final tag in _tags) _pill(context, tag)],
                ),
              ],
              Spacing.gapXS,
              _hostLine(context, l10n),
              // Host-only, and only when someone is actually waiting. A host
              // who cannot see a pending request from the list will not open
              // the gathering to find it.
              if (gathering.viewerIsHost && gathering.requests.isNotEmpty) ...[
                Spacing.gapSM,
                _requestsBadge(context, l10n),
              ],
              Spacing.gapMD,
              Row(
                children: [
                  Expanded(child: _quorumLine(context, l10n)),
                  if (onRsvp != null) ...[
                    Spacing.hGapSM,
                    _rsvpButton(context, l10n),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Day, then the clock time in the viewer's OWN zone, with the host's zone
  /// beneath it when the two differ.
  Widget _whenLine(
    BuildContext context,
    AppLocalizations l10n,
    DateTime clock,
  ) {
    final underway = isUnderway(
      gathering.startsAt,
      gathering.durationMinutes,
      clock,
    );

    final String headline;
    if (underway) {
      headline = l10n.gatheringHappeningNow;
    } else if (isImminent(gathering.startsAt, clock)) {
      headline = l10n.gatheringStartsIn(minutesUntil(gathering.startsAt, clock));
    } else {
      final day = switch (gatheringDayBucket(gathering.startsAt, clock)) {
        GatheringDayBucket.today => l10n.gatheringToday,
        GatheringDayBucket.tomorrow => l10n.gatheringTomorrow,
        _ => _shortDate(context, gathering.startsAt.toLocal()),
      };
      headline = '$day · ${formatLocalClock(gathering.startsAt)}';
    }

    final zone = hostZoneLabel(gathering.hostTimezone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              underway ? Icons.sensors_rounded : Icons.schedule_rounded,
              size: 16,
              color: underway ? AppColors.error : context.primaryColor,
            ),
            Spacing.hGapXS,
            Flexible(
              child: Text(
                headline,
                style: context.labelLarge.copyWith(
                  color: underway ? AppColors.error : context.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (zone != null) ...[
          Spacing.gapXXS,
          Text(
            l10n.gatheringHostZone(zone),
            style: context.captionSmall.copyWith(color: context.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _hostLine(BuildContext context, AppLocalizations l10n) {
    final name = gathering.host.name.isNotEmpty
        ? gathering.host.name
        : gathering.host.username;
    if (name.isEmpty) return const SizedBox.shrink();
    final place = gathering.hostPlace;
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: context.containerHighColor,
          backgroundImage: gathering.host.avatar.isNotEmpty
              ? NetworkImage(gathering.host.avatar)
              : null,
          child: gathering.host.avatar.isEmpty
              ? Icon(Icons.person, size: 12, color: context.textMuted)
              : null,
        ),
        Spacing.hGapSM,
        Flexible(
          child: Text(
            // The place is appended with a separator rather than through its
            // own l10n key: it is a proper noun either way, and this keeps the
            // line from needing 19 new translations to say "Moscow, Russia".
            place.isEmpty
                ? l10n.gatheringHostedBy(name)
                : '${l10n.gatheringHostedBy(name)} · $place',
            style: context.bodySmall.copyWith(color: context.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Public quorum state. This is the sentence the whole feature turns on.
  Widget _quorumLine(BuildContext context, AppLocalizations l10n) {
    final confirmed = gathering.quorumMet;
    return Row(
      children: [
        Icon(
          confirmed ? Icons.check_circle_rounded : Icons.group_add_rounded,
          size: 16,
          color: confirmed ? AppColors.primary : context.textSecondary,
        ),
        Spacing.hGapXS,
        Flexible(
          child: Text(
            confirmed
                ? l10n.gatheringConfirmed(gathering.going)
                : l10n.gatheringQuorumNeeded(gathering.needed),
            style: context.bodySmall.copyWith(
              color: confirmed ? AppColors.primary : context.textSecondary,
              fontWeight: confirmed ? FontWeight.w600 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _rsvpButton(BuildContext context, AppLocalizations l10n) {
    if (busy) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // The host is already committed — they were auto-RSVP'd on creation and
    // count toward quorum, so offering them a Join button would be a lie.
    if (gathering.viewerIsHost) {
      return _pill(context, l10n.gatheringYouHost);
    }

    if (gathering.viewerIsAttending) {
      return TextButton(
        onPressed: onRsvp,
        child: Text(l10n.gatheringGoingYou),
      );
    }

    if (gathering.isFull) {
      return _pill(context, l10n.gatheringFull);
    }

    return FilledButton(
      onPressed: onRsvp,
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      ),
      child: Text(
        gathering.joinMode == 'approval'
            ? l10n.gatheringAskToJoin
            : l10n.gatheringJoin,
      ),
    );
  }

  /// Language and level, in that order, skipping whichever is absent.
  List<String> get _tags => [
    if (gathering.displayLanguage.isNotEmpty) gathering.displayLanguage,
    if (gathering.level != null && gathering.level!.isNotEmpty) gathering.level!,
  ];

  /// "2 waiting to join" — the host's cue that there is a decision to make.
  /// Uses the primary accent because it is the one thing on this card that
  /// asks the viewer to do something.
  Widget _requestsBadge(BuildContext context, AppLocalizations l10n) {
    return Container(
      key: const Key('gathering-card-requests'),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: AppRadius.borderRound,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.how_to_reg_rounded, size: 14, color: AppColors.primary),
          Spacing.hGapXS,
          Flexible(
            child: Text(
              l10n.gatheringRequests(gathering.requests.length),
              style: context.captionSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.containerHighColor,
        borderRadius: AppRadius.borderRound,
      ),
      child: Text(
        text,
        style: context.captionSmall.copyWith(color: context.textSecondary),
      ),
    );
  }

  /// Locale-aware. A bare "16/9" reads as 16 September to a Russian and as an
  /// invalid month to an American, and this list is shown in 19 locales.
  String _shortDate(BuildContext context, DateTime local) => DateFormat.MMMd(
    Localizations.localeOf(context).toString(),
  ).format(local);
}
