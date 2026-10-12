import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
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

  Future<void> pumpScreen(WidgetTester tester, CallHarness h) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActiveCallScreen(call: h.manager.currentCall!),
      ),
    ));
    await tester.pump();
  }

  testWidgets('voice call: Camera turns the camera on and the screen becomes a video call', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    await pumpScreen(tester, h);
    await tester.tap(find.byIcon(Icons.videocam_rounded));
    await tester.pump();
    expect(h.api.calls, contains('upgrade:call-1'));
    expect(h.liveKit.cameraCalls, [true]);
    expect(find.text('Camera'), findsNothing, reason: 'video controls replace the voice ones');
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('peer upgraded: call:state type video switches this screen, camera stays off', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    await pumpScreen(tester, h);
    await h.manager.handleSocketEvent('call:state', {'callId': 'call-1', 'status': 'active', 'type': 'video'});
    await tester.pump();
    expect(find.text('Camera'), findsNothing);
    expect(h.liveKit.cameraCalls, isEmpty, reason: 'the callee never auto-enables their camera');
    expect(find.text('Video On'), findsOneWidget, reason: 'local camera is off until tapped');
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Camera is not offered until the call is connected', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    await h.startOutgoing();
    await pumpScreen(tester, h);
    expect(find.text('Camera'), findsNothing);
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a refused upgrade shows feedback and stays a voice call', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    h.api.upgradeResult = const CallApiResult(ok: false, statusCode: 500);
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    await pumpScreen(tester, h);
    await tester.tap(find.byIcon(Icons.videocam_rounded));
    await tester.pump();
    await tester.pump();
    expect(find.text("Couldn't turn the camera on"), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget, reason: 'rolled back to a voice call');
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a type change after the screen is gone is harmless', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    await pumpScreen(tester, h);
    await tester.pumpWidget(const SizedBox());
    expect(h.manager.onCallTypeChanged, isNull);
    await h.manager.handleSocketEvent('call:state', {'callId': 'call-1', 'status': 'active', 'type': 'video'});
    await tester.pump();
    expect(tester.takeException(), isNull);
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('video call, camera off: toggling on posts no upgrade and stays in sync', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    await h.startOutgoing(type: CallType.video);
    await h.state('active');
    h.liveKit.onPeerConnected!();
    await pumpScreen(tester, h);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.videocam));
    await tester.pump();
    expect(find.text('Video On'), findsOneWidget);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.videocam_off));
    await tester.pump();
    await tester.pump();
    expect(h.api.calls.where((c) => c.startsWith('upgrade')), isEmpty);
    expect(h.liveKit.cameraCalls, [false, true]);
    expect(find.text('Video Off'), findsOneWidget);
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('failed upgrade on a voice call leaves camera and UI off', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    h.api.upgradeResult = const CallApiResult(ok: false, statusCode: 500);
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    await pumpScreen(tester, h);
    await tester.tap(find.byIcon(Icons.videocam_rounded));
    await tester.pump();
    await tester.pump();
    expect(h.liveKit.cameraCalls.last, isFalse);
    expect(h.manager.isVideoEnabled, isFalse);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Video On'), findsNothing);
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('permission denied: the manager error only, no second snack', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    final errors = <String>[];
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    await pumpScreen(tester, h);
    h.manager.onCallError = errors.add;
    h.platform.permissionsGranted = false;
    await tester.tap(find.byIcon(Icons.videocam_rounded));
    await tester.pump();
    await tester.pump();
    expect(errors, ['DENIED:test']);
    expect(find.text("Couldn't turn the camera on"), findsNothing);
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('dispose leaves a newer screen\'s onCallTypeChanged alone', (tester) async {
    final h = CallHarness();
    CallManager.debugSetInstance(h.manager);
    await h.startOutgoing();
    await h.state('active');
    h.liveKit.onPeerConnected!();
    await pumpScreen(tester, h);
    expect(h.manager.onCallTypeChanged, isNotNull);
    void newer(CallType _) {}
    h.manager.onCallTypeChanged = newer;
    await tester.pumpWidget(const SizedBox());
    expect(identical(h.manager.onCallTypeChanged, newer), isTrue);
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });
}
