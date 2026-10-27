import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:bananatalk_app/services/android_purchase_service.dart';

const _coins = {'coins.100', 'coins.500'};

PurchaseDetails _past(
  String productId, {
  PurchaseStatus status = PurchaseStatus.purchased,
  String token = 'token-1',
}) =>
    PurchaseDetails(
      purchaseID: 'GPA.$token',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: token,
        source: 'google_play',
      ),
      transactionDate: '0',
      status: status,
    );

void main() {
  test('a paid, unconsumed coin pack is picked up for verify', () {
    final out = AndroidPurchaseService.unfinishedCoinPacks(
      [_past('coins.100')],
      _coins,
    );
    expect(out.map((p) => p.productID), ['coins.100']);
  });

  test('subscriptions are left alone (restore handles them)', () {
    final out = AndroidPurchaseService.unfinishedCoinPacks(
      [_past('vip.monthly'), _past('coins.500', token: 't2')],
      _coins,
    );
    expect(out.map((p) => p.productID), ['coins.500']);
  });

  test('a pending pack (not paid yet) is not verified', () {
    final out = AndroidPurchaseService.unfinishedCoinPacks(
      [_past('coins.100', status: PurchaseStatus.pending)],
      _coins,
    );
    expect(out, isEmpty);
  });

  test('a pack without a purchase token cannot be verified', () {
    final out = AndroidPurchaseService.unfinishedCoinPacks(
      [_past('coins.100', token: '')],
      _coins,
    );
    expect(out, isEmpty);
  });
}
