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
import 'package:bananatalk_app/pages/community/gatherings/gathering_filter_bar.dart';
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
    with
        AutomaticKeepAliveClientMixin<GatheringsTab>,
        TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  /// Gatherings first, clubs second.
  ///
  /// The original single-scroll layout led with clubs on purpose: a club does
  /// not reset to empty between events, so it looked alive on a day when
  /// nothing was scheduled. Splitting the two loses that cover, so the
  /// Gatherings tab carries its own — its empty state is a pre-filled create
  /// form, not an apology, which reads as an invitation rather than an
  /// abandoned list.
  ///
  /// Built in initState, not lazily. As a `late final` initialiser it was
  /// constructed on first *use*, and the error and skeleton paths never build
  /// the tab bar — so on those paths `dispose()` was the first read, which
  /// constructed a TabController against an already-deactivated element and
  /// threw "Looking up a deactivated widget's ancestor is unsafe" on the way
  /// out of an offline tab.
  late final TabController _tabs;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  late final GatheringApiClient _api = widget.apiClient ?? GatheringApiClient();

  late Future<_FeedData> _feed;

  /// Ids currently mid-RSVP, so a double tap cannot double-post.
  final Set<String> _busy = {};

  /// What the list is narrowed to. Filtering happens server-side so the page
  /// size stays meaningful -- narrowing a single fetched page would show three
  /// results out of thirty and call it "all".
  GatheringFilters _filters = const GatheringFilters();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _feed = _load();
  }

  Future<_FeedData> _load() async {
    // One round trip each, in parallel: the strip and the list are
    // independent and the tab should not wait for the slower of them twice.
    final results = await Future.wait([
      _api.getClubs(),
      _api.getGatherings(
        topic: _filters.topic,
        when: _filters.when,
        hasSeat: _filters.hasSeat,
      ),
    ]);
    return _FeedData(
      clubs: results[0] as List<Club>,
      gatherings: results[1] as List<Gathering>,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    // Block body, not an arrow: `() => _feed = next` evaluates to the assigned
    // Future, and setState rejects a callback that returns one.
    setState(() {
      _feed = next;
    });
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

  /// Refetches, because filtering is server-side. Skips identical filters so
  /// tapping a lit chip twice costs nothing.
  void _onFiltersChanged(GatheringFilters next) {
    if (next == _filters) return;
    setState(() {
      _filters = next;
      _feed = _load();
    });
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
          // Only skeleton when there is nothing to show. FutureBuilder keeps
          // the previous snapshot's data across a future swap, so testing
          // `waiting` alone replaced the whole tab -- header included -- with
          // a skeleton after every RSVP, filter change and pull-to-refresh.
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            // UserListSkeleton IS a ListView -- wrapping it in another one
            // nests two vertical viewports and throws "Vertical viewport was
            // given unbounded height" on the very first frame of the tab.
            return const UserListSkeleton(count: 4);
          }
          // Reachable at last: the read paths used to swallow every failure
          // into an empty list, so an offline user was shown the empty state
          // -- a "create your first gathering" form -- instead of this.
          if (snapshot.hasError) {
            return CommunityErrorState(
              message: l10n.gatheringLoadFailed,
              onRetry: _refresh,
            );
          }

          final data = snapshot.data ?? const _FeedData();

          return Column(
            children: [
              _innerTabs(context, l10n, data),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _gatheringsView(context, l10n, data),
                    _clubsView(context, l10n, data),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The two-tab header. Counts are shown only when non-zero: a "Clubs 0"
  /// label advertises the emptiness this feature is most at risk from.
  Widget _innerTabs(
    BuildContext context,
    AppLocalizations l10n,
    _FeedData data,
  ) {
    String label(String base, int count) => count > 0 ? '$base  $count' : base;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.dividerColor)),
      ),
      child: TabBar(
        controller: _tabs,
        labelColor: AppColors.primary,
        unselectedLabelColor: context.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: [
          Tab(
            key: const Key('gatherings-inner-tab'),
            text: label(l10n.gatheringStartingSoon, data.gatherings.length),
          ),
          Tab(
            key: const Key('clubs-inner-tab'),
            text: label(l10n.gatheringClubs, data.clubs.length),
          ),
        ],
      ),
    );
  }

  /// What is starting soon. Empty means the create form, not an apology.
  Widget _gatheringsView(
    BuildContext context,
    AppLocalizations l10n,
    _FeedData data,
  ) {
    if (data.gatherings.isEmpty) {
      return Column(
        children: [
          // Kept visible when the list is empty: an active filter is the most
          // likely reason it IS empty, and hiding the control that caused it
          // makes the state unexplainable.
          if (!_filters.isEmpty)
            GatheringFilterBar(filters: _filters, onChanged: _onFiltersChanged),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_filters.isEmpty)
                    _emptyState(context, data.clubs.isEmpty)
                  else
                    _noMatchState(context),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        GatheringFilterBar(filters: _filters, onChanged: _onFiltersChanged),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              // Always scrollable so pull-to-refresh works even on a short list.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
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
            ),
          ),
        ),
      ],
    );
  }

  /// Empty because of a filter, not because nothing exists.
  ///
  /// Distinct from the create-form empty state on purpose: offering a draft
  /// here would answer a question nobody asked. What they want is their list
  /// back.
  Widget _noMatchState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xxl,
        Spacing.lg,
        0,
      ),
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_off_rounded,
            size: 40,
            color: context.textMuted,
          ),
          Spacing.gapMD,
          Text(
            l10n.filterNoMatches,
            textAlign: TextAlign.center,
            style: context.bodyMedium.copyWith(color: context.textSecondary),
          ),
          Spacing.gapMD,
          TextButton(
            key: const Key('filter-clear-empty'),
            onPressed: () => _onFiltersChanged(const GatheringFilters()),
            child: Text(l10n.filterClear(_filters.activeCount)),
          ),
        ],
      ),
    );
  }

  /// Every club, as a full-width list rather than the old horizontal strip.
  /// The strip existed because clubs shared a scroll view with the gatherings
  /// list; with a tab of their own they get the room.
  Widget _clubsView(
    BuildContext context,
    AppLocalizations l10n,
    _FeedData data,
  ) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _sectionHeader(
            context,
            l10n.gatheringClubs,
            action: _textAction(context, l10n.gatheringNewClub, () async {
              final club = await showCreateClubSheet(
                context,
                defaultLanguage: _defaultLanguage,
              );
              if (club != null) await _refresh();
            }),
          ),
          if (data.clubs.isEmpty)
            SliverToBoxAdapter(child: _noClubsYet(context))
          else
            SliverList.builder(
              itemCount: data.clubs.length,
              itemBuilder: (context, index) => _ClubRow(
                club: data.clubs[index],
                onTap: () async {
                  await Navigator.of(context).push(
                    AppPageRoute(
                      builder: (_) =>
                          ClubDetailScreen(clubId: data.clubs[index].id),
                    ),
                  );
                  await _refresh();
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
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

  /// Shown in the club strip's place when there are none.
  ///
  /// A line of copy rather than an empty gap: the strip disappearing entirely
  /// is what made the missing "New club" action invisible rather than merely
  /// inconvenient.
  Widget _noClubsYet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
      child: Text(
        l10n.gatheringNoClubsYet,
        style: context.bodySmall.copyWith(color: context.textSecondary),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, {Widget? action}) {
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

/// A club as a full-width row.
///
/// This was a 190x116 chip in a horizontally scrolling strip, which made
/// sense when clubs shared one scroll view with the gatherings list. Once
/// clubs got a tab of their own the strip stayed, so the whole tab was a
/// single short band across the top with an empty screen beneath it — the
/// abandoned look this feature can least afford.
///
/// The member count leads the subtitle because it is the cold-start signal:
/// the number that makes the list look alive when nothing is scheduled.
class _ClubRow extends StatelessWidget {
  const _ClubRow({required this.club, required this.onTap});

  final Club club;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = [
      l10n.clubMembers(club.memberCount),
      if (club.interest.isNotEmpty) club.interest,
    ].join(' · ');

    return ListTile(
      key: Key('club-row-${club.id}'),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: context.containerColor,
        backgroundImage:
            club.coverImage != null && club.coverImage!.isNotEmpty
            ? NetworkImage(club.coverImage!)
            : null,
        child: club.coverImage == null || club.coverImage!.isEmpty
            ? Icon(Icons.groups_rounded, color: context.primaryColor)
            : null,
      ),
      title: Text(
        club.name,
        style: context.titleSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: context.bodySmall.copyWith(color: context.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.chevron_right, color: context.textMuted),
    );
  }
}

class _FeedData {
  const _FeedData({this.clubs = const [], this.gatherings = const []});

  final List<Club> clubs;
  final List<Gathering> gatherings;
}
