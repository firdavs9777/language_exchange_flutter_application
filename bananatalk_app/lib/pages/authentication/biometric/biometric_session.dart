import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';

import 'package:bananatalk_app/pages/authentication/biometric/biometric_service.dart';
import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';

/// How the biometric snapshot (token + refresh token in the keychain) and the
/// server session fit together.
///
/// Logout used to send the session's refresh token to `/auth/logout`, which
/// revokes exactly that token -- the same one the biometric snapshot holds.
/// "Continue with Face ID" then restored a revoked refresh token plus an
/// access token that might already be expired, so it only worked by luck.
///
/// Now:
///  - logout leaves the refresh token alive on the server when the biometric
///    snapshot holds it ([isRefreshTokenHeldForBiometric]); with biometrics
///    off it is revoked as before. Deletion/suspension wipe the snapshot.
///  - biometric login spends the snapshot's refresh token at the refresh
///    endpoint for a fresh access token (`AuthService.loginWithBiometric`)
///    instead of trusting the stored access token.
///  - a definitive rejection deletes the snapshot and turns biometrics off;
///    a network error keeps it for a retry.
enum BiometricLoginOutcome {
  success,

  /// Refresh token rejected or account gone: snapshot deleted, flag off.
  rejected,

  /// Offline / server error: snapshot kept, try again later.
  retryable,
}

/// True when biometric login is enabled AND its snapshot holds
/// [refreshToken] -- i.e. revoking that token at logout would break the next
/// biometric sign-in. A different account's snapshot does not protect this
/// session's token.
Future<bool> isRefreshTokenHeldForBiometric(
  String refreshToken, {
  SharedPreferences? prefs,
  BiometricTokenStorage? storage,
}) async {
  if (refreshToken.isEmpty) return false;
  try {
    final p = prefs ?? await SharedPreferences.getInstance();
    if (p.getBool('biometric_enabled') != true) return false;
    final state = await BiometricService(
      storage: storage ?? BiometricTokenStorage(),
    ).readState();
    return state != null && state.refreshToken == refreshToken;
  } catch (e) {
    debugPrint('[biometric] snapshot check failed: $e');
    return false;
  }
}

/// Keeps the snapshot usable if the server ever rotates refresh tokens: when
/// [oldRefreshToken] is the one in the snapshot, store [newRefreshToken] (and
/// [newAccessToken]) in its place. No-op otherwise.
Future<void> rotateBiometricSnapshot({
  required String oldRefreshToken,
  required String newRefreshToken,
  String? newAccessToken,
  BiometricTokenStorage? storage,
}) async {
  if (newRefreshToken.isEmpty || newRefreshToken == oldRefreshToken) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('biometric_enabled') != true) return;
    final s = storage ?? BiometricTokenStorage();
    final service = BiometricService(storage: s);
    final state = await service.readState();
    if (state == null || state.refreshToken != oldRefreshToken) return;
    await service.enable(BiometricAuthState(
      token: newAccessToken ?? state.token,
      refreshToken: newRefreshToken,
      userId: state.userId,
      userName: state.userName,
    ));
  } catch (e) {
    debugPrint('[biometric] snapshot rotation failed: $e');
  }
}

/// What to tell the user after a biometric prompt, or null for nothing
/// (success, or they cancelled on purpose).
String? biometricResultMessage(
  AppLocalizations l10n,
  BiometricAuthResult result,
) {
  switch (result) {
    case BiometricAuthResult.success:
    case BiometricAuthResult.cancelled:
      return null;
    case BiometricAuthResult.notAvailable:
      return l10n.biometricNotAvailable;
    case BiometricAuthResult.notEnrolled:
      return l10n.biometricNotEnrolled;
    case BiometricAuthResult.lockedOut:
      return l10n.biometricLockedOut;
    case BiometricAuthResult.permanentlyLockedOut:
      return l10n.biometricPermanentlyLockedOut;
    case BiometricAuthResult.passcodeNotSet:
      return l10n.biometricPasscodeNotSet;
    case BiometricAuthResult.error:
      return l10n.somethingWentWrong;
  }
}
