import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_card.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_detail_screen.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_detail_screen.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// The gatherings this viewer hosts or holds a seat in, reached from the
/// profile drawer.
///
/// Separate from the community tab, which is *discovery* — everything in the
/// viewer's languages. A host had no way to find their own gathering again
/// once it scrolled past, which is how a host forgets to turn up to the thing
/// they created.
class MyGatheringsScreen extends StatefulWidget {
  const MyGatheringsScreen({super.key, this.apiClient});

  /// Injected by tests so the screen never reaches the network.
  final GatheringApiClient? apiClient;

  @override
  State<MyGatheringsScreen> createState() => _MyGatheringsScreenState();
}

class _MyGatheringsScreenState extends State<MyGatheringsScreen> {
  late final GatheringApiClient _api = widget.apiClient ?? GatheringApiClient();
  late Future<List<Gathering>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // scope=me, not the tab's scope=mine: one means "hosted by or joined by me",
  // the other means "in my languages".
  Future<List<Gathering>> _load() => _api.getGatherings(scope: 'me');

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _open(Gathering gathering) async {
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => GatheringDetailScreen(gatheringId: gathering.id),
      ),
    );
    // Reload on return: the host may have just admitted someone or cancelled.
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.gatheringsMine),
          // Clubs live here too. They were reachable only by browsing the
          // community tab and remembering which ones you had joined — a
          // standing group you belong to should be findable from your own
          // profile, the same as the events you said yes to.
          bottom: TabBar(
            tabs: [
              Tab(key: const Key('mine-tab-gatherings'), text: l10n.gatheringsMine),
              Tab(key: const Key('mine-tab-clubs'), text: l10n.clubsMine),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _gatheringsTab(context, l10n),
            const MyClubsTab(),
          ],
        ),
      ),
    );
  }

  Widget _gatheringsTab(BuildContext context, AppLocalizations l10n) {
    return FutureBuilder<List<Gathering>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final gatherings = snapshot.data ?? const <Gathering>[];
          if (gatherings.isEmpty) {
            // Still scrollable, so pull-to-refresh works on an empty list.
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                  Icon(
                    Icons.event_outlined,
                    size: 40,
                    color: context.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.gatheringsMineEmpty,
                    textAlign: TextAlign.center,
                    style: context.bodyMedium.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            // No padding here: GatheringCard carries its own margin, and the
            // community tab lays them out the same way. Adding an inset would
            // double it and make this list look narrower than that one.
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: gatherings.length,
              itemBuilder: (context, i) {
                final gathering = gatherings[i];
                return GatheringCard(
                  key: Key('my-gathering-${gathering.id}'),
                  gathering: gathering,
                  onTap: () => _open(gathering),
                );
              },
            ),
          );
        },
    );
  }
}

/// The clubs this person belongs to, owned or joined.
///
/// Separate widget rather than more state on the screen above: its future is
/// independent, and a failure to load clubs must not blank the gatherings
/// list next to it.
class MyClubsTab extends StatefulWidget {
  const MyClubsTab({super.key});

  @override
  State<MyClubsTab> createState() => _MyClubsTabState();
}

class _MyClubsTabState extends State<MyClubsTab> {
  final GatheringApiClient _api = GatheringApiClient();
  late Future<List<Club>> _future = _load();

  // scope=member is "clubs I am in", distinct from the language scoping the
  // other values control.
  Future<List<Club>> _load() => _api.getClubs(scope: 'member');

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Club>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final clubs = snapshot.data ?? const <Club>[];
        if (clubs.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                Icon(Icons.groups_outlined, size: 40, color: context.textMuted),
                const SizedBox(height: 12),
                Text(
                  l10n.clubsMineEmpty,
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(color: context.textMuted),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: clubs.length,
            itemBuilder: (context, i) {
              final club = clubs[i];
              return ListTile(
                key: Key('my-club-${club.id}'),
                leading: CircleAvatar(
                  backgroundColor: context.containerColor,
                  backgroundImage: club.coverImage != null
                      ? NetworkImage(club.coverImage!)
                      : null,
                  child: club.coverImage == null
                      ? Icon(Icons.groups_outlined, color: context.textMuted)
                      : null,
                ),
                title: Text(club.name),
                subtitle: Text(
                  [
                    if (club.displayLanguage.isNotEmpty) club.displayLanguage,
                    l10n.clubMembers(club.memberCount),
                    // Shown, not hidden: an owner whose club was archived
                    // should learn that here rather than wonder where it went.
                    if (club.status != 'active') club.status,
                  ].join(' · '),
                  style: context.captionSmall
                      .copyWith(color: context.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  AppPageRoute(
                    builder: (_) => ClubDetailScreen(clubId: club.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
