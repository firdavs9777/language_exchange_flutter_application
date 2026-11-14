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

  test('request: no arguments is practice in English', () {
    final r = pronunciationRequest(currentText: 'Hello', ownSentence: false);
    expect(r.source, 'practice');
    expect(r.language, 'en');
  });

  test('request: own sentence before languages load uses the caller language',
      () {
    final r = pronunciationRequest(
      initialText: 'Bonjour',
      initialLanguage: 'fr-CA',
      ownSentence: true,
      currentText: 'Bonjour',
    );
    expect(r.source, 'own');
    expect(r.language, 'fr');
  });

  test('request: an edited own sentence is practice', () {
    final r = pronunciationRequest(
      initialText: 'Bonjour',
      initialLanguage: 'fr',
      ownSentence: true,
      currentText: 'Salut',
    );
    expect(r.source, 'practice');
    expect(r.language, 'fr');
  });

  test('request: a selected language wins over the caller language', () {
    final r = pronunciationRequest(
      initialLanguage: 'fr',
      ownSentence: false,
      currentText: 'x',
      selectedLanguageCode: 'ko',
    );
    expect(r.language, 'ko');
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
