import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_card.dart';

/// The card has to survive the worst real row: a long language label, a level,
/// a long title and a long host name, on the narrowest phone we support.
Widget _host(Widget child, {double width = 320}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

Gathering _wide() => Gathering(
  id: 'g1',
  title: 'Chinese Traditional conversation practice for intermediate learners',
  startsAt: DateTime.now().add(const Duration(days: 3)),
  languageLabel: 'Chinese (Traditional)',
  level: 'B2',
  host: const GatheringHost(id: 'h1', name: 'Bartholomew Fotheringay-Smythe'),
  hostCity: 'Ulaanbaatar',
  hostCountry: 'Mongolia',
  hostTimezone: 'Asia/Ulaanbaatar',
  going: 2,
  needed: 1,
);

void main() {
  testWidgets('a maximal card does not overflow a 320pt phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(
      GatheringCard(gathering: _wide(), onTap: () {}, onRsvp: () {}),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the host badge shows how many are waiting', (tester) async {
    await tester.pumpWidget(_host(
      GatheringCard(
        gathering: Gathering(
          id: 'g1',
          title: 'Korean evening',
          startsAt: DateTime.now().add(const Duration(days: 1)),
          viewerIsHost: true,
          requests: const [
            GatheringHost(id: 'u1', name: 'Minji'),
            GatheringHost(id: 'u2', name: 'Pavel'),
          ],
        ),
        onTap: () {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gathering-card-requests')), findsOneWidget);
  });

  testWidgets('a gathering with no one waiting shows no badge', (tester) async {
    await tester.pumpWidget(_host(
      GatheringCard(
        gathering: Gathering(
          id: 'g1',
          title: 'Korean evening',
          startsAt: DateTime.now().add(const Duration(days: 1)),
          viewerIsHost: true,
        ),
        onTap: () {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gathering-card-requests')), findsNothing);
  });
}
