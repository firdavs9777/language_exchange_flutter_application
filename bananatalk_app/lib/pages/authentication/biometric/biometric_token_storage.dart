import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for the biometric-protected auth token.
/// Token is stored in iOS Keychain / Android Keystore (encrypted at rest).
/// Reads gated by biometric enrollment via the OS — accessing the token
/// from another app or after biometric re-enrollment fails silently.
class BiometricTokenStorage {
  static const _tokenKey = 'biometric_auth_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<void> save(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> read() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      // Keychain entry can become unreadable after device biometric
      // re-enrollment or restore-from-backup. Treat as no token.
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
