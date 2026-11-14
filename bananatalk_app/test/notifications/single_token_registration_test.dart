import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The FCM token is registered once per launch, by the splash screen (always
/// the first route) on every session restore. `main()` used to register it
/// too, before `runApp`: two POSTs per launch, and the first frame waited on
/// a network round trip.
void main() {
  test('main() does not register the push token', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source.contains('.registerToken('), isFalse);
  });

  test('the splash screen still registers it on restore', () {
    final source = File('lib/pages/home/splash_screen.dart').readAsStringSync();
    expect('.registerToken('.allMatches(source).length, 1);
  });
}
