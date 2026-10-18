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
      // story/chat ids must be ObjectIds; invite codes are A-Z2-7.
      for (final p in prefixes) {
        final id = p == '/i/' ? 'ABCDEFGH' : '64b7f0c2a1b2c3d4e5f60718';
        final uri = Uri.parse('https://banatalk.com$p$id');
        expect(routePathFromUri(uri), isNotNull, reason: p);
      }
    });

    test('every link shape the app handles is claimed', () {
      for (final path in [
        '/moment/123',
        '/profile/u1',
        '/community/matches',
        '/community/waves',
        '/story/64b7f0c2a1b2c3d4e5f60718',
        '/chat/64b7f0c2a1b2c3d4e5f60718',
        '/i/ABCDEFGH',
      ]) {
        expect(routePathFromUri(Uri.parse('https://banatalk.com$path')), isNotNull, reason: path);
        expect(claimed(path), isTrue, reason: path);
      }
    });

    test('legal pages and the web home stay in the browser', () {
      for (final path in ['/', '/privacy-policy', '/terms-of-use', '/moments/123', '/delete-account', '/stories/abc']) {
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

  group('permissions the app never uses are not requested', () {
    // Each of these is a Play policy / Data-safety surface. None is used by
    // lib/ or by a plugin's own code path the app reaches (audit 2026-10-13):
    // media comes through the photo picker / SAF, calls are self-managed.
    const unused = [
      'android.permission.READ_CONTACTS',
      'android.permission.READ_PHONE_STATE',
      'android.permission.SYSTEM_ALERT_WINDOW',
      'android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      'android.permission.READ_MEDIA_IMAGES',
      'android.permission.READ_MEDIA_VIDEO',
      'android.permission.READ_MEDIA_AUDIO',
    ];
    for (final perm in unused) {
      test(perm, () {
        expect(manifest, isNot(contains('<uses-permission android:name="$perm" />')));
        expect(manifest, isNot(contains('<uses-permission android:name="$perm"/>')));
      });
    }

    test('legacy Bluetooth permissions stop at API 30 (BLUETOOTH_CONNECT after)', () {
      for (final perm in ['BLUETOOTH', 'BLUETOOTH_ADMIN']) {
        expect(manifest,
            contains('<uses-permission android:name="android.permission.$perm"\n        android:maxSdkVersion="30" />'),
            reason: perm);
      }
    });

    test('no lib/ code asks for them at runtime', () {
      final asked = RegExp(r'Permission\.(contacts|phone|systemAlertWindow|ignoreBatteryOptimizations|photos|videos|audio|mediaLibrary)\b');
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        expect(asked.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
      }
    });
  });

  test('no dead Facebook SDK entries (flutter_facebook_auth is not a dependency)', () {
    expect(read('pubspec.yaml'), isNot(matches(RegExp(r'^\s+flutter_facebook_auth:', multiLine: true))));
    expect(manifest, isNot(contains('com.facebook')));
    expect(read('$res/values/strings.xml'), isNot(contains('facebook')));
  });

  test('CallKit components are guarded by a signature permission, not normal', () {
    // flutter_callkit_incoming declares ${applicationId}.PERMISSION_CALL as
    // "normal", so any app could declare it and fire fake incoming-call /
    // accept / decline intents. The plugin's own intents are explicit and
    // in-app, which a signature permission still allows.
    expect(
        manifest,
        contains('<permission\n        android:name="\${applicationId}.PERMISSION_CALL"\n'
            '        android:protectionLevel="signature"\n        tools:replace="android:protectionLevel" />'));
  });

  test('backups and device transfer never carry the session or secure storage', () {
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(manifest, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
    const files = [
      'FlutterSharedPreferences.xml', // token, refreshToken, userId
      'FlutterSecureStorage.xml', // biometric token (Keystore key does not transfer)
      'FlutterSecureKeyStorage.xml',
    ];
    final backup = read('$res/xml/backup_rules.xml');
    for (final f in files) {
      expect(backup, contains('<exclude domain="sharedpref" path="$f" />'), reason: 'backup_rules $f');
    }
    final extraction = read('$res/xml/data_extraction_rules.xml');
    for (final section in ['cloud-backup', 'device-transfer']) {
      final body = RegExp('<$section[^>]*>(.*?)</$section>', dotAll: true).firstMatch(extraction)!.group(1)!;
      for (final f in files) {
        expect(body, contains('<exclude domain="sharedpref" path="$f" />'), reason: '$section $f');
      }
    }
  });

  test('release version is above the live 2.6.1 (10574) and has notes', () {
    final m = RegExp(r'^version: (\d+\.\d+\.\d+)\+(\d+)$', multiLine: true).firstMatch(read('pubspec.yaml'))!;
    expect(int.parse(m.group(2)!), greaterThan(10574), reason: 'Play rejects a reused versionCode');
    // Owner's choice for this release (2026-10-18): 2.2.6 (10581). Play only
    // needs the versionCode above 10574; the App Store needs the version
    // name above the live iOS version.
    expect(m.group(1), '2.2.6');
    expect(m.group(2), '10581');
    expect(File('docs/releases/${m.group(1)}.md').existsSync(), isTrue);
  });
}
