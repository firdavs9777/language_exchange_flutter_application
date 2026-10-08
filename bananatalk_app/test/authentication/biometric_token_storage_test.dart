import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/authentication/biometric/biometric_token_storage.dart';

void main() {
  test('iOS keychain: readable only when unlocked, device-only, not synced',
      () {
    final m = BiometricTokenStorage.iosOptions.toMap();
    // first_unlock_this_device made the snapshot readable while locked.
    expect(m['accessibility'], 'unlocked_this_device');
    expect(m['synchronizable'], 'false');
  });
}
