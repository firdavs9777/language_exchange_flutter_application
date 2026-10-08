import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_service.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_session.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';

class _FakeLocalAuth extends LocalAuthentication {
  _FakeLocalAuth({this.result, this.error, this.enrolled = true});
  final bool? result;
  final PlatformException? error;
  final bool enrolled;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<bool> get canCheckBiometrics async => true;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async =>
      enrolled ? [BiometricType.face] : [];
}

class _FakeStorage implements BiometricTokenStorage {
  String? value;
  @override
  Future<void> clear() async => value = null;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> save(String token) async => value = token;
}

void main() {
  final l10n = AppLocalizationsEn();

  group('authenticateWithResult', () {
    Future<BiometricAuthResult> run(_FakeLocalAuth a) =>
        BiometricService(auth: a, storage: _FakeStorage())
            .authenticateWithResult(reason: 'r');

    test('success and cancel', () async {
      expect(await run(_FakeLocalAuth(result: true)),
          BiometricAuthResult.success);
      expect(await run(_FakeLocalAuth(result: false)),
          BiometricAuthResult.cancelled);
    });

    test('platform errors are distinguished, not swallowed as false', () async {
      Future<BiometricAuthResult> code(String c) =>
          run(_FakeLocalAuth(error: PlatformException(code: c)));
      expect(await code('NotAvailable'), BiometricAuthResult.notAvailable);
      expect(await code('NotEnrolled'), BiometricAuthResult.notEnrolled);
      expect(await code('LockedOut'), BiometricAuthResult.lockedOut);
      expect(await code('PermanentlyLockedOut'),
          BiometricAuthResult.permanentlyLockedOut);
      expect(await code('PasscodeNotSet'), BiometricAuthResult.passcodeNotSet);
      // The Android FlutterActivity bug's code: an error, not a "cancel".
      expect(await code('no_fragment_activity'), BiometricAuthResult.error);
    });

    test('every failure but cancel has a message', () {
      expect(biometricResultMessage(l10n, BiometricAuthResult.cancelled),
          isNull);
      expect(biometricResultMessage(l10n, BiometricAuthResult.notEnrolled),
          l10n.biometricNotEnrolled);
      expect(biometricResultMessage(l10n, BiometricAuthResult.lockedOut),
          l10n.biometricLockedOut);
      expect(biometricResultMessage(l10n, BiometricAuthResult.error),
          l10n.somethingWentWrong);
    });
  });

  group('canOfferLogin ("Continue as <name>" button)', () {
    final snapshot = jsonEncode(const BiometricAuthState(
      token: 't',
      refreshToken: 'rt',
      userId: 'u',
      userName: 'Ann',
    ).toJson());

    test('enabled + enrolled + readable snapshot -> shown', () async {
      SharedPreferences.setMockInitialValues({'biometric_enabled': true});
      final s = _FakeStorage()..value = snapshot;
      expect(
          await BiometricService(auth: _FakeLocalAuth(), storage: s)
              .canOfferLogin(),
          isTrue);
    });

    test('not enabled -> hidden', () async {
      SharedPreferences.setMockInitialValues({});
      final s = _FakeStorage()..value = snapshot;
      expect(
          await BiometricService(auth: _FakeLocalAuth(), storage: s)
              .canOfferLogin(),
          isFalse);
    });

    test('biometrics no longer enrolled -> hidden', () async {
      SharedPreferences.setMockInitialValues({'biometric_enabled': true});
      final s = _FakeStorage()..value = snapshot;
      expect(
          await BiometricService(
                  auth: _FakeLocalAuth(enrolled: false), storage: s)
              .canOfferLogin(),
          isFalse);
    });

    test('flag on but snapshot unreadable -> hidden and flag cleared',
        () async {
      SharedPreferences.setMockInitialValues({'biometric_enabled': true});
      final ok = await BiometricService(
              auth: _FakeLocalAuth(), storage: _FakeStorage())
          .canOfferLogin();
      expect(ok, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('biometric_enabled'), isNull);
    });
  });
}
