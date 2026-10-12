import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/account_suspended_screen.dart';
import 'package:bananatalk_app/services/api_client.dart';

Future<String?> _suspendedWith(Map<String, dynamic> body) async {
  final client = ApiClient();
  String? got = 'unset';
  client.onAccountSuspended = (r) => got = r;
  await http.runWithClient(
    () => client.get('probe/suspended-${body.hashCode}'),
    () => MockClient((_) async => http.Response(jsonEncode(body), 403)),
  );
  client.onAccountSuspended = null;
  return got;
}

Widget _screen(String? reason) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AccountSuspendedScreen(reason: reason),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 't'});
    ApiClient().clearTokenCache();
  });

  test('the callback gets banReason, not the English message', () async {
    // Real backend shape (middleware/auth.js bannedError + error.js extra).
    expect(
      await _suspendedWith({
        'success': false,
        'error': 'Your account has been suspended. Reason: spam',
        'code': 'ACCOUNT_BANNED',
        'banReason': 'spam',
      }),
      'spam',
    );
    expect(
      await _suspendedWith({
        'success': false,
        'error': 'Your account has been suspended.',
        'code': 'ACCOUNT_BANNED',
        'banReason': null,
      }),
      isNull,
    );
    expect(
      await _suspendedWith({'error': 'Your account has been suspended.'}),
      isNull,
    );
  });

  test('rollout fallback: no banReason key, old message suffix is used',
      () async {
    expect(
      await _suspendedWith(
          {'error': 'Your account has been suspended. Reason: abuse'}),
      'abuse',
    );
  });

  testWidgets('a reason is shown under the localized label', (t) async {
    await t.pumpWidget(_screen('spam'));
    expect(find.text('Reason: spam'), findsOneWidget);
  });

  testWidgets('no reason: the generic line', (t) async {
    await t.pumpWidget(_screen(null));
    expect(find.text('Your account is no longer accessible.'), findsOneWidget);
    await t.pumpWidget(_screen('  '));
    expect(find.text('Your account is no longer accessible.'), findsOneWidget);
  });
}
