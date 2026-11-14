import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/pages/ai/pronunciation/pronunciation_screen.dart';

Widget _host(PronunciationScreen screen) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    );

Language _lang(String code) =>
    Language(id: code, code: code, name: code, nativeName: code);

void main() {
  testWidgets('with no arguments the first sample sentence is shown',
      (tester) async {
    await tester.pumpWidget(_host(const PronunciationScreen()));
    await tester.pump();
    expect(find.text('Hello, how are you today?'), findsWidgets);
  });

  testWidgets('initialText is shown in the field', (tester) async {
    await tester.pumpWidget(
      _host(const PronunciationScreen(initialText: 'Je voudrais un café')),
    );
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, 'Je voudrais un café');
  });

  testWidgets('an unknown initialLanguage keeps the default language',
      (tester) async {
    await tester.pumpWidget(
      _host(const PronunciationScreen(initialLanguage: 'xx')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('language choice matches on the base code only when listed', () {
    final list = [_lang('en'), _lang('fr')];
    expect(languageForInitialCode(list, 'fr-CA')?.code, 'fr');
    expect(languageForInitialCode(list, 'xx'), isNull);
    expect(languageForInitialCode(list, null), isNull);
  });

  test('source is own only while the text is still the given sentence', () {
    expect(
      pronunciationSource(
          initialText: 'Hi there', currentText: ' Hi there ', ownSentence: true),
      'own',
    );
    expect(
      pronunciationSource(
          initialText: 'Hi there', currentText: 'Hi', ownSentence: true),
      'practice',
    );
    expect(
      pronunciationSource(
          initialText: 'Hi there', currentText: 'Hi there', ownSentence: false),
      'practice',
    );
    expect(
      pronunciationSource(currentText: 'Hi', ownSentence: true),
      'practice',
    );
  });
}
