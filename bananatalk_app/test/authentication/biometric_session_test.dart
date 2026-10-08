import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/authentication/biometric/biometric_service.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_session.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/service/endpoints.dart';

class FakeBiometricStorage implements BiometricTokenStorage {
  String? value;
  @override
  Future<void> clear() async => value = null;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> save(String token) async => value = token;
}

const _snapshot = BiometricAuthState(
  token: 'old-access',
  refreshToken: 'rt-A',
  userId: 'userA',
  userName: 'Ann',
);

http.Response _json(int status, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), status);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBiometricStorage storage;
  late AuthService auth;

  setUp(() {
    storage = FakeBiometricStorage()..value = jsonEncode(_snapshot.toJson());
    auth = AuthService()..biometricStorageForTest = storage;
  });

  group('logout', () {
    Future<Map<String, dynamic>> logoutBody() async {
      Map<String, dynamic>? sent;
      await http.runWithClient(() => auth.logout(), () => MockClient((req) async {
            if (req.url.path.endsWith(Endpoints.logoutURL)) {
              sent = jsonDecode(req.body) as Map<String, dynamic>;
            }
            return _json(200, {'success': true});
          }));
      return sent!;
    }

    test('biometric on: the snapshot refresh token is NOT revoked', () async {
      SharedPreferences.setMockInitialValues({'biometric_enabled': true});
      auth
        ..token = 'access'
        ..refreshToken = 'rt-A';
      final body = await logoutBody();
      expect(body.containsKey('refreshToken'), isFalse);
      expect(storage.value, isNotNull, reason: 'snapshot kept for re-login');
    });

    test('biometric off: the refresh token is revoked as before', () async {
      SharedPreferences.setMockInitialValues({});
      auth
        ..token = 'access'
        ..refreshToken = 'rt-A';
      final body = await logoutBody();
      expect(body['refreshToken'], 'rt-A');
    });

    test("another account's snapshot does not shield this session", () async {
      SharedPreferences.setMockInitialValues({'biometric_enabled': true});
      auth
        ..token = 'access'
        ..refreshToken = 'rt-B';
      final body = await logoutBody();
      expect(body['refreshToken'], 'rt-B');
    });
  });

  group('loginWithBiometric', () {
    test('refreshes with the snapshot refresh token, stores the fresh token',
        () async {
      SharedPreferences.setMockInitialValues({'biometric_enabled': true});
      String? sentRefresh;
      final outcome = await http.runWithClient(
        () => auth.loginWithBiometric(_snapshot),
        () => MockClient((req) async {
          sentRefresh = (jsonDecode(req.body) as Map)['refreshToken'];
          return _json(200, {'success': true, 'token': 'fresh-access'});
        }),
      );
      expect(outcome, BiometricLoginOutcome.success);
      expect(sentRefresh, 'rt-A');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), 'fresh-access',
          reason: 'not the possibly-expired snapshot access token');
      expect(prefs.getString('refreshToken'), 'rt-A');
      expect(prefs.getString('userId'), 'userA');
    });

    test('a rotated refresh token is written back into the snapshot',
        () async {
      SharedPreferences.setMockInitialValues({'biometric_enabled': true});
      await http.runWithClient(
        () => auth.loginWithBiometric(_snapshot),
        () => MockClient((_) async =>
            _json(200, {'token': 'fresh', 'refreshToken': 'rt-A2'})),
      );
      final saved = BiometricAuthState.tryParse(storage.value!)!;
      expect(saved.refreshToken, 'rt-A2');
      expect(saved.userId, 'userA');
    });

    for (final status in [400, 401, 403, 404]) {
      test('rejected refresh ($status) deletes the snapshot, turns it off',
          () async {
        SharedPreferences.setMockInitialValues({
          'biometric_enabled': true,
          'biometric_user_name_display': 'Ann',
        });
        final outcome = await http.runWithClient(
          () => auth.loginWithBiometric(_snapshot),
          () => MockClient((_) async => _json(status, {'error': 'no'})),
        );
        expect(outcome, BiometricLoginOutcome.rejected);
        expect(storage.value, isNull);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('biometric_enabled'), isNull);
        expect(prefs.getString('token'), isNull);
      });
    }

    test('network error / 5xx: retryable, snapshot kept', () async {
      SharedPreferences.setMockInitialValues({'biometric_enabled': true});
      final offline = await http.runWithClient(
        () => auth.loginWithBiometric(_snapshot),
        () => MockClient((_) async => throw http.ClientException('reset')),
      );
      final down = await http.runWithClient(
        () => auth.loginWithBiometric(_snapshot),
        () => MockClient((_) async => _json(503, {'error': 'down'})),
      );
      expect(offline, BiometricLoginOutcome.retryable);
      expect(down, BiometricLoginOutcome.retryable);
      expect(storage.value, isNotNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('biometric_enabled'), isTrue);
    });
  });
}
