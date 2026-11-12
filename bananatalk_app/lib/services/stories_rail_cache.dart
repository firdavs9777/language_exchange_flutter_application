import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// What [StoriesRailCache.read] hands back: the raw server arrays.
class StoriesRailSnapshot {
  const StoriesRailSnapshot({required this.data, required this.discover});

  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> discover;
}

/// The last stories rail, kept so the next app open draws the rings at once
/// and refreshes them behind the scenes. Same contract as
/// `FeedFirstPageCache`: raw server JSON (the maps `UserStories.fromJson`
/// reads) under `stories_rail_v1` with the user id it belongs to, so another
/// account never reads it; at most [maxAge] old; user-scoped (not on the
/// device-level allow-list in `session_prefs.dart`), so sign-out removes it.
class StoriesRailCache {
  StoriesRailCache({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const String key = 'stories_rail_v1';
  static const int maxData = 20;
  static const int maxDiscover = 10;
  static const int maxBytes = 400 * 1024;
  static const Duration maxAge = Duration(days: 7);

  /// An oversized entry is removed rather than left behind: a stale rail is
  /// worse than none.
  Future<void> write({
    required String userId,
    required List<Map<String, dynamic>> rawData,
    required List<Map<String, dynamic>> rawDiscover,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode({
        'v': 1,
        'userId': userId,
        'savedAt': _now().millisecondsSinceEpoch,
        'data': rawData.take(maxData).toList(),
        'discover': rawDiscover.take(maxDiscover).toList(),
      });
      if (utf8.encode(encoded).length > maxBytes) {
        await prefs.remove(key);
        return;
      }
      await prefs.setString(key, encoded);
    } catch (_) {
      // A cache that cannot be written is just a cold start next time.
    }
  }

  /// The cached rail, or null when missing, of another version or user, older
  /// than [maxAge], or unreadable.
  Future<StoriesRailSnapshot?> read({required String userId}) async {
    try {
      if (userId.isEmpty) return null;
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(key);
      if (text == null) return null;
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      if (decoded['v'] != 1 || decoded['userId'] != userId) return null;
      final savedAt = decoded['savedAt'];
      if (savedAt is! int) return null;
      final age = _now().difference(DateTime.fromMillisecondsSinceEpoch(savedAt));
      if (age > maxAge) return null;
      List<Map<String, dynamic>> maps(Object? v) => v is List
          ? v.whereType<Map>().map(Map<String, dynamic>.from).toList()
          : <Map<String, dynamic>>[];
      if (decoded['data'] is! List) return null;
      return StoriesRailSnapshot(
        data: maps(decoded['data']),
        discover: maps(decoded['discover']),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}
