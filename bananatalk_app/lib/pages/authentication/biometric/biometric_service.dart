import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';

/// Wraps local_auth + secure-storage for biometric login.
///
/// State model:
/// - `isAvailable()` — device supports biometrics AND user has enrolled
///   (Face ID, Touch ID, fingerprint).
/// - `isEnabled()` — user opted-in for this app. Backed by SharedPreferences
///   for fast read on the login screen.
/// - The token itself is in flutter_secure_storage; only readable when the
///   device is unlocked + biometric hasn't been re-enrolled.
class BiometricService {
  BiometricService({LocalAuthentication? auth, BiometricTokenStorage? storage})
      : _auth = auth ?? LocalAuthentication(),
        _storage = storage ?? BiometricTokenStorage();

  static const _enabledFlagKey = 'biometric_enabled';

  final LocalAuthentication _auth;
  final BiometricTokenStorage _storage;

  /// True if the device supports biometrics AND the user has enrolled.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('BiometricService.isAvailable failed: $e');
      return false;
    }
  }

  /// True if the user has opted in for biometric login on this app.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledFlagKey) ?? false;
  }

  /// Triggers the OS biometric prompt. Returns true on success.
  /// [reason] is shown on Android; on iOS it's overridden by
  /// NSFaceIDUsageDescription in Info.plist.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('BiometricService.authenticate failed: $e');
      return false;
    }
  }

  /// Enable biometric login: store the token + flip the flag.
  /// Caller is responsible for having JUST authenticated successfully.
  Future<void> enable(String token) async {
    await _storage.save(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledFlagKey, true);
  }

  /// Disable + wipe stored token. Called on logout, on opt-out, and after
  /// any 401 that proves the stored token is no longer valid.
  Future<void> disable() async {
    await _storage.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_enabledFlagKey);
  }

  /// Read the stored token if biometric is enabled. Returns null if disabled,
  /// if the keychain entry is unreadable, or if the device is locked.
  Future<String?> readStoredToken() async => _storage.read();
}
