import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

void main() {
  testWidgets('shows the reconnect overlay, then the caller outcome banner', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    await h.startOutgoing();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActiveCallScreen(call: h.manager.currentCall!),
      ),
    ));
    await tester.pump();

    h.liveKit.onReconnecting!();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Reconnecting...'), findsWidgets);

    await h.state('missed', outcome: 'no_answer');
    await tester.pump();
    expect(find.text('Voice call · No answer'), findsWidgets);

    // Let CallManager's 1.5 s close timer run so no timer is left pending.
    await tester.pump(const Duration(seconds: 2));
  });
}
