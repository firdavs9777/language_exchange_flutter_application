import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/voice_recorder/voice_recorder_mobile.dart';

const _channel = MethodChannel('flutter.baseflow.com/permissions/methods');

// permission_handler's PermissionStatus indices.
const _denied = 0;
const _permanentlyDenied = 4;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('en'));

  late List<String> calls;

  void mockPermission(int status) {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'requestPermissions':
          final ids = (call.arguments as List).cast<int>();
          return {for (final id in ids) id: status};
        case 'checkPermissionStatus':
          return status;
        case 'openAppSettings':
          return true;
      }
      return null;
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  Future<void> pump(WidgetTester tester, {VoidCallback? onCancel}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: VoiceRecorderWidget(onCancel: onCancel)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('permanently denied mic offers Open Settings and stays open',
      (tester) async {
    mockPermission(_permanentlyDenied);
    var cancels = 0;
    await pump(tester, onCancel: () => cancels++);

    expect(find.text(l10n.aiMicPermissionDeniedSettings), findsOneWidget);
    expect(find.text(l10n.openSettings), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(cancels, 0, reason: 'no auto-close while the user can act');

    await tester.tap(find.text(l10n.openSettings));
    await tester.pump();
    expect(calls, contains('openAppSettings'));
    expect(cancels, 1);
  });

  testWidgets('a plain denial shows the localized message and closes',
      (tester) async {
    mockPermission(_denied);
    var cancels = 0;
    await pump(tester, onCancel: () => cancels++);

    expect(find.text(l10n.micPermissionNeeded), findsOneWidget);
    expect(find.text(l10n.openSettings), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(cancels, 1);
  });
}
