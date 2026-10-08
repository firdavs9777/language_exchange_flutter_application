import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';

/// What survives a logout in SharedPreferences.
///
/// Logout used to call `prefs.clear()`, which also threw away the theme, the
/// app language, the remembered login email and the biometric opt-in flag --
/// so signing out reset the device. The app keeps ~60 keys across ~110 files,
/// most of them user-scoped (tokens, API caches, drafts, chat themes, mutes,
/// quotas, onboarding progress), so this is an ALLOW-list of device-level keys
/// rather than a deny-list of user ones: a key nobody remembered to classify
/// is removed, which is the safe failure for a shared phone.
///
/// Device-level = a property of this install/phone or a preference about the
/// app itself, not about the person signed in.
const Set<String> kDeviceLevelPrefsKeys = {
  // Appearance + app language (main.dart, LanguageService).
  'app_theme',
  'app_language',
  // Login-screen conveniences. The biometric flag + display name only exist
  // while the user has opted in; they pair with the secure-storage snapshot
  // that is kept for re-login (see [clearUserSessionPrefs]).
  'rememberedEmail',
  'biometric_enabled',
  'biometric_user_name_display',
  // Install identity / OS-level state.
  'deviceId',
  'pending_voip_token', // CallKit token waiting for the next login to register
  'notification_prompt_shown', // the OS permission prompt is per install
  'pending_referral_code', // install-link attribution, consumed at signup
  // Public catalog cache (same for every user).
  'languages_catalog_cache_v1',
  // Device/data-usage preferences.
  'video_muted',
  'auto_download_images',
  'auto_download_videos',
  'auto_download_voice',
  'auto_download_documents',
  // Store review / app-update / ads-notice nags are per install.
  'review_prompt_at',
  'app_update_last_soft_prompt_ms',
  'ads_notice_shown_v1',
};

/// True when [key] must survive a logout.
bool isDeviceLevelPrefsKey(String key) => kDeviceLevelPrefsKeys.contains(key);

/// Removes every user/session key from [prefs], keeping [kDeviceLevelPrefsKeys].
Future<void> clearUserScopedPrefs(SharedPreferences prefs) async {
  for (final key in prefs.getKeys().toList()) {
    if (isDeviceLevelPrefsKey(key)) continue;
    try {
      await prefs.remove(key);
    } catch (_) {
      // Keep going: one stuck key must not leave the rest of the session.
    }
  }
}

/// Logout-time prefs + secure-storage cleanup.
///
/// The biometric secure-storage snapshot (token + refresh token) is kept only
/// when biometric login is enabled -- that is its whole purpose, re-entering
/// after a logout. With biometrics off nothing can ever read it, so leaving a
/// live credential in the keychain is pure risk: it is deleted.
Future<void> clearUserSessionPrefs({
  SharedPreferences? prefs,
  BiometricTokenStorage? biometricStorage,
}) async {
  final p = prefs ?? await SharedPreferences.getInstance();
  final biometricEnabled = p.getBool('biometric_enabled') ?? false;
  await clearUserScopedPrefs(p);
  if (!biometricEnabled) {
    try {
      await (biometricStorage ?? BiometricTokenStorage()).clear();
    } catch (_) {
      // Keychain unavailable (locked device, tests): nothing to leak then.
    }
  }
}
