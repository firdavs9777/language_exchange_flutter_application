import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/widgets/language_selection/language_picker_screen.dart';

/// The full-screen language picker hardcoded a white page and black text, so
/// in dark mode it opened as a bright white screen. It now takes the theme.
void main() {
  testWidgets('in dark mode the picker is dark, with readable names', (tester) async {
    final dark = ThemeData.dark(useMaterial3: true);
    await tester.pumpWidget(MaterialApp(
      theme: dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LanguagePickerScreen(languages: [
        Language(id: '1', code: 'ko', name: 'Korean', nativeName: '한국어'),
        Language(id: '2', code: 'es', name: 'Spanish', nativeName: 'Español'),
      ]),
    ));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, dark.scaffoldBackgroundColor);
    expect(scaffold.backgroundColor, isNot(Colors.white));

    final name = tester.widget<Text>(find.text('Korean').first);
    expect(name.style!.color, dark.colorScheme.onSurface);
  });
}
