import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/screens/incoming_call_screen.dart';
import 'package:bananatalk_app/services/call/call_routes.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

void main() {
  late GlobalKey<NavigatorState> navKey;
  late CallHarness h;

  Future<void> pumpApp(WidgetTester tester) async {
    navKey = GlobalKey<NavigatorState>();
    h = CallHarness(
      closeCallScreens: () => navKey.currentState?.popUntil((r) => !CallRoutes.isCallRoute(r.settings.name)),
      openIncoming: (c) => navKey.currentState?.push(CallRoutes.incomingRoute(c)),
    );
    CallManager.debugSetInstance(h.manager);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('home')),
    ));
  }

  testWidgets('closes when call:state reports the call ended elsewhere', (tester) async {
    await pumpApp(tester);
    await h.ringIncoming();
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallScreen), findsOneWidget);
    await h.state('missed', outcome: 'cancelled');
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('safety net: closes itself after 50 s if nothing ended it', (tester) async {
    await pumpApp(tester);
    await h.ringIncoming();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 49));
    expect(find.byType(IncomingCallScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallScreen), findsNothing);
    expect(h.finishes.single.outcome, CallOutcome.noAnswer);
  });

  testWidgets('a screen for a call CallManager no longer has still removes itself at 50 s', (tester) async {
    await pumpApp(tester);
    final orphan = CallModel(
      callId: 'old', userId: 'u', userName: 'Ada', callType: CallType.audio,
      direction: CallDirection.incoming, startTime: DateTime.now(),
    );
    navKey.currentState!.push(CallRoutes.incomingRoute(orphan));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 51));
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallScreen), findsNothing);
  });

  testWidgets('an accept in flight past 50 s keeps the screen and the call', (tester) async {
    await pumpApp(tester);
    await h.ringIncoming();
    await tester.pumpAndSettle();
    h.api.acceptGate = Completer<void>();
    await tester.tap(find.byIcon(Icons.call));
    await tester.pump();
    await tester.pump(const Duration(seconds: 55));
    expect(find.byType(IncomingCallScreen), findsOneWidget);
    expect(h.finishes, isEmpty);
    h.api.acceptGate!.complete();
    await tester.pump();
    expect(h.finishes, isEmpty);
    expect(h.manager.currentCall, isNotNull);
  });

  testWidgets('Decline declines on the server and closes', (tester) async {
    await pumpApp(tester);
    await h.ringIncoming();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pumpAndSettle();
    expect(h.api.calls, contains('decline:call-1'));
    expect(find.byType(IncomingCallScreen), findsNothing);
  });
}
