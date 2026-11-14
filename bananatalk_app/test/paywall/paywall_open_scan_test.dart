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
      // Each screen file may declare its OWN constructor only.
      final ownDecl = {
        'pages/vip/vip_plans_screen.dart':
            RegExp(r'^\s*const\s+VipPlansScreen\('),
        'pages/coins/coin_shop_screen.dart':
            RegExp(r'^\s*const\s+CoinShopScreen\('),
      };
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('services/paywall/paywall_navigation.dart')) {
          continue;
        }
        RegExp? own;
        for (final e in ownDecl.entries) {
          if (entity.path.endsWith(e.key)) own = e.value;
        }
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!ctor.hasMatch(lines[i])) continue;
          // The screen's own constructor declaration, in its own file.
          if (own != null &&
              own.hasMatch(lines[i]) &&
              ctor.allMatches(lines[i]).length == 1) {
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
