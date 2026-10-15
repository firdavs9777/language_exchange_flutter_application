import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// audit_a #21: AI story setup, the AI lesson builder and lesson completion
// called AdService.showInterstitial() directly, so an interstitial showed on
// every use, ignoring the every-N / min-gap / once-per-session caps. Every
// screen must go through a capped entry point
// (maybeShowInterstitial / maybeShowInterstitialOncePerSession).

void main() {
  test('no screen calls showInterstitial() directly', () {
    final offenders = <String>[];
    final direct = RegExp(r'\.showInterstitial\(\)');
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('services/ad_service.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (direct.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'use AdService.maybeShowInterstitial(...) instead');
  });
}
