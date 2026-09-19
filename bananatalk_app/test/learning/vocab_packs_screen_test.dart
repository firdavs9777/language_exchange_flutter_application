import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/vocab_pack_model.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocab_packs_screen.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocab_packs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

VocabPackSummary _pack(String level, String topic) => VocabPackSummary(
      id: '$level-$topic',
      level: level,
      topic: topic,
      language: 'English',
      wordCount: 20,
      exerciseCount: 8,
    );

/// One pack per level the server actually serves.
final _packs = [
  _pack('beginner', 'Around the house'),
  _pack('intermediate', 'Work and careers'),
  _pack('advanced', 'Idioms and fixed expressions'),
  _pack('proficiency', 'Shades of certainty'),
];

Widget _host() => ProviderScope(
      overrides: [
        vocabPacksProvider.overrideWith((ref, String? level) async =>
            level == null
                ? _packs
                : _packs.where((p) => p.level == level).toList()),
      ],
      // The screen's title and empty state are localized, so the delegates
      // are load-bearing here rather than decoration.
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VocabPacksScreen(),
      ),
    );

void main() {
  testWidgets('a filter chip exists for every level the server serves',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    // Keyed, because a level name also appears on every pack card's badge.
    for (final pair in [
      ('all', 'All'),
      ('beginner', 'Beginner'),
      ('intermediate', 'Intermediate'),
      ('advanced', 'Advanced'),
      ('proficiency', 'Proficiency'),
    ]) {
      final chip = find.byKey(Key('level-chip-${pair.$1}'));
      expect(chip, findsOneWidget, reason: 'no "${pair.$2}" chip');
      expect(find.descendant(of: chip, matching: find.text(pair.$2)),
          findsOneWidget);
    }
  });

  testWidgets('every level is reachable through its own chip', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    // Beginner and proficiency packs both shipped after this row was written;
    // without a chip each, a learner could only reach them through "All".
    for (final pair in [
      ('beginner', 'Around the house'),
      ('proficiency', 'Shades of certainty'),
    ]) {
      await tester.tap(find.byKey(Key('level-chip-${pair.$1}')));
      await tester.pumpAndSettle();
      expect(find.text(pair.$2), findsOneWidget);
      expect(find.text('Work and careers'), findsNothing);
    }
  });
}
