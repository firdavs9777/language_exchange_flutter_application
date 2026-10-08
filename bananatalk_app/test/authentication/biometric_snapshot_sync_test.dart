import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/authentication/biometric/biometric_service.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_session.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

class _FakeStorage implements BiometricTokenStorage {
  String? value;
  @override
  Future<void> clear() async => value = null;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> save(String token) async => value = token;
}

String _snap(String user, String rt) => jsonEncode(BiometricAuthState(
      token: 'old-$user',
      refreshToken: rt,
      userId: user,
      userName: 'Name $user',
    ).toJson());

BiometricAuthState _read(_FakeStorage s) =>
    BiometricAuthState.tryParse(s.value!)!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('syncBiometricSnapshotAfterSignIn', () {
    test('same user signs in again: snapshot takes the new tokens', () async {
      SharedPreferences.setMockInitialValues({'biometric_enabled': true});
      final s = _FakeStorage()..value = _snap('A', 'rt-old');
      await syncBiometricSnapshotAfterSignIn(
          userId: 'A', token: 'new', refreshToken: 'rt-new', storage: s);
      expect(_read(s).refreshToken, 'rt-new');
      expect(_read(s).token, 'new');
      expect(_read(s).userName, 'Name A');
    });

    test("a different user's password login wipes A's snapshot", () async {
      SharedPreferences.setMockInitialValues({
        'biometric_enabled': true,
        'biometric_user_name_display': 'Name A',
      });
      final s = _FakeStorage()..value = _snap('A', 'rt-A');
      await syncBiometricSnapshotAfterSignIn(
          userId: 'B', token: 't', refreshToken: 'rt-B', storage: s);
      expect(s.value, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('biometric_enabled'), isNull);
      expect(prefs.getString('biometric_user_name_display'), isNull);
    });

    test('biometrics off: untouched', () async {
      SharedPreferences.setMockInitialValues({});
      final s = _FakeStorage()..value = _snap('A', 'rt-A');
      await syncBiometricSnapshotAfterSignIn(
          userId: 'B', token: 't', refreshToken: 'rt-B', storage: s);
      expect(_read(s).userId, 'A');
    });
  });

  test('rotateBiometricSnapshot follows a rotated refresh token', () async {
    SharedPreferences.setMockInitialValues({'biometric_enabled': true});
    final s = _FakeStorage()..value = _snap('A', 'rt-1');
    await rotateBiometricSnapshot(
        oldRefreshToken: 'rt-1', newRefreshToken: 'rt-2', storage: s);
    expect(_read(s).refreshToken, 'rt-2');
    // A rotation of some other token leaves the snapshot alone.
    await rotateBiometricSnapshot(
        oldRefreshToken: 'rt-x', newRefreshToken: 'rt-3', storage: s);
    expect(_read(s).refreshToken, 'rt-2');
  });

  test('password change stores the new refresh token and updates the snapshot',
      () async {
    // THE BUG: changePassword kept only the new access token; the server had
    // just revoked every refresh token, so the next expiry logged the user
    // out -- and the biometric snapshot held a dead token too.
    SharedPreferences.setMockInitialValues({
      'token': 'old',
      'refreshToken': 'rt-old',
      'userId': 'A',
      'biometric_enabled': true,
    });
    final s = _FakeStorage()..value = _snap('A', 'rt-old');
    final auth = AuthService()
      ..biometricStorageForTest = s
      ..userId = 'A';
    await http.runWithClient(
      () => auth.changePassword(
          currentPassword: 'Old1pass', newPassword: 'New1pass'),
      () => MockClient((_) async => http.Response(
          jsonEncode({'token': 'fresh', 'refreshToken': 'rt-fresh'}), 200)),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token'), 'fresh');
    expect(prefs.getString('refreshToken'), 'rt-fresh');
    expect(_read(s).refreshToken, 'rt-fresh');
  });
}
