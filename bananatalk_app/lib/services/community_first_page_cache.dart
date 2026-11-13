import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The disk cache behind the Partners list and the daily matches; stateless
/// (every entry is keyed by user id), so app-scoped. Overridden in tests.
final communityFirstPageCacheProvider = Provider<CommunityFirstPageCache>(
  (ref) => CommunityFirstPageCache(),
);

/// What [CommunityFirstPageCache.read] hands back: the raw server rows and
/// the caller's own notes about them.
class CommunityFirstPageSnapshot {
  const CommunityFirstPageSnapshot({required this.rows, required this.meta});

  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> meta;
}

/// The first page of the Partners list and today's daily matches, kept so the
/// next cold open paints them at once and replaces them with the network
/// result. Same contract as `FeedFirstPageCache`: raw server JSON, one entry
/// per signed-in user and slot under
/// `community_first_page_v1_<userId>_<slot>`, and the user id and slot are
/// stored inside the entry too, so a read for one user never returns
/// another's rows. User-scoped (not on the device-level allow-list in
/// `session_prefs.dart`), and cleared explicitly on sign-out.
///
/// Only written and read while the server's `communityFastListEnabled` switch
/// is on; callers check it. A corrupt, old-format, oversized, foreign or
/// expired entry is ignored and removed, never thrown.
class CommunityFirstPageCache {
  CommunityFirstPageCache({
    DateTime Function()? now,
    Future<SharedPreferences> Function()? prefs,
  })  : _now = now ?? DateTime.now,
        _prefs = prefs ?? SharedPreferences.getInstance;

  final DateTime Function() _now;
  final Future<SharedPreferences> Function() _prefs;

  static const String keyPrefix = 'community_first_page_v1_';
  static const String partners = 'partners';
  static const String daily = 'daily';
  static const List<String> slots = [partners, daily];

  static const int maxRows = 20;
  static const int maxBytes = 300 * 1024;

  /// Partners entries expire after this; daily entries at their stored
  /// `nextRefreshAt` (see [nextRefreshAtKey]) and never later than this.
  static const Duration maxAge = Duration(hours: 24);

  /// The `meta` key a daily entry must carry (ISO-8601): the batch is not
  /// painted at or after it.
  static const String nextRefreshAtKey = 'nextRefreshAt';

  /// Bumped by every [clearAll] (sign-out, "clear all cache"). A caller takes
  /// [epoch] before its fetch and passes it to [write]: a write begun before
  /// a clear is dropped, even if the stored user id has not been removed yet.
  static int _epoch = 0;

  int get epoch => _epoch;

  static String keyFor(String userId, String slot) =>
      '$keyPrefix${userId}_$slot';

  /// The signed-in user's id, resolved as the feed cache does (the `userId`
  /// pref); null when nobody is signed in.
  Future<String?> signedInUserId() async {
    try {
      final id = (await _prefs()).getString('userId');
      return id == null || id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  /// Stores at most [maxRows] [rows] for [userId]'s [slot]. Rows that are the
  /// user's own profile are dropped. An entry over [maxBytes] is not stored
  /// and the previous one is removed: a stale page is worse than none.
  Future<void> write({
    required String userId,
    required String slot,
    required List<Map<String, dynamic>> rows,
    Map<String, dynamic>? meta,
    int? epoch,
  }) async {
    if (userId.isEmpty || !slots.contains(slot)) return;
    try {
      final prefs = await _prefs();
      if (epoch != null && epoch != _epoch) return;
      final kept = rows
          .where((r) => rowUserId(r) != userId)
          .take(maxRows)
          .toList();
      final encoded = jsonEncode({
        'v': 1,
        'userId': userId,
        'slot': slot,
        'savedAt': _now().millisecondsSinceEpoch,
        'meta': meta ?? const <String, dynamic>{},
        'rows': kept,
      });
      if (utf8.encode(encoded).length > maxBytes) {
        await prefs.remove(keyFor(userId, slot));
        return;
      }
      // Checked again with no await before the store: a clear that started
      // during the encoding wins.
      if (epoch != null && epoch != _epoch) return;
      await prefs.setString(keyFor(userId, slot), encoded);
    } catch (_) {
      // A cache that cannot be written is just a cold start next time.
    }
  }

  /// [userId]'s [slot], or null when missing or unusable (in which case the
  /// entry is removed).
  Future<CommunityFirstPageSnapshot?> read({
    required String userId,
    required String slot,
  }) async {
    if (userId.isEmpty || !slots.contains(slot)) return null;
    final key = keyFor(userId, slot);
    SharedPreferences prefs;
    try {
      prefs = await _prefs();
    } catch (_) {
      return null;
    }
    try {
      final text = prefs.getString(key);
      if (text == null) return null;
      final snapshot = _parse(text, userId: userId, slot: slot);
      if (snapshot == null) await prefs.remove(key);
      return snapshot;
    } catch (_) {
      try {
        await prefs.remove(key);
      } catch (_) {}
      return null;
    }
  }

  CommunityFirstPageSnapshot? _parse(
    String text, {
    required String userId,
    required String slot,
  }) {
    if (utf8.encode(text).length > maxBytes) return null;
    final decoded = jsonDecode(text);
    if (decoded is! Map) return null;
    if (decoded['v'] != 1 ||
        decoded['userId'] != userId ||
        decoded['slot'] != slot) {
      return null;
    }
    final savedAt = decoded['savedAt'];
    if (savedAt is! int) return null;
    final now = _now();
    final age = now.difference(DateTime.fromMillisecondsSinceEpoch(savedAt));
    if (age.isNegative || age > maxAge) return null;
    final rawMeta = decoded['meta'];
    final rawRows = decoded['rows'];
    if (rawMeta is! Map || rawRows is! List || rawRows.length > maxRows) {
      return null;
    }
    final meta = Map<String, dynamic>.from(rawMeta);
    if (slot == daily) {
      final next = meta[nextRefreshAtKey];
      final at = next is String ? DateTime.tryParse(next) : null;
      if (at == null || !now.isBefore(at)) return null;
    }
    return CommunityFirstPageSnapshot(
      rows: rawRows
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .where((r) => rowUserId(r) != userId)
          .toList(),
      meta: meta,
    );
  }

  /// Removes [userId]'s [slot] entry.
  Future<void> remove({required String userId, required String slot}) async {
    if (userId.isEmpty) return;
    try {
      await (await _prefs()).remove(keyFor(userId, slot));
    } catch (_) {}
  }

  /// Drops [targetId] (just blocked, or skipped from the daily batch) from
  /// both of [userId]'s slots, so no cold start paints them again. Writes
  /// only when an entry actually held them.
  Future<void> removeUser(String userId, String targetId) async {
    if (userId.isEmpty || targetId.isEmpty) return;
    try {
      final prefs = await _prefs();
      for (final slot in slots) {
        final key = keyFor(userId, slot);
        final text = prefs.getString(key);
        if (text == null) continue;
        final decoded = jsonDecode(text);
        if (decoded is! Map || decoded['rows'] is! List) {
          await prefs.remove(key);
          continue;
        }
        final rows = decoded['rows'] as List;
        final kept = rows
            .where((r) => r is! Map || rowUserId(r) != targetId)
            .toList();
        if (kept.length == rows.length) continue;
        await prefs.setString(key, jsonEncode({...decoded, 'rows': kept}));
      }
    } catch (_) {
      // Unreadable: the next fresh page overwrites it anyway.
    }
  }

  /// Every entry of every user (sign-out, Data & Storage "clear all").
  Future<void> clearAll() async {
    _epoch++;
    try {
      final prefs = await _prefs();
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith(keyPrefix)) await prefs.remove(key);
      }
    } catch (_) {}
  }

  /// The person a row is about: a Partners row is a user (`_id`), a daily row
  /// wraps one (`user._id`, or a bare id).
  static String? rowUserId(Map<dynamic, dynamic> row) {
    final user = row['user'];
    if (user is Map) return (user['_id'] ?? user['id'])?.toString();
    if (user != null) return user.toString();
    return (row['_id'] ?? row['id'])?.toString();
  }
}
