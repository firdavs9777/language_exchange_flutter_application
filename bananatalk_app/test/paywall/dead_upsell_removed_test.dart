import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the unreachable upsell files are gone', () {
    for (final path in [
      'lib/widgets/visitor_limit_dialog.dart',
      'lib/pages/vip/visitor_upgrade_screen.dart',
      'lib/services/daily_chat_limit_service.dart',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: '$path should be deleted');
    }
  });

  test('lib/ names none of the removed upsell symbols', () {
    const symbols = [
      'VisitorLimitDialog',
      'VisitorUpgradeScreen',
      'VipPromoCard',
      'VipLockBadge',
      'DailyChatLimitService',
      '_chatLimitReached',
      'wrapWithFeatureGate',
    ];
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      for (final s in symbols) {
        if (text.contains(s)) hits.add('${entity.path}: $s');
      }
    }
    expect(hits, isEmpty);
  });
}
