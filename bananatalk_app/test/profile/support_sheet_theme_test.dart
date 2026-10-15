import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/support/support_sheet.dart';

Color? _sheetColor(WidgetTester t) {
  final box = t.widget<Container>(find.descendant(
    of: find.byType(SupportSheet),
    matching: find.byType(Container),
  ).first);
  return (box.decoration as BoxDecoration).color;
}

void main() {
  Future<void> pump(WidgetTester t,
      {required ThemeMode mode, required Brightness system}) async {
    t.platformDispatcher.platformBrightnessTestValue = system;
    addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: mode,
      home: const Scaffold(body: SingleChildScrollView(child: SupportSheet())),
    ));
  }

  testWidgets('dark app theme on a light phone renders dark', (t) async {
    await pump(t, mode: ThemeMode.dark, system: Brightness.light);
    expect(_sheetColor(t), isNot(Colors.white));
  });

  testWidgets('light app theme on a dark phone renders light', (t) async {
    await pump(t, mode: ThemeMode.light, system: Brightness.dark);
    expect(_sheetColor(t), Colors.white);
  });
}
