import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/announcement.dart';

/// User-scoped (not device-level, so logout clears it).
const String kAnnouncementsSeenKey = 'announcements_seen_ids';

/// Key the env-var-only modal wrote per dismissed id; still honoured.
const String _legacyDismissedPrefix = 'dismissed_announcement_';

const int _maxSeenIds = 200;

class AnnouncementSeenStore {
  /// Seen ids, or null when storage is unreadable (callers then show
  /// nothing rather than repeat a pop-up).
  static Future<Set<String>?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = <String>{};
      // A wrong-typed value throws here: unreadable, so null (show nothing).
      seen.addAll(prefs.getStringList(kAnnouncementsSeenKey) ?? const []);
      for (final k in prefs.getKeys()) {
        if (k.startsWith(_legacyDismissedPrefix)) {
          seen.add(k.substring(_legacyDismissedPrefix.length));
        }
      }
      return seen;
    } catch (_) {
      return null;
    }
  }

  static Future<void> add(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // A wrong-typed value throws: leave it alone rather than overwrite.
      var ids = List<String>.of(prefs.getStringList(kAnnouncementsSeenKey) ?? const []);
      if (ids.contains(id)) return;
      ids.add(id);
      if (ids.length > _maxSeenIds) ids = ids.sublist(ids.length - _maxSeenIds);
      await prefs.setStringList(kAnnouncementsSeenKey, ids);
    } catch (_) {}
  }
}

/// Highest-priority unseen announcement (first wins a tie: the server
/// already sorts priority desc, startsAt desc). [live] empty means an old
/// backend or no DB announcement: fall back to the legacy single field.
Announcement? pickAnnouncement({
  required List<Announcement> live,
  required Announcement? legacy,
  required Set<String> seen,
}) {
  final pool = live.isNotEmpty ? live : [if (legacy != null) legacy];
  Announcement? best;
  for (final a in pool) {
    if (a.id.isEmpty || seen.contains(a.id)) continue;
    if (best == null || a.priority > best.priority) best = a;
  }
  return best;
}
