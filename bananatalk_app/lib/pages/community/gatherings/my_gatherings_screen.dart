import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_card.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gatheringsMine)),
      body: FutureBuilder<List<Gathering>>(
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
                    style: context.bodyMedium.copyWith(color: context.textMuted),
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
      ),
    );
  }
}
