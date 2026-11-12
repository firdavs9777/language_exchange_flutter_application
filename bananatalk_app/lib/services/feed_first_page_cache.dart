import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last first page of a card feed tab, kept so the next app open shows
/// posts at once and refreshes them behind the scenes.
///
/// Stored as raw server JSON (the same maps `Moments.fromJson` reads) under
/// `feed_first_page_v1_<feedMode>`, with the user id it belongs to: another
/// account never reads it. Only `forYou` and `following` are cached.
class FeedFirstPageCache {
  FeedFirstPageCache({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const String keyPrefix = 'feed_first_page_v1_';
  static const int maxItems = 12;
  static const int maxBytes = 400 * 1024;
  static const Duration maxAge = Duration(days: 7);

  static String _key(String feedMode) => '$keyPrefix$feedMode';

  Future<void> write({
    required String feedMode,
    required String userId,
    required List<Map<String, dynamic>> rawMoments,
  }) async {
    try {
      final encoded = jsonEncode({
        'v': 1,
        'userId': userId,
        'savedAt': _now().millisecondsSinceEpoch,
        'items': rawMoments.take(maxItems).toList(),
      });
      if (utf8.encode(encoded).length > maxBytes) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(feedMode), encoded);
    } catch (_) {
      // A cache that cannot be written is just a cold start next time.
    }
  }

  /// The cached raw moments, or null when missing, of another version or
  /// user, older than [maxAge], or unreadable.
  Future<List<Map<String, dynamic>>?> read({
    required String feedMode,
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_key(feedMode));
      if (text == null) return null;
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      if (decoded['v'] != 1 || decoded['userId'] != userId) return null;
      final savedAt = decoded['savedAt'];
      if (savedAt is! int) return null;
      final age = _now().difference(DateTime.fromMillisecondsSinceEpoch(savedAt));
      if (age > maxAge) return null;
      final items = decoded['items'];
      if (items is! List) return null;
      return items.whereType<Map>().map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith(keyPrefix)) await prefs.remove(key);
      }
    } catch (_) {}
  }
}
