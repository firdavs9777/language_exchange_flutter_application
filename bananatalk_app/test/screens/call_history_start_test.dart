import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/screens/call_history_screen.dart';
import 'package:bananatalk_app/services/call/call_api.dart';
import 'package:bananatalk_app/services/call_manager.dart';

import '../helpers/call_fakes.dart';

const _limitMessage =
    'You have started the most conversations you can today. Watch an ad for one more, or go VIP to start as many as you want.';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late CallManager original;

  setUp(() => original = CallManager());
  tearDown(() => CallManager.debugSetInstance(original));

  Future<(CallHarness, List<CallModel>)> pumpCallsList(
    WidgetTester tester,
    void Function(CallHarness h) arrange,
  ) async {
    final h = CallHarness();
    arrange(h);
    CallManager.debugSetInstance(h.manager);
    final notifier = CallNotifier();
    final opened = <CallModel>[];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => startCallFromCallsList(
              context,
              notifier,
              userId: 'u-callee',
              userName: 'Bo',
              type: CallType.audio,
              openActive: opened.add,
            ),
            child: const Text('call'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('call'));
    await tester.pumpAndSettle();
    return (h, opened);
  }

  testWidgets('403 CONVERSATION_START_LIMIT: the server message is shown once', (tester) async {
    final (h, opened) = await pumpCallsList(tester, (h) {
      h.api.initiateResult = const CallApiResult(
        ok: false,
        statusCode: 403,
        errorCode: 'CONVERSATION_START_LIMIT',
        error: _limitMessage,
      );
    });
    expect(find.text(_limitMessage), findsOneWidget);
    expect(opened, isEmpty);
    expect(h.manager.currentCall, isNull);
  });

  testWidgets('callee busy: the busy label is shown', (tester) async {
    final (_, opened) = await pumpCallsList(tester, (h) {
      h.api.initiateResult =
          const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALLEE_BUSY');
    });
    expect(find.text(en.callLabelBusy('Bo')), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('caller already busy on the server: a call-failed message', (tester) async {
    await pumpCallsList(tester, (h) {
      h.api.initiateResult =
          const CallApiResult(ok: false, statusCode: 409, errorCode: 'CALLER_BUSY');
    });
    expect(find.text(en.callFailed), findsOneWidget);
  });

  testWidgets('permission denied: the message without its prefix', (tester) async {
    await pumpCallsList(tester, (h) => h.platform.permissionsGranted = false);
    expect(find.text('test'), findsOneWidget);
  });

  testWidgets('started: the active call screen opens, no message', (tester) async {
    final (h, opened) = await pumpCallsList(tester, (_) {});
    expect(opened.single.callId, 'call-1');
    expect(find.byType(SnackBar), findsNothing);
    await h.manager.endCall(); // cancels the 50 s ring safety timer
  });
}
