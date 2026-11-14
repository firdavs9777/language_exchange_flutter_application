import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/expired_receipt_memo.dart';
import 'package:bananatalk_app/services/purchase_restorer.dart';

RestoredPurchase _p(String tx, {DateTime? renewedAt}) => RestoredPurchase(
  productId: 'vip.year',
  receipt: 'receipt-$tx',
  transactionId: tx,
  renewedAt: renewedAt,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keyFor uses the transaction id and renewedAt ms (0 when unknown)', () {
    expect(ExpiredReceiptMemo.keyFor(_p('t1')), 't1|0');
    expect(
      ExpiredReceiptMemo.keyFor(_p('t1', renewedAt: DateTime.utc(2026, 1, 1))),
      't1|${DateTime.utc(2026, 1, 1).millisecondsSinceEpoch}',
    );
  });

  test(
    'without a transaction id the key is a stable hash, not the receipt',
    () {
      const p = RestoredPurchase(
        productId: 'vip.year',
        receipt: 'abc-secret-receipt',
      );
      final key = ExpiredReceiptMemo.keyFor(p);
      expect(key, ExpiredReceiptMemo.keyFor(p));
      expect(key.contains('secret'), isFalse);
      expect(
        key,
        isNot(
          ExpiredReceiptMemo.keyFor(
            const RestoredPurchase(
              productId: 'vip.year',
              receipt: 'abc-other-receipt',
            ),
          ),
        ),
      );
    },
  );

  test('contains is false until added, then true', () async {
    final memo = ExpiredReceiptMemo(userId: 'u1');
    expect(await memo.contains(_p('t1')), isFalse);
    await memo.add(_p('t1'));
    expect(await memo.contains(_p('t1')), isTrue);
  });

  test('memo keeps the newest 50 keys', () async {
    final memo = ExpiredReceiptMemo(userId: 'u1');
    for (var i = 0; i < 55; i++) {
      await memo.add(_p('t$i'));
    }
    final stored = (await SharedPreferences.getInstance()).getStringList(
      'expired_receipts_v1_u1',
    )!;
    expect(stored.length, 50);
    expect(await memo.contains(_p('t0')), isFalse);
    expect(await memo.contains(_p('t4')), isFalse);
    expect(await memo.contains(_p('t5')), isTrue);
    expect(await memo.contains(_p('t54')), isTrue);
  });

  test('memo for one user is invisible to another', () async {
    await ExpiredReceiptMemo(userId: 'u1').add(_p('t1'));
    expect(await ExpiredReceiptMemo(userId: 'u2').contains(_p('t1')), isFalse);
    expect(await ExpiredReceiptMemo(userId: 'u1').contains(_p('t1')), isTrue);
  });

  test('an empty user id stores nothing', () async {
    final memo = ExpiredReceiptMemo(userId: '');
    await memo.add(_p('t1'));
    expect(await memo.contains(_p('t1')), isFalse);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
}
