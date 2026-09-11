import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/progress/mastery_screen.dart';

const _mastery = MasterySummary(
  level: 'A2',
  book: 'elementary',
  vocabulary: VocabMastery(mastered: 84, learning: 31, fresh: 4, due: 12),
  grammar: GrammarProgress(mastered: 9, total: 115, sections: [
    GrammarSection(section: 'Present', mastered: 9, total: 9),
    GrammarSection(section: 'Past', mastered: 0, total: 5),
  ]),
  listening: SkillAccuracy(accuracy: 0.71, samples: 14),
  translate: SkillAccuracy(accuracy: null, samples: 0),
  consistencyDays: ['2026-09-06', '2026-09-07'],
);

Widget _host(MasterySummary? m) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MasteryScreen(mastery: m),
    );

void main() {
  testWidgets('renders a bar per skill', (tester) async {
    await tester.pumpWidget(_host(_mastery));
    expect(find.byKey(const Key('mastery-vocabulary')), findsOneWidget);
    expect(find.byKey(const Key('mastery-grammar')), findsOneWidget);
    expect(find.byKey(const Key('mastery-listening')), findsOneWidget);
  });

  testWidgets('the level badge offers a retake and claims no certification', (tester) async {
    await tester.pumpWidget(_host(_mastery));
    expect(find.byKey(const Key('mastery-level-retake')), findsOneWidget);
    expect(find.textContaining('certif'), findsNothing);
  });

  testWidgets('grammar breaks down by section', (tester) async {
    await tester.pumpWidget(_host(_mastery));
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
  });

  testWidgets('due words are a call to action into review', (tester) async {
    await tester.pumpWidget(_host(_mastery));
    expect(find.byKey(const Key('mastery-due-cta')), findsOneWidget);
  });

  testWidgets('a skill with no samples reads as not started, not 0%', (tester) async {
    await tester.pumpWidget(_host(_mastery));
    expect(find.byKey(const Key('mastery-translate')), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('a learner with no data sees an empty state, not a crash', (tester) async {
    await tester.pumpWidget(_host(null));
    expect(find.byKey(const Key('mastery-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
