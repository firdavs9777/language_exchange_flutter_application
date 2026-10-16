import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/router/app_router.dart' show callOverlayNavigatorKey;
import 'package:bananatalk_app/services/call/call_launcher.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

/// In-call errors (audit #16): one app-level presenter on the overlay
/// navigator, so a call accepted from the lock screen or started from the
/// Calls list shows its error even when no chat screen is open.
void main() {
  late CallManager original;

  setUp(() => original = CallManager());
  tearDown(() => CallManager.debugSetInstance(original));

  Future<void> pumpApp(WidgetTester tester, Widget home) => tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
          builder: (context, child) => Navigator(
            key: callOverlayNavigatorKey,
            onDidRemovePage: (_) {},
            pages: [MaterialPage(child: child ?? const SizedBox())],
          ),
        ),
      ));

  testWidgets('an accept that fails with no chat open shows its error once', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    h.manager.onCallError = CallLauncher.showCallErrorOnOverlay;
    await pumpApp(tester, const Scaffold(body: Text('calls list')));

    h.platform.permissionsGranted = false;
    await h.ringIncoming();
    await h.manager.acceptCall();
    await tester.pump();

    expect(find.text('test'), findsOneWidget, reason: 'the DENIED: message without its prefix');
  });

  testWidgets('"Connection lost" and connect failures are in the app language', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => Navigator(
        key: callOverlayNavigatorKey,
        onDidRemovePage: (_) {},
        pages: [MaterialPage(child: child ?? const SizedBox())],
      ),
      home: const SizedBox(),
    ));
    final de = lookupAppLocalizations(const Locale('de'));
    final deps = CallManagerDeps.production();
    expect(deps.connectionLostMessage(), de.callConnectionLost);
    expect(deps.connectFailedMessage(), de.callConnectionFailed);
    expect(deps.callFailedMessage(), de.callFailed);
  });
}
