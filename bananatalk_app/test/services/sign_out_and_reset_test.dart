import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/session_reset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('leaving an unfinished profile gate ends the session for good',
      () async {
    // THE BUG: splash sent an incomplete profile to /login with the session
    // still stored, so the next launch restored it into the same gate.
    SharedPreferences.setMockInitialValues({
      'token': 'jwt',
      'refreshToken': 'rt',
      'userId': 'u1',
      'app_theme': 'dark',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final auth = container.read(authServiceProvider)
      ..token = 'jwt'
      ..refreshToken = 'rt';

    var loggedOutOnServer = false;
    await http.runWithClient(
      () => signOutAndReset(auth, container: container),
      () => MockClient((req) async {
        if (req.url.path.endsWith('logout')) loggedOutOnServer = true;
        return http.Response(jsonEncode({'success': true}), 200);
      }),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(loggedOutOnServer, isTrue);
    expect(prefs.getString('token'), isNull,
        reason: 'no session left for the next launch to restore');
    expect(prefs.getString('refreshToken'), isNull);
    expect(prefs.getString('app_theme'), 'dark');
  });
}
