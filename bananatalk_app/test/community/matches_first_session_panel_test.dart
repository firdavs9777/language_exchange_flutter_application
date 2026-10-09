import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/first_session/matches_first_session_panel.dart';

Widget _host({required double width, int matchCount = 6}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: MatchesFirstSessionPanel(matchCount: matchCount),
          ),
        ),
      ),
    );

void main() {
  testWidgets('it names the count and the one action', (tester) async {
    await tester.pumpWidget(_host(width: 390));
    await tester.pumpAndSettle();

    expect(find.textContaining('6'), findsWidgets);
    expect(find.textContaining('Say hi'), findsOneWidget);
  });

  testWidgets('it does not overflow at a narrow phone width', (tester) async {
    // Same failure class as the chat_app_bar overflow found on 2026-10-09:
    // unconstrained text in a bounded row.
    await tester.pumpWidget(_host(width: 280));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('it survives a very narrow width', (tester) async {
    await tester.pumpWidget(_host(width: 180));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a single match is not "1 people"', (tester) async {
    // matchCount is the skip-filtered list, so a user who skips five of six
    // reads this on the panel whose whole job is a good first impression.
    await tester.pumpWidget(_host(width: 390, matchCount: 1));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 people'), findsNothing);
    expect(find.textContaining('1 person'), findsOneWidget);
  });

  testWidgets('plural still reads correctly', (tester) async {
    await tester.pumpWidget(_host(width: 390, matchCount: 4));
    await tester.pumpAndSettle();
    expect(find.textContaining('4 people'), findsOneWidget);
  });

  testWidgets('it has no dismiss control', (tester) async {
    await tester.pumpWidget(_host(width: 390));
    await tester.pumpAndSettle();

    // A dismiss invites dismissal INSTEAD of acting; the view cap bounds the
    // annoyance instead.
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}
