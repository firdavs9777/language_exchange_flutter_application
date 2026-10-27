import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_detail_screen.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';

/// The attendee card (spec §3.1): once a gathering has happened, someone who
/// was there sees who else came, each one tap from a chat. The backend sends
/// `people` only then and only to them, so the screen just renders it.
class _FakeApi extends GatheringApiClient {
  _FakeApi(this.gathering);

  final Gathering gathering;

  @override
  Future<Gathering?> getGathering(String id) async => gathering;
}

Gathering _ended({List<Map<String, dynamic>> people = const []}) =>
    Gathering.fromJson({
      '_id': 'g1',
      'title': 'Korean evening',
      'startsAt': DateTime.now()
          .subtract(const Duration(hours: 3))
          .toIso8601String(),
      'status': 'ended',
      'host': {'_id': 'h1', 'name': 'Anna'},
      'people': people,
    });

Widget _app(GatheringApiClient api) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            GatheringDetailScreen(gatheringId: 'g1', apiClient: api),
      ),
      GoRoute(
        path: '/chat/:userId',
        builder: (_, state) =>
            Text('chat with ${state.pathParameters['userId']}'),
      ),
    ],
  );
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  test('people is parsed, and defaults to empty', () {
    final g = _ended(people: [
      {'_id': 'u2', 'name': 'Bo', 'images': ['https://x/bo.jpg']},
    ]);
    expect(g.people.single.id, 'u2');
    expect(g.people.single.name, 'Bo');
    expect(g.people.single.avatar, 'https://x/bo.jpg');
    expect(_ended().people, isEmpty);
  });

  testWidgets('who was there, and Message opens the chat', (tester) async {
    await tester.pumpWidget(_app(_FakeApi(_ended(people: [
      {'_id': 'u2', 'name': 'Bo'},
      {'_id': 'u3', 'name': 'Cy'},
    ]))));
    await tester.pumpAndSettle();

    expect(find.text('Who was there'), findsOneWidget);
    expect(find.byKey(const Key('gathering-person-u2')), findsOneWidget);
    expect(find.byKey(const Key('gathering-person-u3')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('gathering-message-u3')));
    await tester.tap(find.byKey(const Key('gathering-message-u3')));
    await tester.pumpAndSettle();
    expect(find.text('chat with u3'), findsOneWidget);
  });

  testWidgets('no people, no card', (tester) async {
    await tester.pumpWidget(_app(_FakeApi(_ended())));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gathering-people')), findsNothing);
    expect(find.text('Who was there'), findsNothing);
  });
}
