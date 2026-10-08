import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

Future<Map<String, dynamic>> _loginAgainst(MockClient server) =>
    http.runWithClient(
      () => AuthService().login(email: 'a@b.co', password: 'pw'),
      () => server,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('423 lockout keeps the server message with its minutes', () async {
    // THE BUG: the server sends no lockUntil, so the app replaced
    // "...try again in 14 minutes." with a generic sentence.
    final r = await _loginAgainst(MockClient((_) async => http.Response(
        jsonEncode({
          'success': false,
          'message': 'Account is locked. Please try again in 14 minutes.',
          'code': 'ACCOUNT_LOCKED',
        }),
        423)));
    expect(r['success'], isFalse);
    expect(r['isLocked'], isTrue);
    expect(r['message'], 'Account is locked. Please try again in 14 minutes.');
  });

  test('email login on a Google/Apple-only account shows the server text',
      () async {
    const msg = 'This account uses Google sign-in. Continue with Google.';
    final r = await _loginAgainst(MockClient((_) async =>
        http.Response(jsonEncode({'success': false, 'message': msg}), 400)));
    expect(r['message'], msg);
  });

  test('a transport failure is flagged, with no raw exception text', () async {
    final r = await _loginAgainst(MockClient(
        (_) async => throw http.ClientException('Connection reset by peer')));
    expect(r['success'], isFalse);
    expect(r['isNetworkError'], isTrue);
    expect(r['message'].toString().contains('ClientException'), isFalse);
  });
}
