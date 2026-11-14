import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/sections/recommended_tile.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/services/ai_service.dart';

void main() {
  // What GET /learning/progress/weak-areas sends today
  // (controllers/learning.js getWeakAreas + recommendationService).
  final serverBody = {
    'weakAreas': [
      {
        'topic': 'Past tense',
        'category': 'quiz',
        'score': 0.4,
        'mistakeRate': 60,
      },
      {
        'topic': 'food',
        'category': 'vocabulary',
        'score': 0.2,
        'mistakeRate': 80,
      },
    ],
  };

  test(
    'weak areas parse from the object shape and from the old list shape',
    () {
      final fromObject = parseWeakAreas(serverBody);
      expect(fromObject.map((a) => a.name), ['Past tense', 'food']);
      expect(fromObject.first.accuracy, closeTo(0.4, 1e-9));

      final fromList = parseWeakAreas([
        {
          'name': 'Articles',
          'category': 'grammar',
          'accuracy': 0.5,
          'attempts': 8,
        },
      ]);
      expect(fromList.single.name, 'Articles');
      expect(fromList.single.attempts, 8);

      expect(parseWeakAreas(null), isEmpty);
      expect(parseWeakAreas('nope'), isEmpty);
      expect(parseWeakAreas({'weakAreas': 'nope'}), isEmpty);
      expect(
        parseWeakAreas({
          'weakAreas': [
            1,
            null,
            {'topic': 'x'},
          ],
        }).length,
        1,
      );
    },
  );

  testWidgets(
    'the recommended tile shows when the server reports a weak area',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weakAreasProvider.overrideWith(
              (ref) async => parseWeakAreas(serverBody),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: RecommendedTile()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Only the quiz area qualifies (the vocabulary one is weaker, but the
      // tile opens the quiz screen).
      expect(find.textContaining('Past tense'), findsOneWidget);
      expect(find.textContaining('food'), findsNothing);
      expect(find.byType(InkWell), findsOneWidget);
    },
  );

  testWidgets('the recommended tile stays hidden with no weak area', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weakAreasProvider.overrideWith(
            (ref) async => parseWeakAreas({'weakAreas': []}),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RecommendedTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a vocabulary-only list shows no tile', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weakAreasProvider.overrideWith(
            (ref) async => parseWeakAreas({
              'weakAreas': [
                {'topic': 'food', 'category': 'vocabulary', 'score': 0.2},
              ],
            }),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RecommendedTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InkWell), findsNothing);
  });
}
