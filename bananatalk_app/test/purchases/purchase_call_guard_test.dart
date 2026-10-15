import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:bananatalk_app/services/purchase_call_guard.dart';

PurchaseDetails _details(String productId, PurchaseStatus status) =>
    PurchaseDetails(
      productID: productId,
      purchaseID: 'tx-$productId',
      verificationData: PurchaseVerificationData(
        localVerificationData: 'r',
        serverVerificationData: 'r',
        source: 'test',
      ),
      transactionDate: '0',
      status: status,
    );

void main() {
  group('PurchaseCallGuard', () {
    test('a second purchase cannot start while one is in flight', () {
      final guard = PurchaseCallGuard();
      expect(guard.begin('vip.month'), isTrue);
      expect(guard.begin('vip.year'), isFalse);
    });

    test('a timed-out purchase releases the guard so a retry works', () async {
      final guard = PurchaseCallGuard();
      expect(guard.begin('vip.month'), isTrue);
      final result = await guard.wait(timeout: const Duration(milliseconds: 10));
      expect(result, isNull);
      expect(guard.inFlight, isFalse);
      expect(guard.begin('vip.month'), isTrue,
          reason: 'before the fix the pending flag stayed set until restart');
    });

    test('a store "pending" event that never resolves does not block forever',
        () async {
      final guard = PurchaseCallGuard();
      guard.begin('vip.month');
      guard.markStorePending();
      expect(guard.isPending, isTrue);
      await guard.wait(timeout: const Duration(milliseconds: 10));
      expect(guard.isPending, isFalse);
      expect(guard.begin('vip.month'), isTrue);
    });

    test('a cancel / error resolves the call with null and releases it',
        () async {
      for (final status in [PurchaseStatus.canceled, PurchaseStatus.error]) {
        final guard = PurchaseCallGuard();
        guard.begin('coins.100');
        final waiting = guard.wait(timeout: const Duration(seconds: 5));
        expect(guard.offer(_details('coins.100', status)), isTrue);
        expect(await waiting, isNull);
        expect(guard.begin('coins.100'), isTrue);
      }
    });

    test('the purchased transaction for the in-flight product resolves the call',
        () async {
      final guard = PurchaseCallGuard();
      guard.begin('vip.year');
      final waiting = guard.wait(timeout: const Duration(seconds: 5));
      final bought = _details('vip.year', PurchaseStatus.purchased);
      expect(guard.offer(bought), isTrue);
      expect(await waiting, same(bought));
      expect(guard.inFlight, isFalse);
    });

    test('a redelivered transaction for another product is NOT taken by the call',
        () async {
      final guard = PurchaseCallGuard();
      guard.begin('vip.year');
      final waiting = guard.wait(timeout: const Duration(seconds: 5));
      final old = _details('coins.500', PurchaseStatus.purchased);
      expect(guard.offer(old), isFalse,
          reason: 'it belongs to the redelivery handler, not this purchase');
      expect(guard.inFlight, isTrue);
      final bought = _details('vip.year', PurchaseStatus.purchased);
      guard.offer(bought);
      expect(await waiting, same(bought));
    });

    test('a Google Play cancel/error with an EMPTY product id resolves the call',
        () async {
      // in_app_purchase_android reports "user canceled" / billing errors that
      // carry no purchase as PurchaseDetails(productID: '').
      for (final status in [PurchaseStatus.canceled, PurchaseStatus.error]) {
        final guard = PurchaseCallGuard();
        guard.begin('vip.year');
        final waiting = guard.wait(timeout: const Duration(seconds: 5));
        expect(guard.offer(_details('', status)), isTrue);
        expect(await waiting, isNull);
        expect(guard.inFlight, isFalse);
      }
    });

    test('an empty-product "purchased" event is not taken as the purchase', () {
      final guard = PurchaseCallGuard();
      guard.begin('vip.year');
      expect(guard.offer(_details('', PurchaseStatus.purchased)), isFalse);
      expect(guard.inFlight, isTrue);
    });

    test('offer with nothing in flight returns false', () {
      final guard = PurchaseCallGuard();
      expect(guard.offer(_details('vip.year', PurchaseStatus.purchased)),
          isFalse);
    });

    test('abort releases a call that could not be started', () {
      final guard = PurchaseCallGuard();
      guard.begin('vip.year');
      guard.abort();
      expect(guard.inFlight, isFalse);
      expect(guard.begin('vip.year'), isTrue);
    });
  });
}
