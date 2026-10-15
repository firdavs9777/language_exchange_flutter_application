import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/services/purchase_restorer.dart';
import 'package:bananatalk_app/widgets/restore_purchases_button.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  final en = AppLocalizationsEn();

  testWidgets('shows "Restore Purchases"', (tester) async {
    await tester.pumpWidget(_wrap(RestorePurchasesButton(
      onRestore: () async => RestoreOutcome.restored,
    )));
    expect(find.text(en.restorePurchases), findsOneWidget);
  });

  testWidgets('shows progress and ignores taps while restoring',
      (tester) async {
    final gate = Completer<RestoreOutcome>();
    var calls = 0;
    await tester.pumpWidget(_wrap(RestorePurchasesButton(
      onRestore: () {
        calls++;
        return gate.future;
      },
    )));
    await tester.tap(find.byKey(const ValueKey('restore-purchases')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(en.restorePurchases), findsNothing);

    await tester.tap(find.byKey(const ValueKey('restore-purchases')));
    await tester.pump();
    expect(calls, 1);

    gate.complete(RestoreOutcome.nothingToRestore);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(en.restorePurchases), findsOneWidget);
  });

  final cases = <RestoreOutcome, String>{
    RestoreOutcome.restored: en.restorePurchasesSuccess,
    RestoreOutcome.alreadyActive: en.restorePurchasesAlreadyActive,
    RestoreOutcome.nothingToRestore: en.restorePurchasesNothing,
    RestoreOutcome.failed: en.restorePurchasesFailed,
  };
  for (final entry in cases.entries) {
    testWidgets('${entry.key.name} -> its own localized message',
        (tester) async {
      await tester.pumpWidget(_wrap(RestorePurchasesButton(
        onRestore: () async => entry.key,
      )));
      await tester.tap(find.byKey(const ValueKey('restore-purchases')));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    });
  }

  testWidgets('a throwing restore is reported as failed, not a crash',
      (tester) async {
    await tester.pumpWidget(_wrap(RestorePurchasesButton(
      onRestore: () async => throw Exception('boom'),
    )));
    await tester.tap(find.byKey(const ValueKey('restore-purchases')));
    await tester.pumpAndSettle();
    expect(find.text(en.restorePurchasesFailed), findsOneWidget);
  });

  test('the VIP plans screen and VIP status screen offer Restore Purchases',
      () {
    // App Store guideline 3.1.1: a visible restore mechanism where
    // auto-renewing subscriptions are sold.
    for (final path in [
      'lib/pages/vip/vip_plans_screen.dart',
      'lib/pages/vip/vip_status_screen.dart',
    ]) {
      expect(File(path).readAsStringSync(), contains('RestorePurchasesButton('),
          reason: path);
    }
  });
}
