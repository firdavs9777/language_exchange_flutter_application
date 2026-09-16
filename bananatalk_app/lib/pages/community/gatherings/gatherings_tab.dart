import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_detail_screen.dart';
import 'package:bananatalk_app/pages/community/gatherings/create_club_sheet.dart';
import 'package:bananatalk_app/pages/community/gatherings/create_gathering_form.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_card.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_detail_screen.dart';
import 'package:bananatalk_app/pages/community/widgets/community_error_state.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';

/// 모임 — the tab that replaces Voice Rooms.
///
/// Not a ninth tab. Gatherings are voice rooms with commitment attached, and
/// voice rooms failed 93 times out of 93 by depending on people being online
/// at the same moment. Replacing that entry keeps the tab count flat and
/// retires the surface that taught this audience the app is empty.
///
/// Two things stacked: the clubs strip, then what is starting soon. The clubs
/// come first deliberately — a club does not reset to empty between events,
/// so "Korean Learners Club · 49 members" looks alive on a day when nothing
/// at all is scheduled, which is precisely the day this feature is most at
/// risk of looking abandoned.
class GatheringsTab extends ConsumerStatefulWidget {
  const GatheringsTab({super.key, this.apiClient});

  /// Injectable for widget tests, which must not touch the network.
  final GatheringApiClient? apiClient;

  @override
  ConsumerState<GatheringsTab> createState() => _GatheringsTabState();
}

class _GatheringsTabState extends ConsumerState<GatheringsTab>
    with AutomaticKeepAliveClientMixin<GatheringsTab> {
  @override
  bool get wantKeepAlive => true;

  late final GatheringApiClient _api = widget.apiClient ?? GatheringApiClient();

  late Future<_FeedData> _feed;

  /// Ids currently mid-RSVP, so a double tap cannot double-post.
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _feed = _load();
  }

  Future<_FeedData> _load() async {
    // One round trip each, in parallel: the strip and the list are
    // independent and the tab should not wait for the slower of them twice.
    final results = await Future.wait([
      _api.getClubs(),
      _api.getGatherings(),
    ]);
    return _FeedData(
      clubs: results[0] as List<Club>,
      gatherings: results[1] as List<Gathering>,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _feed = next);
    await next;
  }

  /// The viewer's target language, used to pre-fill the create form. Empty is
  /// fine — the form just cannot be posted in a single tap.
  String get _defaultLanguage {
    final user = ref.read(userProvider).valueOrNull;
    final learning = user?.language_to_learn ?? '';
    if (learning.isNotEmpty) return learning;
    return user?.native_language ?? '';
  }

  Future<void> _rsvp(Gathering gathering) async {
    if (_busy.contains(gathering.id)) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy.add(gathering.id));

    String? error;
    var pending = false;
    if (gathering.viewerIsAttending) {
      error = (await _api.cancelRsvp(gathering.id)).error;
    } else {
      final result = await _api.rsvp(gathering.id);
      error = result.error;
      pending = result.value?.pending ?? false;
    }
    if (!mounted) return;
    setState(() => _busy.remove(gathering.id));

    if (error != null) {
      showCommunitySnackBar(
        context,
        message: error,
        type: CommunitySnackBarType.error,
      );
      return;
    }

    // An approval-mode RSVP lands as a request, not a seat. Saying so is the
    // difference between "asked to join" and a tap that appears to do
    // nothing at all.
    if (pending) {
      showCommunitySnackBar(context, message: l10n.gatheringRequested);
    }
    await _refresh();
  }

  Future<void> _create({String? clubId}) async {
    final created = await showCreateGatheringSheet(
      context,
      defaultLanguage: _defaultLanguage,
      clubId: clubId,
    );
    if (created != null) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<_FeedData>(
        future: _feed,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // UserListSkeleton IS a ListView -- wrapping it in another one
            // nests two vertical viewports and throws "Vertical viewport was
            // given unbounded height" on the very first frame of the tab.
            return const UserListSkeleton(count: 4);
          }
          if (snapshot.hasError) {
            return CommunityErrorState(
              message: l10n.gatheringLoadFailed,
              onRetry: _refresh,
            );
          }

          final data = snapshot.data ?? const _FeedData();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              // Always scrollable so pull-to-refresh works on the empty state
              // too, which is the state most in need of a retry.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (data.clubs.isNotEmpty) ...[
                  _sectionHeader(
                    context,
                    l10n.gatheringClubs,
                    action: _textAction(
                      context,
                      l10n.gatheringNewClub,
                      () async {
                        final club = await showCreateClubSheet(
                          context,
                          defaultLanguage: _defaultLanguage,
                        );
                        if (club != null) await _refresh();
                      },
                    ),
                  ),
                  SliverToBoxAdapter(child: _clubStrip(data.clubs)),
                ],
                if (data.gatherings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyState(context, data.clubs.isEmpty),
                  )
                else ...[
                  _sectionHeader(
                    context,
                    l10n.gatheringStartingSoon,
                    action: _textAction(
                      context,
                      l10n.gatheringCreateShort,
                      () => _create(),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: data.gatherings.length,
                    itemBuilder: (context, index) {
                      final gathering = data.gatherings[index];
                      return GatheringCard(
                        gathering: gathering,
                        busy: _busy.contains(gathering.id),
                        onRsvp: gathering.isOpenForRsvp
                            ? () => _rsvp(gathering)
                            : null,
                        onTap: () async {
                          await Navigator.of(context).push(
                            AppPageRoute(
                              builder: (_) => GatheringDetailScreen(
                                gatheringId: gathering.id,
                              ),
                            ),
                          );
                          await _refresh();
                        },
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// The empty state IS the create form.
  ///
  /// An apology ("no gatherings yet") is what an abandoned list looks like,
  /// and this audience has already been taught that lesson twice. A draft
  /// with the language, the time and the seats already filled in says the
  /// opposite: the thing that is missing is one tap away, and you are the
  /// person who can do it.
  Widget _emptyState(BuildContext context, bool noClubsEither) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.xxl,
              Spacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.gatheringEmptyTitle, style: context.titleLarge),
                Spacing.gapSM,
                Text(
                  l10n.gatheringEmptyBody,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Spacing.gapLG,
          CreateGatheringForm(
            key: const Key('gatherings_empty_create_form'),
            compact: true,
            defaultLanguage: _defaultLanguage,
            onCreated: (_) => _refresh(),
          ),
          if (noClubsEither)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.xxl,
              ),
              child: TextButton.icon(
                onPressed: () async {
                  final club = await showCreateClubSheet(
                    context,
                    defaultLanguage: _defaultLanguage,
                  );
                  if (club != null) await _refresh();
                },
                icon: const Icon(Icons.groups_rounded, size: 18),
                label: Text(l10n.gatheringStartAClub),
              ),
            ),
        ],
      ),
    );
  }

  Widget _clubStrip(List<Club> clubs) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        itemCount: clubs.length,
        separatorBuilder: (_, __) => Spacing.hGapMD,
        itemBuilder: (context, index) => _ClubChip(
          club: clubs[index],
          onTap: () async {
            await Navigator.of(context).push(
              AppPageRoute(
                builder: (_) => ClubDetailScreen(clubId: clubs[index].id),
              ),
            );
            await _refresh();
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title, {
    Widget? action,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.lg,
          Spacing.sm,
          Spacing.sm,
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: context.titleMedium)),
            if (action != null) action,
          ],
        ),
      ),
    );
  }

  Widget _textAction(BuildContext context, String label, VoidCallback onTap) {
    return TextButton(onPressed: onTap, child: Text(label));
  }
}

/// A club as it appears in the strip. The member count leads, because it is
/// the cold-start signal — the number that makes the list look alive when
/// nothing is scheduled.
class _ClubChip extends StatelessWidget {
  const _ClubChip({required this.club, required this.onTap});

  final Club club;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderLG,
      child: Container(
        width: 190,
        padding: Spacing.paddingMD,
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: AppRadius.borderLG,
          border: Border.all(color: context.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              club.name,
              style: context.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (club.interest.isNotEmpty)
              Text(
                club.interest,
                style: context.captionSmall.copyWith(color: context.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                Icon(
                  Icons.people_rounded,
                  size: 14,
                  color: context.primaryColor,
                ),
                Spacing.hGapXS,
                Flexible(
                  child: Text(
                    l10n.clubMembers(club.memberCount),
                    style: context.bodySmall.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedData {
  const _FeedData({this.clubs = const [], this.gatherings = const []});

  final List<Club> clubs;
  final List<Gathering> gatherings;
}
