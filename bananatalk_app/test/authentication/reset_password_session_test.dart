import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // THE BUG: a successful reset stored the returned session (and connected
  // the socket) while the screen said "Please login with your new password"
  // and routed to /login -- signed in on the login screen, and the next cold
  // start went straight into the app.
  test('a successful reset leaves no stored session behind', () async {
    SharedPreferences.setMockInitialValues({
      'token': 'stale',
      'refreshToken': 'stale-rt',
      'userId': 'u1',
    });
    final auth = AuthService();
    final r = await http.runWithClient(
      () => auth.resetPassword(
          email: 'a@b.co', code: '123456', newPassword: 'NewPassw0rd'),
      () => MockClient((_) async => http.Response(
          jsonEncode({
            'success': true,
            'token': 'fresh',
            'refreshToken': 'fresh-rt',
            'user': {'_id': 'u1'},
          }),
          200)),
    );
    expect(r['success'], isTrue);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.token, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token'), isNull);
    expect(prefs.getString('refreshToken'), isNull);
    expect(prefs.getString('userId'), isNull);
  });
}
