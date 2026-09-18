import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_header.dart';

import '../support/moment_fixture.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('Follow fires its callback', (tester) async {
    var toggled = false;

    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(),
      onAvatarTap: () {},
      onMenuTap: () {},
      onFollowToggle: () => toggled = true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('moment-follow')));
    expect(toggled, isTrue);
  });

  // Your own post is not something to follow, and the card passes no callback
  // in that case.
  testWidgets('no Follow pill without a callback', (tester) async {
    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('moment-follow')), findsNothing);
  });

  testWidgets('an already-followed author reads Following', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(),
      onAvatarTap: () {},
      onMenuTap: () {},
      isFollowing: true,
      onFollowToggle: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text(l10n.following), findsOneWidget);
    expect(find.text(l10n.follow), findsNothing);
  });

  testWidgets('a maximal header with Follow does not overflow 320pt',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(SizedBox(
      width: 320,
      child: MomentCardHeader(
        moment: buildMoment(
          userName: 'Bartholomew Fotheringay-Smythe',
          nativeLanguage: 'Chinese (Traditional)',
          languageLevel: 'C2',
        ),
        onAvatarTap: () {},
        onMenuTap: () {},
        onFollowToggle: () {},
      ),
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
