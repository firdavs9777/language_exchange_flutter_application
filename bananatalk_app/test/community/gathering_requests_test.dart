import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_detail_screen.dart';
import 'package:bananatalk_app/pages/community/gatherings/my_gatherings_screen.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';

/// Answers from memory. The host's pending queue is exactly the state a live
/// server will not reliably produce on demand.
class _FakeApi extends GatheringApiClient {
  _FakeApi({required this.gathering, this.mine = const []});

  Gathering gathering;
  final List<Gathering> mine;

  /// Every decideJoinRequest call, as (userId, approve).
  final List<({String userId, bool approve})> decisions = [];

  @override
  Future<Gathering?> getGathering(String id) async => gathering;

  @override
  Future<List<Gathering>> getGatherings({
    String? language,
    String? level,
    String scope = 'mine',
    int page = 1,
  }) async {
    lastScope = scope;
    return mine;
  }

  String? lastScope;

  @override
  Future<GatheringResult<Gathering>> decideJoinRequest(
    String id,
    String userId, {
    required bool approve,
  }) async {
    decisions.add((userId: userId, approve: approve));
    // The server drops the row either way — admitted people become attendees,
    // denied ones are removed outright.
    gathering = gathering.copyWith(
      requests: gathering.requests.where((r) => r.id != userId).toList(),
    );
    return GatheringResult<Gathering>.ok(gathering);
  }
}

Gathering _hosted({List<GatheringHost> requests = const []}) => Gathering(
  id: 'g1',
  title: 'Korean evening',
  startsAt: DateTime.now().add(const Duration(days: 2)),
  languageLabel: 'Korean',
  host: const GatheringHost(id: 'h1', name: 'Anna'),
  hostCity: 'Moscow',
  hostCountry: 'Russia',
  going: 2,
  needed: 1,
  viewerIsHost: true,
  requests: requests,
);

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets('the host sees who is waiting and can admit them', (tester) async {
    final api = _FakeApi(
      gathering: _hosted(requests: const [
        GatheringHost(id: 'u1', name: 'Minji'),
        GatheringHost(id: 'u2', name: 'Pavel'),
      ]),
    );
    await tester.pumpWidget(
      _host(GatheringDetailScreen(gatheringId: 'g1', apiClient: api)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Minji'), findsOneWidget);
    expect(find.text('Pavel'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gathering-admit-u1')));
    await tester.pumpAndSettle();

    expect(api.decisions.single.userId, 'u1');
    expect(api.decisions.single.approve, isTrue);
  });

  testWidgets('the host can deny a request', (tester) async {
    final api = _FakeApi(
      gathering: _hosted(requests: const [GatheringHost(id: 'u1', name: 'Minji')]),
    );
    await tester.pumpWidget(
      _host(GatheringDetailScreen(gatheringId: 'g1', apiClient: api)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gathering-deny-u1')));
    await tester.pumpAndSettle();

    expect(api.decisions.single.approve, isFalse);
  });

  testWidgets('a gathering with no requests shows no queue', (tester) async {
    final api = _FakeApi(gathering: _hosted());
    await tester.pumpWidget(
      _host(GatheringDetailScreen(gatheringId: 'g1', apiClient: api)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gathering-admit-u1')), findsNothing);
  });

  testWidgets('a non-host never sees the queue', (tester) async {
    // The backend sends an empty list to non-hosts; this guards the client
    // from rendering one if that ever changes.
    final api = _FakeApi(
      gathering: Gathering(
        id: 'g1',
        title: 'Korean evening',
        startsAt: DateTime.now().add(const Duration(days: 2)),
        viewerIsHost: false,
        requests: const [GatheringHost(id: 'u1', name: 'Minji')],
      ),
    );
    await tester.pumpWidget(
      _host(GatheringDetailScreen(gatheringId: 'g1', apiClient: api)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Minji'), findsNothing);
  });

  testWidgets('the host location is shown beneath the host name', (tester) async {
    final api = _FakeApi(gathering: _hosted());
    await tester.pumpWidget(
      _host(GatheringDetailScreen(gatheringId: 'g1', apiClient: api)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Moscow, Russia'), findsOneWidget);
  });

  testWidgets('my gatherings asks for scope=me, not the discovery scope',
      (tester) async {
    final api = _FakeApi(gathering: _hosted(), mine: [_hosted()]);
    await tester.pumpWidget(_host(MyGatheringsScreen(apiClient: api)));
    await tester.pumpAndSettle();

    expect(api.lastScope, 'me');
    expect(find.text('Korean evening'), findsOneWidget);
  });

  testWidgets('my gatherings with nothing in it explains itself', (tester) async {
    final api = _FakeApi(gathering: _hosted());
    await tester.pumpWidget(_host(MyGatheringsScreen(apiClient: api)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-gathering-g1')), findsNothing);
  });

  testWidgets('the host gets both edit and cancel', (tester) async {
    final api = _FakeApi(gathering: _hosted());
    await tester.pumpWidget(
      _host(GatheringDetailScreen(gatheringId: 'g1', apiClient: api)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gathering-edit')), findsOneWidget);
    expect(find.byKey(const Key('gathering-cancel')), findsOneWidget);
  });

  testWidgets('a non-host gets neither edit nor cancel', (tester) async {
    // Ownership is enforced server-side too (403), but a button that always
    // fails is worse than no button.
    final api = _FakeApi(
      gathering: Gathering(
        id: 'g1',
        title: 'Korean evening',
        startsAt: DateTime.now().add(const Duration(days: 2)),
        viewerIsHost: false,
      ),
    );
    await tester.pumpWidget(
      _host(GatheringDetailScreen(gatheringId: 'g1', apiClient: api)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gathering-edit')), findsNothing);
    expect(find.byKey(const Key('gathering-cancel')), findsNothing);
  });

  testWidgets('tapping edit opens the form seeded with the gathering',
      (tester) async {
    final api = _FakeApi(gathering: _hosted());
    await tester.pumpWidget(
      _host(GatheringDetailScreen(gatheringId: 'g1', apiClient: api)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gathering-edit')));
    await tester.pumpAndSettle();

    // The existing title is in the form, not a blank create sheet.
    expect(find.widgetWithText(TextField, 'Korean evening'), findsOneWidget);
  });
}
