import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Every way into the VIP screen / coin shop goes through openVipPlans /
// openCoinShop so each open carries a PaywallFlow and logs the funnel.

void main() {
  test(
    'only paywall_navigation.dart constructs VipPlansScreen or CoinShopScreen',
    () {
      final offenders = <String>[];
      final ctor = RegExp(r'\b(VipPlansScreen|CoinShopScreen)\(');
      final ownDecl = RegExp(r'\bconst\s+(VipPlansScreen|CoinShopScreen)\(');
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('services/paywall/paywall_navigation.dart')) {
          continue;
        }
        final isScreenFile =
            entity.path.endsWith('pages/vip/vip_plans_screen.dart') ||
            entity.path.endsWith('pages/coins/coin_shop_screen.dart');
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!ctor.hasMatch(lines[i])) continue;
          // The screen's own constructor declaration.
          if (isScreenFile &&
              ownDecl.hasMatch(lines[i]) &&
              lines[i].trimLeft().startsWith('const ')) {
            continue;
          }
          offenders.add('${entity.path}:${i + 1}');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'use openVipPlans / openCoinShop:\n${offenders.join('\n')}',
      );
    },
  );
}
