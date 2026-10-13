import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards for the Android release configuration (android audit 2026-10-13).
/// Static checks on the checked-in files: the merged manifest is verified by
/// the release build, these keep the source from drifting back.
void main() {
  const res = 'android/app/src/main/res';
  String read(String path) => File(path).readAsStringSync();
  final manifest = read('android/app/src/main/AndroidManifest.xml');

  group('notifications', () {
    test('FCM default channel is the channel the app creates (heads-up)', () {
      final strings = read('$res/values/strings.xml');
      final id = RegExp(r'name="default_notification_channel_id">([^<]+)<')
          .firstMatch(strings)!
          .group(1);
      expect(id, 'high_importance_channel');
      expect(read('lib/services/notification_service.dart'),
          contains("AndroidNotificationChannel(\n        '$id'"));
    });

    test('small icon is the monochrome ic_notification vector everywhere', () {
      final icon = File('$res/drawable/ic_notification.xml');
      expect(icon.existsSync(), isTrue);
      final xml = icon.readAsStringSync();
      expect(xml, contains('<vector'));
      // Android uses only the alpha channel: one opaque white fill.
      expect(RegExp(r'android:fillColor="(#[0-9A-Fa-f]+)"').allMatches(xml).map((m) => m.group(1)).toSet(),
          {'#FFFFFFFF'});
      expect(manifest, contains('android:resource="@drawable/ic_notification"'));
      expect(manifest, isNot(contains('default_notification_icon"\n            android:resource="@mipmap')));
      for (final f in [
        'lib/services/notification_service.dart',
        'lib/services/call/missed_call_actions.dart',
      ]) {
        final src = read(f);
        expect(src, contains("AndroidInitializationSettings('@drawable/ic_notification')"), reason: f);
        expect(src, isNot(contains("AndroidInitializationSettings('@mipmap")), reason: f);
      }
    });
  });
}
