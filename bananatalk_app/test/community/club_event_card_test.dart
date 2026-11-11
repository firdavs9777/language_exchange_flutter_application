import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/message/club_event_card.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

/// A club gathering's milestone in the club chat (backend lib/clubEvents.js):
/// a card in the reader's language, one tap from the gathering. Anything the
/// app doesn't recognise falls back to the plain `message` text.
Map<String, dynamic> _json(Map<String, dynamic>? event) => {
      '_id': 'm1',
      'sender': {'_id': 'system', 'name': 'BananaTalk'},
      'receiver': {'_id': ''},
      'message': '📅 New meetup: Thursday free talk',
      'messageType': 'system',
      'createdAt': '2026-11-11T10:00:00.000Z',
      if (event != null) 'gatheringEvent': event,
    };

Widget _app(GatheringEvent event) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(body: ClubEventCard(event: event)),
      ),
      GoRoute(
        path: '/gathering/:gatheringId',
        builder: (_, state) =>
            Text('gathering ${state.pathParameters['gatheringId']}'),
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
  test('gatheringEvent is parsed; unknown or missing events are null', () {
    final m = Message.fromJson(_json({
      'kind': 'confirmed',
      'gathering': 'g1',
      'title': 'Thursday free talk',
      'startsAt': '2026-11-20T11:30:00.000Z',
      'going': 3,
      'capacity': 6,
    }));
    expect(m.gatheringEvent!.kind, 'confirmed');
    expect(m.gatheringEvent!.gatheringId, 'g1');
    expect(m.gatheringEvent!.going, 3);
    expect(m.gatheringEvent!.capacity, 6);
    expect(m.gatheringEvent!.startsAt!.isUtc, isFalse);

    expect(Message.fromJson(_json(null)).gatheringEvent, isNull);
    expect(
      Message.fromJson(_json({'kind': 'teleported', 'gathering': 'g1'})).gatheringEvent,
      isNull,
      reason: 'a kind from a newer server shows the plain text instead',
    );
    expect(Message.fromJson(_json({'kind': 'scheduled'})).gatheringEvent, isNull);
  });

  testWidgets('each kind has its own headline, and Details opens the gathering', (tester) async {
    const event = GatheringEvent(
      kind: 'scheduled',
      gatheringId: 'g1',
      title: 'Thursday free talk',
    );
    await tester.pumpWidget(_app(event));
    await tester.pumpAndSettle();

    expect(find.text('New meetup'), findsOneWidget);
    expect(find.text('Thursday free talk'), findsOneWidget);

    await tester.tap(find.byKey(const Key('club-event-open-g1')));
    await tester.pumpAndSettle();
    expect(find.text('gathering g1'), findsOneWidget);
  });

  testWidgets('confirmed shows how many are going; cancelled hides the time', (tester) async {
    await tester.pumpWidget(_app(GatheringEvent(
      kind: 'confirmed',
      gatheringId: 'g1',
      title: 'Free talk',
      going: 4,
      startsAt: DateTime(2026, 11, 20, 20, 30),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Confirmed · 4 going'), findsOneWidget);
    expect(find.textContaining('20:30'), findsOneWidget);

    await tester.pumpWidget(_app(GatheringEvent(
      kind: 'cancelled',
      gatheringId: 'g2',
      title: 'Free talk',
      startsAt: DateTime(2026, 11, 20, 20, 30),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.textContaining('20:30'), findsNothing);
  });
}
