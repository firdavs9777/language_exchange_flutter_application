import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/purchase_restorer.dart';

/// True only for the server's own "expired" answer: status exactly 400 and
/// the body text exactly `Subscription has expired` (trimmed, any case). A 401
/// "jwt expired" or any other text must never count, or a valid paid receipt
/// could be remembered as dead and never sent again.
bool isServerExpiredAnswer(int? statusCode, Object? error) {
  if (statusCode != 400 || error == null) return false;
  return error.toString().trim().toLowerCase() == 'subscription has expired';
}

/// Which store transactions the server already refused as expired, per user.
///
/// StoreKit redelivers every unfinished transaction at each launch, and an
/// expired subscription can never verify, so without a memo the same receipt
/// is sent (and refused) at every launch. Stored under
/// `expired_receipts_v1_<userId>`, which is not a device-level key, so
/// sign-out clears it. Holds hashes and ids only, never a receipt.
class ExpiredReceiptMemo {
  ExpiredReceiptMemo({required this.userId, SharedPreferences? prefs})
    : _prefs = prefs;

  static const keyPrefix = 'expired_receipts_v1_';
  static const maxKeys = 50;

  final String userId;
  final SharedPreferences? _prefs;

  String get _prefsKey => '$keyPrefix$userId';

  Future<SharedPreferences> _store() async =>
      _prefs ?? await SharedPreferences.getInstance();

  /// `<transactionId or receipt hash>|<renewedAt ms or 0>`. A renewal of the
  /// same subscription has a later `renewedAt`, so it has a different key.
  static String keyFor(RestoredPurchase p) {
    final id = (p.transactionId != null && p.transactionId!.isNotEmpty)
        ? p.transactionId!
        : _receiptHash(p.receipt);
    return '$id|${p.renewedAt?.millisecondsSinceEpoch ?? 0}';
  }

  /// FNV-1a over the UTF-8 bytes, 32 bits, plus the length: short and stable
  /// across launches (`String.hashCode` is not).
  static String _receiptHash(String receipt) {
    var h = 0x811c9dc5;
    for (final b in utf8.encode(receipt)) {
      h ^= b;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return 'h${h.toRadixString(16)}-${receipt.length}';
  }

  List<String> _read(SharedPreferences prefs) =>
      prefs.getStringList(_prefsKey) ?? const [];

  Future<bool> contains(RestoredPurchase p) async {
    if (userId.isEmpty) return false;
    try {
      return _read(await _store()).contains(keyFor(p));
    } catch (_) {
      return false;
    }
  }

  /// Remembers [p], keeping the newest [maxKeys].
  Future<void> add(RestoredPurchase p) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await _store();
      final key = keyFor(p);
      final keys = [..._read(prefs)]..remove(key);
      keys.add(key);
      final kept = keys.length > maxKeys
          ? keys.sublist(keys.length - maxKeys)
          : keys;
      await prefs.setStringList(_prefsKey, kept);
    } catch (_) {}
  }
}
