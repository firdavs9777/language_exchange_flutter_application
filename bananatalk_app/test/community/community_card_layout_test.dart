import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/card/community_card.dart';

import '../support/community_fixture.dart';

Widget _host(Widget child, {double width = 320}) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
      ),
    );

void main() {
  testWidgets('a maximal row does not overflow a 320pt phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(CommunityCard(
      community: buildCommunity(
        name: 'Bartholomew Fotheringay-Smythe',
        nativeLanguage: 'Chinese (Traditional)',
        languageToLearn: 'English',
        languageLevel: 'B2',
        bio: 'Looking for someone to practise with every single day of the week, '
            'preferably in the evenings, about food and films and everything else.',
        topics: const ['Philosophy'],
        vipSubscriptionActive: true,
        showOnlineStatus: false,
      ),
      onTap: () {},
    )));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });

  testWidgets('the row no longer carries a View Profile button', (tester) async {
    await tester.pumpWidget(_host(
      CommunityCard(
        community: buildCommunity(showOnlineStatus: false),
        onTap: () {},
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    // Tapping the row already opens the profile; a second control doing the
    // same thing is what this redesign removed.
    expect(find.textContaining('View Profile'), findsNothing);
  });

  testWidgets('tapping the row fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_host(
      CommunityCard(
        community: buildCommunity(showOnlineStatus: false),
        onTap: () => tapped = true,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byType(CommunityCard));
    expect(tapped, isTrue);
  });
}
