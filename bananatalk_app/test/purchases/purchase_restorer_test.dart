import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/purchase_restorer.dart';

const _month = 'vip.month';
const _year = 'vip.year';
const _coins = 'coins.100';

final _now = DateTime.utc(2026, 10, 15, 12);

RestoredPurchase _sub(
  String productId, {
  DateTime? renewedAt,
  String tx = 'tx',
}) =>
    RestoredPurchase(
      productId: productId,
      receipt: 'receipt-$tx',
      transactionId: tx,
      renewedAt: renewedAt,
    );

class _Harness {
  _Harness({
    this.restored = const [],
    this.restoreThrows = false,
    this.vipActive = false,
    this.verifyResult = const RestoreVerifyResult.success(),
    this.checkExpiry = false,
  });

  final List<RestoredPurchase> restored;
  final bool restoreThrows;
  final bool vipActive;
  final RestoreVerifyResult verifyResult;
  final bool checkExpiry;
  final verified = <RestoredPurchase>[];

  PurchaseRestorer build() => PurchaseRestorer(
        restore: () async {
          if (restoreThrows) throw Exception('store down');
          return restored;
        },
        vipProductIds: const {_month, _year},
        isVipActive: () async => vipActive,
        verify: (p) async {
          verified.add(p);
          return verifyResult;
        },
        planPeriod: (id) => id == _year
            ? const Duration(days: 366)
            : const Duration(days: 31),
        checkExpiry: checkExpiry,
        now: () => _now,
      );
}

void main() {
  group('PurchaseRestorer', () {
    test('nothing came back from the store -> nothingToRestore', () async {
      final h = _Harness();
      expect(await h.build().run(), RestoreOutcome.nothingToRestore);
      expect(h.verified, isEmpty);
    });

    test('only coin packs came back -> nothingToRestore, coins never verified here',
        () async {
      final h = _Harness(restored: [_sub(_coins)]);
      expect(await h.build().run(), RestoreOutcome.nothingToRestore);
      expect(h.verified, isEmpty,
          reason: 'consumables are not restorable; a restore must never grant coins');
    });

    test('a store error -> failed', () async {
      final h = _Harness(restoreThrows: true);
      expect(await h.build().run(), RestoreOutcome.failed);
    });

    test('a subscription is sent through the purchase verify -> restored',
        () async {
      final sub = _sub(_month, tx: 'a');
      final h = _Harness(restored: [sub]);
      expect(await h.build().run(), RestoreOutcome.restored);
      expect(h.verified, [sub]);
    });

    test('verifies exactly one subscription: the most recently renewed', () async {
      final older = _sub(_month, renewedAt: _now.subtract(const Duration(days: 40)), tx: 'old');
      final newest = _sub(_month, renewedAt: _now.subtract(const Duration(days: 3)), tx: 'new');
      final middle = _sub(_month, renewedAt: _now.subtract(const Duration(days: 20)), tx: 'mid');
      final h = _Harness(restored: [older, newest, middle]);
      expect(await h.build().run(), RestoreOutcome.restored);
      expect(h.verified.map((p) => p.transactionId), ['new'],
          reason: 'every extra verify would extend VIP server-side');
    });

    test('already VIP -> alreadyActive without calling verify', () async {
      final h = _Harness(restored: [_sub(_year)], vipActive: true);
      expect(await h.build().run(), RestoreOutcome.alreadyActive);
      expect(h.verified, isEmpty,
          reason: 'the backend extends an active subscription on every verify');
    });

    test('verify rejected -> failed', () async {
      final h = _Harness(
        restored: [_sub(_year)],
        verifyResult: const RestoreVerifyResult.failure('nope'),
      );
      expect(await h.build().run(), RestoreOutcome.failed);
    });

    test('verify throwing -> failed', () async {
      final restorer = PurchaseRestorer(
        restore: () async => [_sub(_year)],
        vipProductIds: const {_year},
        isVipActive: () async => false,
        verify: (_) async => throw Exception('offline'),
        planPeriod: (_) => const Duration(days: 366),
        now: () => _now,
      );
      expect(await restorer.run(), RestoreOutcome.failed);
    });

    test('a VIP status lookup failure does not block the restore', () async {
      final restorer = PurchaseRestorer(
        restore: () async => [_sub(_year)],
        vipProductIds: const {_year},
        isVipActive: () async => throw Exception('offline'),
        verify: (_) async => const RestoreVerifyResult.success(),
        planPeriod: (_) => const Duration(days: 366),
        now: () => _now,
      );
      expect(await restorer.run(), RestoreOutcome.restored);
    });

    group('expiry check (iOS returns lapsed subscriptions too)', () {
      test('a lapsed subscription is not sent to the server', () async {
        final h = _Harness(
          checkExpiry: true,
          restored: [
            _sub(_month, renewedAt: _now.subtract(const Duration(days: 60))),
          ],
        );
        expect(await h.build().run(), RestoreOutcome.nothingToRestore);
        expect(h.verified, isEmpty);
      });

      test('a current subscription inside its period is restored', () async {
        final h = _Harness(
          checkExpiry: true,
          restored: [
            _sub(_year, renewedAt: _now.subtract(const Duration(days: 200))),
          ],
        );
        expect(await h.build().run(), RestoreOutcome.restored);
      });

      test('a renewal a little late is still inside the grace window', () async {
        final h = _Harness(
          checkExpiry: true,
          restored: [
            _sub(_month, renewedAt: _now.subtract(const Duration(days: 32))),
          ],
        );
        expect(await h.build().run(), RestoreOutcome.restored);
      });

      test('an unknown renewal date is left for the server to judge', () async {
        final h = _Harness(checkExpiry: true, restored: [_sub(_month)]);
        expect(await h.build().run(), RestoreOutcome.restored);
      });

      test('Android (checkExpiry off) never filters: Play only returns live subs',
          () async {
        final h = _Harness(
          restored: [
            _sub(_month, renewedAt: _now.subtract(const Duration(days: 400))),
          ],
        );
        expect(await h.build().run(), RestoreOutcome.restored);
      });
    });
  });

}
