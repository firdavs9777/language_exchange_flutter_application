import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/notification_api_client.dart';

/// Pushes are rendered in the server's preferredLocale, which came only from
/// the device locale: a user on an English phone who picked Korean in the
/// app kept getting English pushes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Object?> sentLocale(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({'token': 'jwt', ...prefs});
    Object? locale;
    await http.runWithClient(
      () => NotificationApiClient().registerToken('fcm', 'ios', 'device-1'),
      () => MockClient((req) async {
        locale = (jsonDecode(req.body) as Map)['deviceLocale'];
        return http.Response(jsonEncode({'success': true}), 200);
      }),
    );
    return locale;
  }

  test('the language picked in the app is sent', () async {
    expect(await sentLocale({'app_language': 'ko'}), 'ko');
    expect(await sentLocale({'app_language': 'zh_TW'}), 'zh_TW');
  });

  test('never picked: the device locale is sent', () async {
    final locale = await sentLocale({});
    expect(locale, isA<String>());
    expect(locale, isNot('ko'));
  });
}
