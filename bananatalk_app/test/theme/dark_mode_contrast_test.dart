import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';
import 'package:bananatalk_app/widgets/learning/vocabulary_card.dart';

/// Dark mode on AI Study > Review (2026-10-17): the flashcard was hardcoded
/// white, so the word (theme text = white) was white on white; and the dark
/// theme had no button theme, so a teal button drew teal text.
VocabularyItem _item() => VocabularyItem(
      id: 'v1',
      userId: 'u1',
      word: 'hola',
      translation: 'hello',
      language: 'es',
      exampleSentence: 'Hola, amigo',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Widget _dark(Widget child) => MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

Color _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

Color _boxColor(WidgetTester tester, Finder inside) {
  final box = tester.widgetList<Container>(
      find.ancestor(of: inside, matching: find.byType(Container)))
      .firstWhere((c) => c.decoration is BoxDecoration &&
          (c.decoration as BoxDecoration).color != null);
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  testWidgets('flashcard front: the word does not match its card in dark mode',
      (tester) async {
    await tester.pumpWidget(_dark(
        VocabularyFlashcard(item: _item(), isFlipped: false, onFlip: () {})));
    final text = _textColor(tester, 'hola');
    final card = _boxColor(tester, find.text('hola'));
    expect(text, isNot(card));
    expect(card, isNot(Colors.white));
  });

  testWidgets('flashcard back: the example does not match its box in dark mode',
      (tester) async {
    await tester.pumpWidget(_dark(
        VocabularyFlashcard(item: _item(), isFlipped: true, onFlip: () {})));
    final text = _textColor(tester, 'Hola, amigo');
    final box = _boxColor(tester, find.text('Hola, amigo'));
    expect(text, isNot(box));
    expect(box, isNot(Colors.white));
  });

  testWidgets('a teal button that sets only its background gets white text in dark mode',
      (tester) async {
    await tester.pumpWidget(_dark(ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
      child: const Text('Done'),
    )));
    final style = DefaultTextStyle.of(tester.element(find.text('Done'))).style;
    expect(style.color, AppColors.white);
  });
}
