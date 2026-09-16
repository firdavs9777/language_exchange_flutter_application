import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/widgets/community_error_state.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/utils/gathering_time.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// One gathering, in full.
class GatheringDetailScreen extends StatefulWidget {
  const GatheringDetailScreen({
    super.key,
    required this.gatheringId,
    this.apiClient,
  });

  final String gatheringId;
  final GatheringApiClient? apiClient;

  @override
  State<GatheringDetailScreen> createState() => _GatheringDetailScreenState();
}

class _GatheringDetailScreenState extends State<GatheringDetailScreen> {
  late final GatheringApiClient _api = widget.apiClient ?? GatheringApiClient();
  late Future<Gathering?> _future;
  bool _busy = false;

  /// Whether the most recent RSVP landed as a pending request rather than a
  /// seat. Held on the State so the message can be shown after the write
  /// completes, with a `mounted` check the analyzer can actually see.
  bool _lastRsvpWasPending = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getGathering(widget.gatheringId);
  }

  Future<void> _reload() async {
    final next = _api.getGathering(widget.gatheringId);
    setState(() => _future = next);
    await next;
  }

  /// Runs a write, shows whatever the server said if it refused, and reloads.
  /// The refusals here are specific and worth surfacing verbatim — "this
  /// gathering is full", "a gathering cannot end before it starts".
  Future<void> _run(Future<String?> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      showCommunitySnackBar(
        context,
        message: error,
        type: CommunitySnackBarType.error,
      );
      return;
    }
    if (success != null) {
      showCommunitySnackBar(
        context,
        message: success,
        type: CommunitySnackBarType.success,
      );
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gatheringDetailTitle)),
      body: FutureBuilder<Gathering?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final gathering = snapshot.data;
          if (gathering == null) {
            return CommunityErrorState(
              message: l10n.gatheringNotFound,
              onRetry: _reload,
            );
          }
          return _body(context, l10n, gathering);
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    Gathering gathering,
  ) {
    final now = DateTime.now();
    final zone = hostZoneLabel(gathering.hostTimezone);

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Spacing.paddingLG,
        children: [
          Text(gathering.title, style: context.displaySmall),
          Spacing.gapMD,
          _statusBanner(context, l10n, gathering, now),
          Spacing.gapLG,

          // The time, in the viewer's own zone, with the host's zone beneath.
          _row(
            context,
            Icons.event_rounded,
            '${_longDate(gathering.startsAt.toLocal())} · '
            '${formatLocalClock(gathering.startsAt)}',
            subtitle: zone == null ? null : l10n.gatheringHostZone(zone),
          ),
          _row(
            context,
            Icons.timer_outlined,
            l10n.gatheringDuration(gathering.durationMinutes),
          ),
          if (gathering.displayLanguage.isNotEmpty)
            _row(
              context,
              Icons.translate_rounded,
              gathering.level == null || gathering.level!.isEmpty
                  ? gathering.displayLanguage
                  : '${gathering.displayLanguage} · ${gathering.level}',
            ),
          _row(
            context,
            Icons.people_rounded,
            l10n.gatheringSeatsTaken(gathering.going, gathering.capacity),
          ),
          if (gathering.host.name.isNotEmpty)
            _row(
              context,
              Icons.person_rounded,
              l10n.gatheringHostedBy(gathering.host.name),
            ),

          if (gathering.description.isNotEmpty) ...[
            Spacing.gapLG,
            Text(gathering.description, style: context.bodyMedium),
          ],

          Spacing.gapXXL,
          ..._actions(context, l10n, gathering, now),
        ],
      ),
    );
  }

  /// Quorum, said out loud. Before it is met the card asks for help; after, it
  /// tells the viewer it is safe to come.
  Widget _statusBanner(
    BuildContext context,
    AppLocalizations l10n,
    Gathering gathering,
    DateTime now,
  ) {
    final (String text, Color color, IconData icon) = switch (gathering.status) {
      GatheringStatus.cancelled => (
        l10n.gatheringCancelled,
        AppColors.error,
        Icons.event_busy_rounded,
      ),
      GatheringStatus.ended => (
        l10n.gatheringEnded,
        context.textSecondary,
        Icons.history_rounded,
      ),
      _ when isUnderway(gathering.startsAt, gathering.durationMinutes, now) => (
        l10n.gatheringHappeningNow,
        AppColors.error,
        Icons.sensors_rounded,
      ),
      _ when gathering.quorumMet => (
        l10n.gatheringConfirmed(gathering.going),
        AppColors.primary,
        Icons.check_circle_rounded,
      ),
      _ => (
        l10n.gatheringQuorumNeeded(gathering.needed),
        context.textSecondary,
        Icons.group_add_rounded,
      ),
    };

    return Container(
      padding: Spacing.paddingMD,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMD,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          Spacing.hGapSM,
          Expanded(
            child: Text(
              text,
              style: context.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    AppLocalizations l10n,
    Gathering gathering,
    DateTime now,
  ) {
    if (gathering.status == GatheringStatus.cancelled ||
        gathering.status == GatheringStatus.ended) {
      return const [];
    }

    if (gathering.viewerIsHost) {
      return [
        // The T-2h question, asked once and answered out loud. A gathering is
        // never auto-cancelled: a host who abandons their own gathering is
        // the worst outcome here, so the decision is theirs and explicit.
        if (!gathering.quorumMet && minutesUntil(gathering.startsAt, now) <= 120)
          Container(
            margin: const EdgeInsets.only(bottom: Spacing.lg),
            padding: Spacing.paddingMD,
            decoration: BoxDecoration(
              color: context.containerHighColor,
              borderRadius: AppRadius.borderMD,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.gatheringHostDecision(gathering.going),
                  style: context.bodyMedium,
                ),
                Spacing.gapSM,
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () async => (await _api.hostDecision(
                                  gathering.id,
                                  runAnyway: true,
                                )).error,
                              ),
                        child: Text(l10n.gatheringRunAnyway),
                      ),
                    ),
                    Spacing.hGapSM,
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () async => (await _api.hostDecision(
                                  gathering.id,
                                  runAnyway: false,
                                )).error,
                              ),
                        child: Text(l10n.gatheringCallItOff),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Ending is only offered once the start time has passed. The backend
        // refuses it before then, and for a real reason: attending a
        // gathering exempts a first message from the conversation cap, so an
        // End button reachable one call after creation would be a paywall
        // bypass rather than a tidiness problem.
        if (!gathering.startsAt.toLocal().isAfter(now))
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () async => (await _api.endGathering(gathering.id)).error,
                      success: l10n.gatheringEndedThanks,
                    ),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(l10n.gatheringEnd),
            ),
          ),
        Spacing.gapMD,
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _confirmCancel(l10n, gathering),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(l10n.gatheringCancelIt),
          ),
        ),
      ];
    }

    if (gathering.viewerIsAttending) {
      return [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(
                    () async => (await _api.cancelRsvp(gathering.id)).error,
                  ),
            child: Text(l10n.gatheringCancelRsvp),
          ),
        ),
      ];
    }

    return [
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _busy || gathering.isFull
              ? null
              : () async {
                  await _run(() async {
                    final result = await _api.rsvp(gathering.id);
                    _lastRsvpWasPending = result.value?.pending ?? false;
                    return result.error;
                  });
                  if (!mounted) return;
                  // An approval-mode RSVP is a request, not a seat, and the
                  // gathering itself cannot say so -- viewerIsAttending stays
                  // false either way.
                  //
                  // `this.context` rather than the shadowing parameter: the
                  // `mounted` check above guards the State's context, not a
                  // BuildContext captured from an enclosing build.
                  if (_lastRsvpWasPending) {
                    showCommunitySnackBar(
                      this.context,
                      message: l10n.gatheringRequested,
                    );
                  }
                },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          ),
          child: Text(
            gathering.isFull
                ? l10n.gatheringFull
                : gathering.joinMode == 'approval'
                ? l10n.gatheringAskToJoin
                : l10n.gatheringJoin,
          ),
        ),
      ),
    ];
  }

  Future<void> _confirmCancel(
    AppLocalizations l10n,
    Gathering gathering,
  ) async {
    // Cancelling notifies every attendee by push AND email — they arranged
    // their evening around this — so it gets a confirmation step.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.gatheringCancelIt),
        content: Text(l10n.gatheringCancelConfirm(gathering.going)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.gatheringKeepIt),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.gatheringCancelIt),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () async => (await _api.cancelGathering(gathering.id)).error,
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String text, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.textSecondary),
          Spacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: context.bodyMedium),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: context.captionSmall.copyWith(
                      color: context.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _longDate(DateTime local) =>
      '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
