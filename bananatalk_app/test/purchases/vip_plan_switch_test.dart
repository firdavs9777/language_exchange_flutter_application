import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/services/vip_plan_switch.dart';

PurchaseDetails _purchase(
  String productId, {
  PurchaseStatus status = PurchaseStatus.purchased,
  String token = 'token',
}) =>
    PurchaseDetails(
      productID: productId,
      purchaseID: 'GPA.$productId',
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: token,
        source: 'google_play',
      ),
      transactionDate: '0',
      status: status,
    );

final _monthly = VipPlan.monthly.androidProductId;
final _yearly = VipPlan.yearly.androidProductId;
final _quarterly = VipPlan.quarterly.androidProductId;

/// Fake Play: records what the switch asked for and answers with [result].
class _FakeStore {
  _FakeStore({this.owned, this.result, this.queryThrows = false});

  final PurchaseDetails? owned;
  final PurchaseDetails? result;
  final bool queryThrows;
  final calls = <(VipPlan, PurchaseDetails, ReplacementMode)>[];

  VipPlanSwitcher switcher() => VipPlanSwitcher(
        queryOwned: () async {
          if (queryThrows) throw Exception('billing unavailable');
          return owned;
        },
        buy: (target, old, mode) async {
          calls.add((target, old, mode));
          return result;
        },
      );
}

void main() {
  group('vipReplacementMode', () {
    test('to a longer plan charges the full price now', () {
      expect(vipReplacementMode(from: VipPlan.monthly, to: VipPlan.yearly),
          ReplacementMode.chargeFullPrice);
      expect(vipReplacementMode(from: VipPlan.quarterly, to: VipPlan.yearly),
          ReplacementMode.chargeFullPrice);
    });

    test('to a shorter plan waits for the paid period to end', () {
      expect(vipReplacementMode(from: VipPlan.yearly, to: VipPlan.monthly),
          ReplacementMode.deferred);
      expect(vipReplacementMode(from: VipPlan.quarterly, to: VipPlan.monthly),
          ReplacementMode.deferred);
    });
  });

  group('vipPlanOffer', () {
    test('a non-VIP buys any plan', () {
      for (final plan in VipPlan.values) {
        expect(vipPlanOffer(isVip: false, ownedPlan: null, plan: plan),
            VipPlanOffer.buy);
      }
    });

    test('a VIP never re-buys the plan they have; others are switches', () {
      expect(
          vipPlanOffer(
              isVip: true, ownedPlan: VipPlan.monthly, plan: VipPlan.monthly),
          VipPlanOffer.current);
      expect(
          vipPlanOffer(
              isVip: true, ownedPlan: VipPlan.monthly, plan: VipPlan.yearly),
          VipPlanOffer.switchPlan);
    });

    test('a VIP without a Play subscription (iOS, promo) is offered nothing',
        () {
      for (final plan in VipPlan.values) {
        expect(vipPlanOffer(isVip: true, ownedPlan: null, plan: plan), isNull);
      }
    });
  });

  group('ownedVipSubscription', () {
    test('picks the VIP subscription, not a coin pack', () {
      final sub = _purchase(_yearly);
      expect(ownedVipSubscription([_purchase('coins.100'), sub]), same(sub));
    });

    test('skips a pending purchase', () {
      expect(
          ownedVipSubscription(
              [_purchase(_monthly, status: PurchaseStatus.pending)]),
          isNull);
    });

    test('none owned -> null', () {
      expect(ownedVipSubscription(const []), isNull);
      expect(vipPlanForAndroidProduct('coins.100'), isNull);
      expect(vipPlanForAndroidProduct(_quarterly), VipPlan.quarterly);
    });
  });

  group('VipPlanSwitcher', () {
    test('monthly -> yearly replaces the owned token, full price, and returns '
        'the new purchase to verify', () async {
      final old = _purchase(_monthly, token: 'old-token');
      final bought = _purchase(_yearly, token: 'new-token');
      final store = _FakeStore(owned: old, result: bought);

      final result = await store.switcher().run(VipPlan.yearly);

      expect(result.status, VipPlanSwitchStatus.switched);
      expect(result.purchase, same(bought));
      expect(store.calls, hasLength(1));
      final (target, replaced, mode) = store.calls.single;
      expect(target, VipPlan.yearly);
      expect(replaced.verificationData.serverVerificationData, 'old-token');
      expect(mode, ReplacementMode.chargeFullPrice);
    });

    test('yearly -> monthly is deferred; Play\'s empty "purchased" event means '
        'scheduled, nothing to verify', () async {
      final store = _FakeStore(
        owned: _purchase(_yearly),
        result: _purchase(''),
      );

      final result = await store.switcher().run(VipPlan.monthly);

      expect(result.status, VipPlanSwitchStatus.scheduled);
      expect(result.purchase, isNull);
      expect(store.calls.single.$3, ReplacementMode.deferred);
    });

    test('the same plan is never bought again', () async {
      final store = _FakeStore(owned: _purchase(_monthly));
      final result = await store.switcher().run(VipPlan.monthly);
      expect(result.status, VipPlanSwitchStatus.samePlan);
      expect(store.calls, isEmpty);
    });

    test('no Play subscription to replace -> no purchase at all', () async {
      for (final owned in [null, _purchase('coins.100')]) {
        final store = _FakeStore(owned: owned);
        final result = await store.switcher().run(VipPlan.yearly);
        expect(result.status, VipPlanSwitchStatus.noSubscription);
        expect(store.calls, isEmpty,
            reason: 'a plain purchase here would be a second subscription');
      }
    });

    test('store query failure -> canceled, no purchase', () async {
      final store = _FakeStore(queryThrows: true);
      final result = await store.switcher().run(VipPlan.yearly);
      expect(result.status, VipPlanSwitchStatus.canceled);
      expect(store.calls, isEmpty);
    });

    test('the user closes the Play sheet -> canceled', () async {
      final store = _FakeStore(owned: _purchase(_monthly), result: null);
      final result = await store.switcher().run(VipPlan.yearly);
      expect(result.status, VipPlanSwitchStatus.canceled);
    });

    test('a purchase for some other product is not taken as the switch',
        () async {
      final store = _FakeStore(
        owned: _purchase(_monthly),
        result: _purchase('coins.100'),
      );
      final result = await store.switcher().run(VipPlan.yearly);
      expect(result.status, VipPlanSwitchStatus.canceled);
    });
  });
}
