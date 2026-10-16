import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// links#7: with Flutter 3.38 defaults the engine hands /i/CODE or
/// /moment/x straight to GoRouter (no route / no errorBuilder, skips splash
/// and DeepLinkGate) while app_links pushes the same link. Only app_links +
/// DeepLinkGate may handle links.
void main() {
  test('iOS: FlutterDeepLinkingEnabled is false', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<false/>').hasMatch(plist), isTrue);
  });

  test('Android: flutter_deeplinking_enabled=false on MainActivity', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final activity = RegExp(r'<activity\s+android:name="\.MainActivity".*?</activity>', dotAll: true)
        .firstMatch(manifest)!
        .group(0)!;
    expect(
      RegExp(r'<meta-data\s+android:name="flutter_deeplinking_enabled"\s+android:value="false"\s*/>')
          .hasMatch(activity),
      isTrue,
    );
  });
}
