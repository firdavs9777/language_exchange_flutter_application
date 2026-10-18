import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/sections/vocab_packs_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vocabulary packs have their own card on the hub (2026-10-18).
void main() {
  for (final locale in const [Locale('en'), Locale('de'), Locale('ru')]) {
    testWidgets('packs card shows its pitch and button, no overflow at 320 ($locale)', (t) async {
      t.view.physicalSize = const Size(320, 700);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: VocabPacksCard()),
        ),
      ));
      await t.pump();
      expect(find.byKey(const Key('study-hub-vocab-packs')), findsOneWidget);
      expect(t.takeException(), isNull);
      if (locale.languageCode == 'en') {
        expect(find.text('Browse packs'), findsOneWidget);
      }
    });
  }
}
