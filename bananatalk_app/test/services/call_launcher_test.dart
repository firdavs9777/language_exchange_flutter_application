import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call/call_launcher.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

const _limitMessage =
    'You have started the most conversations you can today. Watch an ad for one more, or go VIP to start as many as you want.';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late CallManager original;

  setUp(() => original = CallManager());
  tearDown(() => CallManager.debugSetInstance(original));

  Future<List<String>> run(WidgetTester tester, CallHarness h) async {
    final opened = <String>[];
    CallManager.debugSetInstance(h.manager);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(builder: (context, ref, _) => TextButton(
            onPressed: () => CallLauncher.start(context, ref,
                userId: 'u2', userName: 'Bo', type: CallType.audio, openActive: (c) => opened.add(c.callId)),
            child: const Text('call'),
          )),
        ),
      ),
    ));
    await tester.tap(find.text('call'));
    await tester.pump();
    await tester.pump();
    return opened;
  }

  testWidgets('busy callee → "Bo was on another call", no call screen', (tester) async {
    final h = CallHarness();
    h.api.initiateResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALLEE_BUSY');
    final opened = await run(tester, h);
    expect(find.text('Bo was on another call'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('started → the active call screen opens for the new call', (tester) async {
    final h = CallHarness();
    final opened = await run(tester, h);
    expect(opened, ['call-1']);
    expect(find.byType(SnackBar), findsNothing);
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('403 CONVERSATION_START_LIMIT: the server message is shown once', (tester) async {
    final h = CallHarness();
    h.api.initiateResult = const CallApiResult(
      ok: false,
      statusCode: 403,
      errorCode: 'CONVERSATION_START_LIMIT',
      error: _limitMessage,
    );
    final opened = await run(tester, h);
    expect(find.text(_limitMessage), findsOneWidget);
    expect(opened, isEmpty);
    expect(h.manager.currentCall, isNull);
  });

  testWidgets('caller already busy on the server: a call-failed message', (tester) async {
    final h = CallHarness();
    h.api.initiateResult = const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALLER_BUSY');
    final opened = await run(tester, h);
    expect(find.text(en.callFailed), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('permission denied: the message without its prefix', (tester) async {
    final h = CallHarness();
    h.platform.permissionsGranted = false;
    final opened = await run(tester, h);
    expect(find.text('test'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('tapping call during a call does not open a second call screen', (tester) async {
    final h = CallHarness();
    final opened = await run(tester, h);
    expect(opened, ['call-1']);
    await tester.tap(find.text('call'));
    await tester.pump();
    await tester.pump();
    expect(opened, ['call-1'], reason: 'the second tap must not open another screen');
    expect(find.text(en.callFailed), findsOneWidget);
    await h.manager.endCall();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the screen\'s own error callback is put back after the start', (tester) async {
    final h = CallHarness();
    final screenErrors = <String>[];
    h.manager.onCallError = screenErrors.add;
    h.api.initiateResult = const CallApiResult(
      ok: false,
      statusCode: 403,
      errorCode: 'CONVERSATION_START_LIMIT',
      error: _limitMessage,
    );
    await run(tester, h);
    expect(find.text(_limitMessage), findsOneWidget);
    expect(screenErrors, isEmpty, reason: 'the start\'s own error is shown by the launcher only');
    h.manager.onCallError?.call('Connection lost');
    expect(screenErrors, ['Connection lost']);
  });
}
