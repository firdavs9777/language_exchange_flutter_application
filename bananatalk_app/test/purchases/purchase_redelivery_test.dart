import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/expired_receipt_memo.dart';
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
    this.verifyWhenVipActive = false,
  });

  final bool verifyWhenVipActive;

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
          return subOk
              ? const RestoreVerifyResult.success()
              : const RestoreVerifyResult.failure('nope');
        },
        verifyCoinPack: (p) async {
          coinVerified.add(p.transactionId!);
          if (coinGate != null) return coinGate!.future;
          return coinOk;
        },
        completeCoinPack: (p) async => coinCompleted.add(p.transactionId!),
        onVipChanged: () => vipRefreshes++,
        onCoinsChanged: () => coinRefreshes++,
        verifyWhenVipActive: verifyWhenVipActive,
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

    test('Android: a late plan-switch purchase is verified for an active VIP',
        () async {
      final h = _Harness(vipActive: true, verifyWhenVipActive: true);
      expect(await h.build().handle(_p(_year)),
          RedeliveryAction.verifiedSubscription);
      expect(h.subVerified, ['tx-1']);
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

  group('expired receipts are sent once', () {
    RestoredPurchase sub({String tx = 'tx-1', DateTime? renewedAt}) =>
        RestoredPurchase(
          productId: _year,
          receipt: 'r-$tx',
          transactionId: tx,
          renewedAt: renewedAt,
        );

    // Builds a handler wired to an in-memory memo, counting verify calls.
    ({PurchaseRedeliveryHandler handler, List<int> calls, ExpiredReceiptMemo memo})
        build({
      required RestoreVerifyResult result,
      bool vipActive = false,
      bool Function(RestoredPurchase)? lapsed,
    }) {
      final calls = <int>[];
      final memo = ExpiredReceiptMemo(userId: 'u1');
      final handler = PurchaseRedeliveryHandler(
        vipProductIds: const {_year},
        coinProductIds: const {_coins},
        canVerify: () => true,
        isVipActive: () async => vipActive,
        verifySubscription: (p) async {
          calls.add(1);
          return result;
        },
        verifyCoinPack: (_) async => true,
        completeCoinPack: (_) async {},
        isKnownExpired: memo.contains,
        rememberExpired: memo.add,
        isLapsed: lapsed,
      );
      return (handler: handler, calls: calls, memo: memo);
    }

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
        'an expired answer is remembered and the same transaction is not sent again',
        () async {
      final b = build(result: const RestoreVerifyResult.failure('Subscription has expired', expired: true));
      expect(await b.handler.handle(sub()), RedeliveryAction.verifyFailed);
      expect(b.calls.length, 1);
      expect(await b.handler.handle(sub()), RedeliveryAction.skippedKnownExpired);
      expect(b.calls.length, 1);
    });

    test('a network failure is not remembered; the next launch tries again',
        () async {
      final b = build(result: const RestoreVerifyResult.failure('SocketException'));
      expect(await b.handler.handle(sub()), RedeliveryAction.verifyFailed);
      expect(await b.handler.handle(sub()), RedeliveryAction.verifyFailed);
      expect(b.calls.length, 2);
      expect(await b.memo.contains(sub()), isFalse);
    });

    test('a lapsed purchase is skipped without a request and not remembered',
        () async {
      final b = build(
          result: const RestoreVerifyResult.success(), lapsed: (_) => true);
      expect(await b.handler.handle(sub()), RedeliveryAction.skippedLapsed);
      expect(await b.handler.handle(sub()), RedeliveryAction.skippedLapsed);
      expect(b.calls, isEmpty);
      expect(await b.memo.contains(sub()), isFalse);
    });

    test('once the clock no longer says lapsed, the same purchase is sent',
        () async {
      var lapsed = true;
      final b = build(
          result: const RestoreVerifyResult.success(),
          lapsed: (_) => lapsed);
      expect(await b.handler.handle(sub()), RedeliveryAction.skippedLapsed);
      lapsed = false;
      expect(await b.handler.handle(sub()),
          RedeliveryAction.verifiedSubscription);
      expect(b.calls.length, 1);
    });

    test('a renewal with the same transaction id but a later renewedAt is sent',
        () async {
      final b = build(result: const RestoreVerifyResult.failure('Subscription has expired', expired: true));
      final first = sub(renewedAt: DateTime.utc(2026, 1, 1));
      final renewed = sub(renewedAt: DateTime.utc(2026, 2, 1));
      await b.handler.handle(first);
      expect(await b.handler.handle(first), RedeliveryAction.skippedKnownExpired);
      expect(await b.handler.handle(renewed), RedeliveryAction.verifyFailed);
      expect(b.calls.length, 2);
    });

    test('an active VIP still short-circuits first', () async {
      final b = build(
          result: const RestoreVerifyResult.success(),
          vipActive: true,
          lapsed: (_) => true);
      expect(await b.handler.handle(sub()), RedeliveryAction.skippedAlreadyVip);
      expect(await b.memo.contains(sub()), isFalse,
          reason: 'nothing is remembered for an active VIP');
      expect(b.calls, isEmpty);
    });

    test('without the new dependencies the handler behaves exactly as before',
        () async {
      var calls = 0;
      final handler = PurchaseRedeliveryHandler(
        vipProductIds: const {_year},
        coinProductIds: const {_coins},
        canVerify: () => true,
        isVipActive: () async => false,
        verifySubscription: (_) async {
          calls++;
          return const RestoreVerifyResult.failure('Subscription has expired', expired: true);
        },
        verifyCoinPack: (_) async => true,
        completeCoinPack: (_) async {},
      );
      expect(await handler.handle(sub()), RedeliveryAction.verifyFailed);
      expect(await handler.handle(sub()), RedeliveryAction.verifyFailed);
      expect(calls, 2);
    });
  });

  group('isServerExpiredAnswer', () {
    test('only 400 plus the exact server phrase counts', () {
      expect(isServerExpiredAnswer(400, 'Subscription has expired'), isTrue);
      expect(isServerExpiredAnswer(400, 'SUBSCRIPTION HAS EXPIRED '), isTrue);
      expect(isServerExpiredAnswer(401, 'jwt expired'), isFalse);
      expect(isServerExpiredAnswer(401, 'Subscription has expired'), isFalse);
      expect(isServerExpiredAnswer(403, 'Subscription has expired'), isFalse);
      expect(isServerExpiredAnswer(500, 'Subscription has expired'), isFalse);
      expect(isServerExpiredAnswer(null, 'Subscription has expired'), isFalse);
      expect(isServerExpiredAnswer(400, 'Token expired'), isFalse);
      expect(isServerExpiredAnswer(400, 'Purchase verification failed'),
          isFalse);
      expect(isServerExpiredAnswer(400, null), isFalse);
    });
  });

  group('clearlyLapsed', () {
    Duration? period(String id) => const Duration(days: 30);
    final now = DateTime.utc(2026, 6, 1);
    RestoredPurchase at(DateTime? t) =>
        RestoredPurchase(productId: _year, receipt: 'r', renewedAt: t);

    test('lapsed only after period plus grace; unknown times are not lapsed', () {
      expect(clearlyLapsed(at(DateTime.utc(2026, 4, 1)), now, planPeriod: period), isTrue);
      expect(clearlyLapsed(at(DateTime.utc(2026, 5, 15)), now, planPeriod: period), isFalse);
      expect(clearlyLapsed(at(null), now, planPeriod: period), isFalse);
      expect(clearlyLapsed(at(DateTime.utc(2026, 1, 1)), now, planPeriod: (_) => null), isFalse);
    });
  });
}
