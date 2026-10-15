import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/edit/privacy_edit.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

Future<void> _pumpPrivacy(WidgetTester tester, Community user) async {
  tester.view.physicalSize = const Size(1200, 5000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      // Resolves after the screen's first frame, like a cold userProvider.
      userProvider.overrideWith((ref) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return user;
      }),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: ProfilePrivacy(),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

// Visibility toggles in on-screen order: country/region, city, age, ...
bool _switchValue(WidgetTester tester, int index) =>
    tester.widgetList<Switch>(find.byType(Switch)).elementAt(index).value;

void main() {
  testWidgets('stored settings load even when the user is still loading',
      (tester) async {
    await _pumpPrivacy(
      tester,
      Community.fromJson({
        '_id': 'u1',
        'name': 'Ana',
        'email': 'a@b.c',
        'privacySettings': {'showAge': false},
      }),
    );

    expect(_switchValue(tester, 2), isFalse); // Show Age
    expect(find.text('You have unsaved changes'), findsNothing);
  });

  testWidgets('no stored settings: defaults are the unsaved-changes baseline',
      (tester) async {
    await _pumpPrivacy(
      tester,
      Community.fromJson({'_id': 'u1', 'name': 'Ana', 'email': 'a@b.c'}),
    );

    expect(_switchValue(tester, 2), isTrue);
    expect(find.text('You have unsaved changes'), findsNothing);

    await tester.tap(find.byType(Switch).at(2));
    await tester.pumpAndSettle();
    expect(find.text('You have unsaved changes'), findsOneWidget);

    await tester.tap(find.byType(Switch).at(2));
    await tester.pumpAndSettle();
    expect(find.text('You have unsaved changes'), findsNothing);
  });
}
