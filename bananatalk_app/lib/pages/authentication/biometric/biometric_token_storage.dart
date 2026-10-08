import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for the biometric-protected auth snapshot.
/// Stored in the iOS Keychain / Android Keystore-backed encrypted prefs.
///
/// iOS accessibility is `unlocked_this_device`
/// (kSecAttrAccessibleWhenUnlockedThisDeviceOnly):
///  - readable only while the device is unlocked -- biometric sign-in only
///    ever happens in the foreground, so nothing needs it while locked (it
///    was `first_unlock_this_device`, readable while locked after the first
///    unlock since boot);
///  - `ThisDeviceOnly`: never synced to iCloud Keychain and not restored to
///    another device from a backup; `synchronizable: false` as well;
///  - survives app relaunch (and, being the keychain, even a reinstall --
///    the `biometric_enabled` pref gates use, so an orphan is never offered).
///
/// Changing accessibility is safe for existing users: reads ignore the
/// attribute and writes delete-and-recreate on mismatch (plugin 9.2.4).
/// Deletes do match it, so [clear] also deletes under the old value.
class BiometricTokenStorage {
  static const _tokenKey = 'biometric_auth_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: iosOptions,
  );

  /// The keychain options every write uses (exposed for a test to pin).
  static const iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
    synchronizable: false,
  );

  /// The pre-2026-10 accessibility, so [clear] can remove those items too.
  static const _legacyIosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  Future<void> save(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> read() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      // Keychain entry can become unreadable after device biometric
      // re-enrollment or restore-from-backup. Treat as no token.
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    try {
      await _storage.delete(key: _tokenKey, iOptions: _legacyIosOptions);
    } catch (_) {}
  }
}
