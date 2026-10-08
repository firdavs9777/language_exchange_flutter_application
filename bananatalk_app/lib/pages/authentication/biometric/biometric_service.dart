import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';

/// Snapshot of auth state preserved across logout for biometric login.
class BiometricAuthState {
  final String token;
  final String refreshToken;
  final String userId;
  final String userName;

  const BiometricAuthState({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.userName,
  });

  Map<String, String> toJson() => {
    'token': token,
    'refreshToken': refreshToken,
    'userId': userId,
    'userName': userName,
  };

  static BiometricAuthState? tryParse(String raw) {
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      return BiometricAuthState(
        token: m['token']?.toString() ?? '',
        refreshToken: m['refreshToken']?.toString() ?? '',
        userId: m['userId']?.toString() ?? '',
        userName: m['userName']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

/// What a biometric prompt ended in. Everything except [success] and
/// [cancelled] deserves a message: the user cannot fix what they are not told.
enum BiometricAuthResult {
  success,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  error,
}

/// Maps local_auth's PlatformException codes (package:local_auth/error_codes).
BiometricAuthResult biometricResultForErrorCode(String code) {
  switch (code) {
    case auth_error.notAvailable:
    case auth_error.otherOperatingSystem:
    case auth_error.biometricOnlyNotSupported:
      return BiometricAuthResult.notAvailable;
    case auth_error.notEnrolled:
      return BiometricAuthResult.notEnrolled;
    case auth_error.lockedOut:
      return BiometricAuthResult.lockedOut;
    case auth_error.permanentlyLockedOut:
      return BiometricAuthResult.permanentlyLockedOut;
    case auth_error.passcodeNotSet:
      return BiometricAuthResult.passcodeNotSet;
    default:
      return BiometricAuthResult.error;
  }
}

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
  static const _userNameDisplayKey = 'biometric_user_name_display';

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

  /// Triggers the OS biometric prompt. True only on success.
  Future<bool> authenticate({required String reason}) async =>
      await authenticateWithResult(reason: reason) ==
      BiometricAuthResult.success;

  /// Triggers the OS biometric prompt and says what happened.
  ///
  /// [authenticate] used to swallow every PlatformException as `false`, so
  /// "no Face ID enrolled", "locked out after too many tries" and "this
  /// Android activity can't host the prompt" all looked like the user
  /// cancelling: the login button simply did nothing. [reason] is shown on
  /// Android; on iOS NSFaceIDUsageDescription is used.
  Future<BiometricAuthResult> authenticateWithResult({
    required String reason,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      // local_auth reports a user/system cancel as `false`, not an error.
      return ok ? BiometricAuthResult.success : BiometricAuthResult.cancelled;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('BiometricService.authenticate: ${e.code}');
      return biometricResultForErrorCode(e.code);
    } catch (e) {
      if (kDebugMode) debugPrint('BiometricService.authenticate failed: $e');
      return BiometricAuthResult.error;
    }
  }

  /// True when the "Continue as <name>" button may be shown: the user opted
  /// in, the device still has biometrics enrolled, AND a snapshot is
  /// actually readable. An opted-in flag with no readable snapshot (keychain
  /// wiped, restored onto a new phone) is turned off here rather than
  /// offering a button that can only fail.
  Future<bool> canOfferLogin() async {
    if (!await isEnabled()) return false;
    if (!await isAvailable()) return false;
    final state = await readState();
    if (state == null || state.refreshToken.isEmpty) {
      await disable();
      return false;
    }
    return true;
  }

  /// Enable biometric login: store the auth snapshot + flip the flag.
  /// Caller is responsible for having JUST authenticated successfully.
  Future<void> enable(BiometricAuthState state) async {
    await _storage.save(json.encode(state.toJson()));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledFlagKey, true);
    // Cache the userName for display on the login button (needs no
    // biometric to read — it's not sensitive).
    await prefs.setString(_userNameDisplayKey, state.userName);
  }

  /// Display name for the "Continue as <name>" button. Available
  /// without biometric since it's just a label, not a credential.
  Future<String?> readUserNameDisplay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameDisplayKey);
  }

  /// Disable + wipe stored token. Called on opt-out and after any 401 that
  /// proves the stored token is no longer valid. Logout does NOT call this
  /// — biometric is meant to survive logout so the user can re-enter quickly.
  Future<void> disable() async {
    await _storage.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_enabledFlagKey);
    await prefs.remove(_userNameDisplayKey);
  }

  /// Read the stored auth snapshot. Returns null if disabled, if the
  /// keychain entry is unreadable, or if the device is locked.
  Future<BiometricAuthState?> readState() async {
    final raw = await _storage.read();
    if (raw == null || raw.isEmpty) return null;
    return BiometricAuthState.tryParse(raw);
  }
}
