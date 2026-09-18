import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_header.dart';
import 'package:bananatalk_app/widgets/language/language_exchange_pill.dart';

import '../support/moment_fixture.dart';

Widget _host(Widget child, {double width = 320}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );

void main() {
  testWidgets('the header renders the shared language pill', (tester) async {
    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.byType(LanguageExchangePill), findsOneWidget);
  });

  // The bug: five dots built with `index < 3`, a constant, so a beginner and a
  // C2 speaker rendered identically on every card in the feed.
  testWidgets('a header with no level shows no proficiency dots', (tester) async {
    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(languageLevel: null),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pumpAndSettle();

    final pill = tester.widget<LanguageExchangePill>(
      find.byType(LanguageExchangePill),
    );
    expect(dotsForLevel(pill.languageLevel), isNull);
  });

  testWidgets('a C2 speaker and an A1 speaker do not look identical',
      (tester) async {
    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(languageLevel: 'C2'),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pumpAndSettle();

    final advanced = tester.widget<LanguageExchangePill>(
      find.byType(LanguageExchangePill),
    );
    expect(dotsForLevel(advanced.languageLevel), 3);
    expect(dotsForLevel('A1'), 1);
  });

  testWidgets('a maximal header does not overflow a 320pt phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(MomentCardHeader(
      moment: buildMoment(
        userName: 'Bartholomew Fotheringay-Smythe',
        nativeLanguage: 'Chinese (Traditional)',
        languageLevel: 'C2',
      ),
      onAvatarTap: () {},
      onMenuTap: () {},
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
