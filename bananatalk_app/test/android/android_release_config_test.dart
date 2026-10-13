import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/deep_link_parser.dart';

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

  group('App Links (https://banatalk.com)', () {
    // The autoVerify filter: once assetlinks verifies, every matching URL
    // opens the app instead of the browser.
    final filter = RegExp(r'<intent-filter android:autoVerify="true">(.*?)</intent-filter>', dotAll: true)
        .firstMatch(manifest)!
        .group(1)!;
    final prefixes = RegExp(r'android:pathPrefix="([^"]+)"').allMatches(filter).map((m) => m.group(1)!).toList();

    bool claimed(String path) => prefixes.any(path.startsWith);

    test('the filter is restricted to paths', () {
      expect(prefixes, isNotEmpty);
      expect(filter, isNot(contains('android:path=')));
      expect(filter, isNot(contains('pathPattern')));
    });

    test('every claimed prefix is a route the app handles', () {
      for (final p in prefixes) {
        final uri = Uri.parse('https://banatalk.com${p}ABCDEFGH');
        expect(routePathFromUri(uri), isNotNull, reason: p);
      }
    });

    test('every link shape the app handles is claimed', () {
      for (final path in ['/moment/123', '/profile/u1', '/community/matches', '/community/waves', '/i/ABCDEFGH']) {
        expect(routePathFromUri(Uri.parse('https://banatalk.com$path')), isNotNull, reason: path);
        expect(claimed(path), isTrue, reason: path);
      }
    });

    test('legal pages and the web home stay in the browser', () {
      for (final path in ['/', '/privacy-policy', '/terms-of-use', '/moments/123', '/delete-account']) {
        expect(claimed(path), isFalse, reason: path);
      }
    });
  });

  test('every app locale is offered in Android 13+ per-app language settings', () {
    final config = read('$res/xml/locales_config.xml');
    final declared = RegExp(r'<locale android:name="([^"]+)"').allMatches(config).map((m) => m.group(1)!).toList();
    final arbs = Directory('lib/l10n')
        .listSync()
        .map((f) => RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)?.group(1))
        .whereType<String>()
        .toList();
    expect(arbs, hasLength(19));
    for (final l in arbs) {
      final parts = l.split('_'); // zh_TW
      final ok = declared.any((d) {
        final dp = d.split('-');
        if (dp.first != parts.first) return false;
        if (parts.length == 1) return parts.first != 'zh' || !d.contains('Hant');
        return d.endsWith(parts.last);
      });
      expect(ok, isTrue, reason: '$l missing from locales_config.xml');
    }
    expect(manifest, contains('android:supportsRtl="true"'), reason: 'Arabic mirrors native screens');
  });

  test('implied hardware features never filter devices out of Play', () {
    for (final f in [
      'android.hardware.bluetooth',
      'android.hardware.location',
      'android.hardware.location.gps',
      'android.hardware.location.network',
      'android.hardware.wifi',
      'android.hardware.camera',
      'android.hardware.microphone',
      'android.hardware.telephony',
      'android.hardware.screen.portrait',
    ]) {
      expect(manifest, contains('<uses-feature android:name="$f" android:required="false" />'), reason: f);
    }
  });

  test('no bogus manifest attributes or permission names', () {
    expect(manifest, isNot(contains('showOnLockScreen')));
    expect(manifest,
        contains('<uses-permission android:name="Manifest.permission.CAPTURE_AUDIO_OUTPUT" tools:node="remove" />'));
  });
}
