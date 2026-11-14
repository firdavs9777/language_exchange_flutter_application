import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_purchase_events.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';

// The purchase screens drive the App Store / Play billing plugins, which a
// test cannot run; what they report is the pure mapping below, plus the
// logging wrapper, so those are what is tested.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<({String placement, String action, String flowId, String? detail})>
  logged;
  const flow = PaywallFlow(
    placement: PaywallPlacement.dmCap,
    flowId: 'entry-flow',
  );

  setUp(() {
    logged = [];
    paywallLogSpy = (f, action, detail) => logged.add((
      placement: f.placement,
      action: action,
      flowId: f.flowId,
      detail: detail,
    ));
  });
  tearDown(() => paywallLogSpy = null);

  test(
    'vip purchase: started, succeeded carry the plan product id and the flow id from the entry point',
    () {
      paywallLogPurchase(
        flow,
        PurchaseOutcome.started,
        productId: 'vip_monthly',
      );
      paywallLogPurchase(
        flow,
        PurchaseOutcome.succeeded,
        productId: 'vip_monthly',
      );
      expect(logged.map((l) => l.action), [
        'purchase_started',
        'purchase_succeeded',
      ]);
      expect(logged.map((l) => l.detail), ['vip_monthly', 'vip_monthly']);
      expect(
        logged.every(
          (l) => l.flowId == 'entry-flow' && l.placement == 'dm_cap',
        ),
        isTrue,
      );
    },
  );

  test(
    'vip purchase cancel logs dismissed; verify failure logs purchase_failed verify',
    () {
      paywallLogPurchase(flow, PurchaseOutcome.cancelled);
      paywallLogPurchase(flow, PurchaseOutcome.verifyFailed);
      paywallLogPurchase(flow, PurchaseOutcome.error);
      expect(logged.map((l) => l.action), [
        'dismissed',
        'purchase_failed',
        'purchase_failed',
      ]);
      expect(logged.map((l) => l.detail), [null, 'verify', 'error']);
    },
  );

  test(
    'coin purchase: started then succeeded; failure logs purchase_failed',
    () {
      paywallLogPurchase(flow, PurchaseOutcome.started, productId: 'coins_500');
      paywallLogPurchase(
        flow,
        purchaseOutcomeForCoinVerify(CoinVerifyOutcome.credited),
        productId: 'coins_500',
      );
      paywallLogPurchase(
        flow,
        purchaseOutcomeForCoinVerify(CoinVerifyOutcome.failed),
        productId: 'coins_500',
      );
      expect(logged.map((l) => l.action), [
        'purchase_started',
        'purchase_succeeded',
        'purchase_failed',
      ]);
      expect(logged.map((l) => l.detail), ['coins_500', 'coins_500', 'verify']);
    },
  );

  test(
    'coin verify outcomes map: already credited succeeds, linked elsewhere fails',
    () {
      expect(
        purchaseOutcomeForCoinVerify(CoinVerifyOutcome.credited),
        PurchaseOutcome.succeeded,
      );
      expect(
        purchaseOutcomeForCoinVerify(CoinVerifyOutcome.alreadyCredited),
        PurchaseOutcome.succeeded,
      );
      expect(
        purchaseOutcomeForCoinVerify(CoinVerifyOutcome.linkedToAnotherAccount),
        PurchaseOutcome.verifyFailed,
      );
      expect(
        purchaseOutcomeForCoinVerify(CoinVerifyOutcome.failed),
        PurchaseOutcome.verifyFailed,
      );
    },
  );

  test('a screen opened without a flow reports nothing', () {
    paywallLogPurchase(null, PurchaseOutcome.started, productId: 'x');
    expect(logged, isEmpty);
  });
}
