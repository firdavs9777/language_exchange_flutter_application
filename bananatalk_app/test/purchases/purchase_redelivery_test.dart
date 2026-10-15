import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/purchase_redelivery.dart';
import 'package:bananatalk_app/services/purchase_restorer.dart';

const _year = 'vip.year';
const _coins = 'coins.100';

RestoredPurchase _p(String productId, {String tx = 'tx-1'}) => RestoredPurchase(
      productId: productId,
      receipt: 'r-$tx',
      transactionId: tx,
    );

class _Harness {
  _Harness({
    this.signedIn = true,
    this.vipActive = false,
    this.subOk = true,
    this.coinOk = true,
  });

  final bool signedIn;
  final bool vipActive;
  final bool subOk;
  final bool coinOk;
  Completer<bool>? coinGate;

  final subVerified = <String>[];
  final coinVerified = <String>[];
  final coinCompleted = <String>[];
  int vipRefreshes = 0;
  int coinRefreshes = 0;

  PurchaseRedeliveryHandler build() => PurchaseRedeliveryHandler(
        vipProductIds: const {_year},
        coinProductIds: const {_coins},
        canVerify: () => signedIn,
        isVipActive: () async => vipActive,
        verifySubscription: (p) async {
          subVerified.add(p.transactionId!);
          return subOk;
        },
        verifyCoinPack: (p) async {
          coinVerified.add(p.transactionId!);
          if (coinGate != null) return coinGate!.future;
          return coinOk;
        },
        completeCoinPack: (p) async => coinCompleted.add(p.transactionId!),
        onVipChanged: () => vipRefreshes++,
        onCoinsChanged: () => coinRefreshes++,
      );
}

void main() {
  group('PurchaseRedeliveryHandler', () {
    test('a redelivered subscription is verified when the user is not VIP',
        () async {
      final h = _Harness();
      expect(await h.build().handle(_p(_year)),
          RedeliveryAction.verifiedSubscription);
      expect(h.subVerified, ['tx-1']);
      expect(h.vipRefreshes, 1);
    });

    test('a redelivered subscription is NOT re-sent for an active VIP', () async {
      final h = _Harness(vipActive: true);
      expect(await h.build().handle(_p(_year)),
          RedeliveryAction.skippedAlreadyVip);
      expect(h.subVerified, isEmpty,
          reason: 'the backend would extend the subscription a second time');
    });

    test('a rejected subscription verify does not refresh VIP', () async {
      final h = _Harness(subOk: false);
      expect(await h.build().handle(_p(_year)), RedeliveryAction.verifyFailed);
      expect(h.vipRefreshes, 0);
    });

    test('an unfinished coin pack is verified (server dedupes per transaction) '
        'and only completed on success', () async {
      final h = _Harness();
      expect(await h.build().handle(_p(_coins)),
          RedeliveryAction.verifiedCoinPack);
      expect(h.coinVerified, ['tx-1']);
      expect(h.coinCompleted, ['tx-1']);
      expect(h.coinRefreshes, 1);
    });

    test('a coin pack whose verify fails stays unfinished for a later retry',
        () async {
      final h = _Harness(coinOk: false);
      expect(await h.build().handle(_p(_coins)),
          RedeliveryAction.verifyFailed);
      expect(h.coinCompleted, isEmpty);
      expect(h.coinRefreshes, 0);
    });

    test('the same transaction delivered twice concurrently is verified once',
        () async {
      final h = _Harness()..coinGate = Completer<bool>();
      final handler = h.build();
      final first = handler.handle(_p(_coins));
      final second = await handler.handle(_p(_coins));
      expect(second, RedeliveryAction.ignored);
      h.coinGate!.complete(true);
      expect(await first, RedeliveryAction.verifiedCoinPack);
      expect(h.coinVerified, ['tx-1']);
    });

    test('signed out: nothing is verified or completed', () async {
      final h = _Harness(signedIn: false);
      expect(await h.build().handle(_p(_coins)), RedeliveryAction.ignored);
      expect(await h.build().handle(_p(_year)), RedeliveryAction.ignored);
      expect(h.coinVerified, isEmpty);
      expect(h.coinCompleted, isEmpty);
      expect(h.subVerified, isEmpty);
    });

    test('an unknown product is ignored', () async {
      final h = _Harness();
      expect(await h.build().handle(_p('something.else')),
          RedeliveryAction.ignored);
    });

    test('a throwing verify is swallowed and reported as failed', () async {
      final handler = PurchaseRedeliveryHandler(
        vipProductIds: const {_year},
        coinProductIds: const {_coins},
        canVerify: () => true,
        isVipActive: () async => false,
        verifySubscription: (_) async => throw Exception('offline'),
        verifyCoinPack: (_) async => throw Exception('offline'),
        completeCoinPack: (_) async {},
      );
      expect(await handler.handle(_p(_year)), RedeliveryAction.verifyFailed);
      expect(await handler.handle(_p(_coins, tx: 'c')),
          RedeliveryAction.verifyFailed);
    });
  });
}
