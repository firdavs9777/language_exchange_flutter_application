import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';
import 'package:bananatalk_app/services/session_prefs.dart';

class _FakeBiometricStorage implements BiometricTokenStorage {
  bool cleared = false;
  @override
  Future<void> clear() async => cleared = true;
  @override
  Future<String?> read() async => null;
  @override
  Future<void> save(String token) async {}
}

void main() {
  const userState = <String, Object>{
    'token': 'jwt',
    'refreshToken': 'rt',
    'userId': 'u1',
    'fcm_token': 'fcm',
    'termsAcceptedLocally': true,
    'user_native_language': 'Korean',
    'chat_theme_abc': 'ocean',
    'chat_draft_c1': 'hi',
    'registrationProgress': '{}',
    'mutedMoments': <String>['x'],
    'qh_snapshot': '{}',
    'tutor/me': '{}',
  };
  const deviceState = <String, Object>{
    'app_theme': 'dark',
    'app_language': 'ko',
    'rememberedEmail': 'a@b.c',
    'deviceId': 'dev-1',
    'video_muted': true,
  };

  test('logout keeps device-level keys and removes every user key', () async {
    // THE BUG: logout called prefs.clear(), losing theme, language and the
    // remembered email along with the session.
    SharedPreferences.setMockInitialValues({...userState, ...deviceState});
    final prefs = await SharedPreferences.getInstance();
    final storage = _FakeBiometricStorage();

    await clearUserSessionPrefs(prefs: prefs, biometricStorage: storage);

    for (final key in userState.keys) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expect(prefs.getString('app_theme'), 'dark');
    expect(prefs.getString('app_language'), 'ko');
    expect(prefs.getString('rememberedEmail'), 'a@b.c');
    expect(prefs.getString('deviceId'), 'dev-1');
    expect(prefs.getBool('video_muted'), isTrue);
  });

  test('an unclassified key is removed (allow-list fails safe)', () async {
    SharedPreferences.setMockInitialValues({'some_new_feature_cache': 'x'});
    final prefs = await SharedPreferences.getInstance();
    await clearUserScopedPrefs(prefs);
    expect(prefs.getKeys(), isEmpty);
  });

  test('biometric enabled: flag and keychain snapshot survive logout',
      () async {
    SharedPreferences.setMockInitialValues({
      'biometric_enabled': true,
      'biometric_user_name_display': 'Ann',
      'token': 'jwt',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = _FakeBiometricStorage();

    await clearUserSessionPrefs(prefs: prefs, biometricStorage: storage);

    expect(prefs.getBool('biometric_enabled'), isTrue);
    expect(prefs.getString('biometric_user_name_display'), 'Ann');
    expect(storage.cleared, isFalse);
  });

  test('biometric disabled: the keychain snapshot is deleted', () async {
    SharedPreferences.setMockInitialValues({'token': 'jwt'});
    final prefs = await SharedPreferences.getInstance();
    final storage = _FakeBiometricStorage();

    await clearUserSessionPrefs(prefs: prefs, biometricStorage: storage);

    expect(storage.cleared, isTrue);
  });
}
