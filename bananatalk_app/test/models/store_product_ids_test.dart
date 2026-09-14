import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/coin_pack.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';

/// The store product IDs are what a purchase is made against. When a plan's ID
/// is not among the IDs its platform service queries, `getProduct()` returns
/// null and the user sees "Product not found" instead of a paywall — so these
/// lists disagreeing is a revenue outage, not a style problem.
///
/// The IDs were duplicated across six places: both purchase services, both VIP
/// screens, and two sets of defaults in the backend's /plans endpoint. This is
/// the same list-drift shape that has already shipped five bugs in this repo.
void main() {
  group('VipPlan carries its own store product IDs', () {
    test('every plan has an ID on both platforms', () {
      for (final plan in VipPlan.values) {
        expect(plan.iosProductId, isNotEmpty, reason: '${plan.name} iOS');
        expect(plan.androidProductId, isNotEmpty, reason: '${plan.name} Android');
      }
    });

    test('no two plans share an ID', () {
      final ios = VipPlan.values.map((p) => p.iosProductId).toSet();
      final android = VipPlan.values.map((p) => p.androidProductId).toSet();
      expect(ios.length, VipPlan.values.length);
      expect(android.length, VipPlan.values.length);
    });

    test('the IDs are the ones registered in the stores', () {
      // Pinned deliberately: changing one of these is a store-console change
      // too, never a refactor. iOS and Android use different suffixes because
      // that is how they were registered.
      expect(VipPlan.monthly.iosProductId, 'com.bananatalk.bananatalkApp.vip.month');
      expect(VipPlan.quarterly.iosProductId, 'com.bananatalk.bananatalkApp.vip.quarter');
      expect(VipPlan.yearly.iosProductId, 'com.bananatalk.bananatalkApp.vip.year');
      expect(VipPlan.monthly.androidProductId, 'com.bananatalk.app.vip.monthly');
      expect(VipPlan.quarterly.androidProductId, 'com.bananatalk.app.vip.quarterly');
      expect(VipPlan.yearly.androidProductId, 'com.bananatalk.app.vip.yearly');
    });

    test('productId picks the platform the caller is on', () {
      expect(VipPlan.yearly.productId(true), VipPlan.yearly.iosProductId);
      expect(VipPlan.yearly.productId(false), VipPlan.yearly.androidProductId);
    });
  });

  group('the product IDs live in exactly one place', () {
    /// The two files allowed to spell an ID out. Everything else must derive
    /// from [VipPlan] or [CoinPack].
    const sources = {
      'lib/models/vip_subscription.dart',
      'lib/models/coin_pack.dart',
    };

    final literal = RegExp(r"'com\.bananatalk\.[A-Za-z.]*\.(vip|coins)\.[A-Za-z0-9]+'");

    test('no other lib/ file hardcodes a store product ID', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (sources.contains(entity.path)) continue;
        final hits = literal.allMatches(entity.readAsStringSync());
        for (final hit in hits) {
          offenders.add('${entity.path}: ${hit.group(0)}');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'these must come from VipPlan/CoinPack instead:\n'
            '${offenders.join('\n')}',
      );
    });
  });

  group('CoinPack is the source for coin product IDs', () {
    test('every pack has a distinct ID on both platforms', () {
      final ios = CoinPack.all.map((p) => p.iosProductId).toSet();
      final android = CoinPack.all.map((p) => p.androidProductId).toSet();
      expect(ios.length, CoinPack.all.length);
      expect(android.length, CoinPack.all.length);
    });

    test('a store ID maps back to its pack on either platform', () {
      for (final pack in CoinPack.all) {
        expect(CoinPack.byProductId(pack.iosProductId), pack);
        expect(CoinPack.byProductId(pack.androidProductId), pack);
      }
    });
  });
}
