import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/card/match_card.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';

DailyMatch _match({
  List<String> reasons = const ['reciprocal_pair'],
  String? bucket,
  double? rate,
}) =>
    DailyMatch.fromJson({
      'user': {
        '_id': 'u1',
        'name': 'Minji',
        'native_language': 'Korean',
        'language_to_learn': 'English',
      },
      'matchReasons': reasons,
      'reciprocal': true,
      'lastActiveBucket': bucket,
      'responseRate': rate,
    });

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('renders reciprocal reason and fires Say hi', (tester) async {
    var hi = 0;
    await tester.pumpWidget(_wrap(MatchCard(
      match: _match(),
      onSayHi: () => hi++,
      onWave: () {},
      onSkip: () {},
    )));
    expect(find.text("You're learning each other's language"), findsOneWidget);
    await tester.tap(find.text('Say hi'));
    expect(hi, 1);
  });

  testWidgets('shows Replies fast only for responseRate >= 0.7',
      (tester) async {
    await tester.pumpWidget(_wrap(MatchCard(
      match: _match(rate: 0.9),
      onSayHi: () {},
      onWave: () {},
      onSkip: () {},
    )));
    expect(find.text('Replies fast'), findsOneWidget);
    await tester.pumpWidget(_wrap(MatchCard(
      match: _match(rate: 0.3),
      onSayHi: () {},
      onWave: () {},
      onSkip: () {},
    )));
    expect(find.text('Replies fast'), findsNothing);
  });

  testWidgets('presence dot only when active today; unknown reasons hidden',
      (tester) async {
    await tester.pumpWidget(_wrap(MatchCard(
      match: _match(reasons: ['bogus_key', 'shared_topic:travel']),
      onSayHi: () {},
      onWave: () {},
      onSkip: () {},
    )));
    expect(find.byKey(const Key('match-presence-dot')), findsNothing);
    expect(find.text('Shared interest: travel'), findsOneWidget);
    expect(find.text('bogus_key'), findsNothing);
    await tester.pumpWidget(_wrap(MatchCard(
      match: _match(bucket: 'today'),
      onSayHi: () {},
      onWave: () {},
      onSkip: () {},
    )));
    expect(find.byKey(const Key('match-presence-dot')), findsOneWidget);
  });
}
