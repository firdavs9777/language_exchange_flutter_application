import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The disk cache behind the AI Study tab's first paint; stateless (the entry
/// is keyed by user id), so app-scoped. Overridden in tests.
final studyHubCacheProvider = Provider<StudyHubCache>((ref) => StudyHubCache());

/// What the top of the tab showed when it was last live: enough to paint the
/// streak chip, the language and level chip and the pack row's progress on
/// the next cold open, before the network answers. Only ever a first paint:
/// nothing here decides what a tap does.
class StudyHubSnapshot {
  const StudyHubSnapshot({
    required this.dateKey,
    required this.packDateKey,
    this.language,
    this.level,
    required this.streak,
    required this.stationsDone,
    required this.stationsTotal,
    required this.savedAt,
  });

  /// The device's local date (`YYYY-MM-DD`) when this was written. The pack's
  /// own `dateKey` may differ around midnight; the snapshot is compared with
  /// the device date again at read time.
  final String dateKey;

  /// The pack's own date key. A snapshot is only ever written from a pack
  /// whose key equals the device date, and only painted while it still does.
  final String packDateKey;

  /// The language chip's text, and the CEFR level the chip showed.
  final String? language;
  final String? level;
  final int streak;
  final int stationsDone;
  final int stationsTotal;
  final DateTime savedAt;
}

/// One small entry per signed-in user under `study_hub_v1_<userId>`, with the
/// user id stored inside it too, so a read for one user never returns
/// another's. User-scoped (not on the device-level allow-list in
/// `session_prefs.dart`), so sign-out removes it; `AuthService` also calls
/// [clearAll] beside the other first-page caches. A corrupt, foreign or
/// old-format entry reads as null and is removed, never thrown.
class StudyHubCache {
  StudyHubCache({
    DateTime Function()? now,
    Future<SharedPreferences> Function()? prefs,
  }) : _now = now ?? DateTime.now,
       _prefs = prefs ?? SharedPreferences.getInstance;

  final DateTime Function() _now;
  final Future<SharedPreferences> Function() _prefs;

  static const String keyPrefix = 'study_hub_v1_';

  /// Bumped by every [clearAll] (sign-out). A [write]
  /// takes it before its first await: a write begun before a clear is
  /// dropped, even if the clear has not removed the key yet.
  static int _epoch = 0;

  /// Taken by a caller before its first await and passed to [write], so a
  /// write begun before a [clearAll] is dropped.
  int get epoch => _epoch;

  /// A snapshot may be painted only when the device day is still the day it
  /// was saved, its pack was today's pack, and it is under 24 hours old.
  /// Checked when painting, not only when it was read from disk.
  static const Duration maxAge = Duration(hours: 24);

  bool isFresh(StudyHubSnapshot s) {
    final today = todayKey();
    final age = _now().difference(s.savedAt);
    return s.dateKey == today &&
        s.packDateKey == today &&
        !age.isNegative &&
        age < maxAge;
  }

  static String keyFor(String userId) => '$keyPrefix$userId';

  /// The device's local date as `YYYY-MM-DD`: what "today" means for a snapshot.
  String todayKey() {
    final d = _now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  /// The signed-in user's id (the `userId` pref); null when nobody is.
  Future<String?> signedInUserId() async {
    try {
      final id = (await _prefs()).getString('userId');
      return id == null || id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String userId, StudyHubSnapshot s, {int? epoch}) async {
    if (userId.isEmpty) return;
    final started = epoch ?? _epoch;
    try {
      final prefs = await _prefs();
      if (started != _epoch) return;
      await prefs.setString(
        keyFor(userId),
        jsonEncode({
          'v': 1,
          'userId': userId,
          'dateKey': s.dateKey,
          'packDateKey': s.packDateKey,
          'language': s.language,
          'level': s.level,
          'streak': s.streak,
          'stationsDone': s.stationsDone,
          'stationsTotal': s.stationsTotal,
          'savedAt': s.savedAt.millisecondsSinceEpoch,
        }),
      );
    } catch (_) {
      // A cache that cannot be written is just a cold start next time.
    }
  }

  /// [userId]'s snapshot, or null when missing or unusable (then removed).
  Future<StudyHubSnapshot?> read(String userId) async {
    if (userId.isEmpty) return null;
    final key = keyFor(userId);
    SharedPreferences prefs;
    try {
      prefs = await _prefs();
    } catch (_) {
      return null;
    }
    try {
      final text = prefs.getString(key);
      if (text == null) return null;
      final snapshot = _parse(text, userId);
      if (snapshot == null) await prefs.remove(key);
      return snapshot;
    } catch (_) {
      try {
        await prefs.remove(key);
      } catch (_) {}
      return null;
    }
  }

  StudyHubSnapshot? _parse(String text, String userId) {
    final d = jsonDecode(text);
    if (d is! Map || d['v'] != 1 || d['userId'] != userId) return null;
    final dateKey = d['dateKey'];
    final packDateKey = d['packDateKey'];
    final language = d['language'];
    final level = d['level'];
    final streak = d['streak'];
    final done = d['stationsDone'];
    final total = d['stationsTotal'];
    final savedAt = d['savedAt'];
    if (dateKey is! String ||
        packDateKey is! String ||
        (language != null && language is! String) ||
        (level != null && level is! String) ||
        streak is! int ||
        done is! int ||
        total is! int ||
        savedAt is! int ||
        streak < 0 ||
        done < 0 ||
        total < 0) {
      return null;
    }
    return StudyHubSnapshot(
      dateKey: dateKey,
      packDateKey: packDateKey,
      language: language as String?,
      level: level as String?,
      streak: streak,
      stationsDone: done,
      stationsTotal: total,
      savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
    );
  }

  /// A station was just committed: moves today's saved progress to
  /// [stationsRemaining] stations left, so a kill mid-pack still opens on the
  /// right count. Touches nothing without a signed-in user and a snapshot
  /// written today.
  Future<void> recordStationCompleted({required int stationsRemaining}) async {
    // Before the first await: a sign-out clear that runs while this reads
    // must also stop the write below.
    final started = _epoch;
    final userId = await signedInUserId();
    if (userId == null) return;
    final s = await read(userId);
    if (s == null || !isFresh(s) || s.stationsTotal <= 0) return;
    final done = (s.stationsTotal - stationsRemaining).clamp(
      0,
      s.stationsTotal,
    );
    await write(
      userId,
      StudyHubSnapshot(
        dateKey: s.dateKey,
        packDateKey: s.packDateKey,
        language: s.language,
        level: s.level,
        streak: s.streak,
        stationsDone: done,
        stationsTotal: s.stationsTotal,
        savedAt: _now(),
      ),
      epoch: started,
    );
  }

  /// Every user's snapshot (sign-out).
  Future<void> clearAll() async {
    _epoch++;
    try {
      final prefs = await _prefs();
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith(keyPrefix)) await prefs.remove(key);
      }
    } catch (_) {}
  }
}
