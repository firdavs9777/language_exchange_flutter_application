import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';
import 'package:bananatalk_app/pages/community/gatherings/create_gathering_form.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_card.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_detail_screen.dart';
import 'package:bananatalk_app/pages/community/widgets/community_error_state.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// A club, and what it has coming up.
///
/// A club with nothing scheduled is not a failure state — that is the whole
/// reason the club is the primary entity. "49 members" is true on a quiet
/// week, whereas an event list resets to empty after every event and reads as
/// abandoned.
class ClubDetailScreen extends StatefulWidget {
  const ClubDetailScreen({super.key, required this.clubId, this.apiClient});

  final String clubId;
  final GatheringApiClient? apiClient;

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  late final GatheringApiClient _api = widget.apiClient ?? GatheringApiClient();
  late Future<Club?> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getClub(widget.clubId);
  }

  Future<void> _reload() async {
    final next = _api.getClub(widget.clubId);
    setState(() => _future = next);
    await next;
  }

  Future<void> _toggleMembership(Club club) async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = club.viewerIsMember
        ? (await _api.leaveClub(club.id)).error
        : (await _api.joinClub(club.id)).error;
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
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clubDetailTitle)),
      body: FutureBuilder<Club?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final club = snapshot.data;
          if (club == null) {
            return CommunityErrorState(
              message: l10n.clubNotFound,
              onRetry: _reload,
            );
          }
          return _body(context, l10n, club);
        },
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, Club club) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Spacing.xxxl),
        children: [
          Padding(
            padding: Spacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club.name, style: context.displaySmall),
                Spacing.gapSM,
                Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: context.primaryColor,
                    ),
                    Spacing.hGapXS,
                    Text(
                      l10n.clubMembers(club.memberCount),
                      style: context.bodyMedium.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (club.displayLanguage.isNotEmpty) ...[
                      Spacing.hGapSM,
                      Text('·', style: context.bodyMedium),
                      Spacing.hGapSM,
                      Flexible(
                        child: Text(
                          club.interest.isEmpty
                              ? club.displayLanguage
                              : '${club.displayLanguage} · ${club.interest}',
                          style: context.bodyMedium.copyWith(
                            color: context.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (club.description.isNotEmpty) ...[
                  Spacing.gapMD,
                  Text(club.description, style: context.bodyMedium),
                ],
                Spacing.gapLG,
                if (!club.viewerIsOwner)
                  SizedBox(
                    width: double.infinity,
                    child: club.viewerIsMember
                        ? OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _toggleMembership(club),
                            child: Text(l10n.clubLeave),
                          )
                        : FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _toggleMembership(club),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: Spacing.md,
                              ),
                            ),
                            child: Text(l10n.clubJoin),
                          ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              0,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Text(l10n.clubUpcoming, style: context.titleMedium),
          ),

          if (club.gatherings.isEmpty)
            Padding(
              padding: Spacing.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clubNothingScheduled,
                    style: context.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  // Only members may host for a club — the backend refuses
                  // otherwise, and for a good reason: anyone could otherwise
                  // hang a gathering off a 586-member club and borrow its
                  // audience.
                  if (club.viewerIsMember) ...[
                    Spacing.gapLG,
                    CreateGatheringForm(
                      compact: true,
                      clubId: club.id,
                      defaultLanguage: club.displayLanguage,
                      onCreated: (_) => _reload(),
                    ),
                  ],
                ],
              ),
            )
          else ...[
            ...club.gatherings.map(
              (g) => GatheringCard(
                gathering: g,
                onTap: () async {
                  await Navigator.of(context).push(
                    AppPageRoute(
                      builder: (_) => GatheringDetailScreen(gatheringId: g.id),
                    ),
                  );
                  await _reload();
                },
              ),
            ),
            if (club.viewerIsMember)
              Padding(
                padding: Spacing.paddingLG,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final created = await showCreateGatheringSheet(
                      context,
                      defaultLanguage: club.displayLanguage,
                      clubId: club.id,
                    );
                    if (created != null) await _reload();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.clubHostGathering),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
