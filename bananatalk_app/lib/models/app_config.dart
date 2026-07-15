class AppAnnouncement {
  final bool active;
  final String id;
  final String title;
  final String body;
  final String emoji;
  final String buttonLabel;
  final String buttonUrl;

  const AppAnnouncement({
    required this.active,
    required this.id,
    required this.title,
    required this.body,
    required this.emoji,
    required this.buttonLabel,
    required this.buttonUrl,
  });

  factory AppAnnouncement.fromJson(Map<String, dynamic> json) {
    return AppAnnouncement(
      active: (json['active'] as bool?) ?? false,
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      emoji: (json['emoji'] as String?) ?? '📢',
      buttonLabel: (json['buttonLabel'] as String?) ?? '',
      buttonUrl: (json['buttonUrl'] as String?) ?? '',
    );
  }
}

class AppConfig {
  final String minVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String iosUrl;
  final String androidUrl;
  final String releaseNotes;
  final AppAnnouncement? announcement;

  /// Workstream D: server-side kill switch for the public Language Rooms
  /// feature. Defaults to `true` so older/dev config payloads that predate
  /// this flag don't accidentally hide the tab.
  final bool roomsEnabled;

  /// Workstream G: server-side kill switch for the Reels tab (mirrors
  /// [roomsEnabled]). Unlike rooms, Reels is a brand-new surface rolling
  /// out behind this flag, so it defaults to `false` — older/dev config
  /// payloads that predate this flag stay hidden until the backend
  /// explicitly turns it on, rather than a half-finished feature flashing
  /// into view.
  final bool reelsEnabled;

  const AppConfig({
    required this.minVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.iosUrl,
    required this.androidUrl,
    required this.releaseNotes,
    this.announcement,
    this.roomsEnabled = true,
    this.reelsEnabled = false,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final announcementJson = json['announcement'] as Map<String, dynamic>?;
    return AppConfig(
      minVersion: (json['minVersion'] as String?) ?? '0.0.0',
      latestVersion: (json['latestVersion'] as String?) ?? '0.0.0',
      forceUpdate: (json['forceUpdate'] as bool?) ?? false,
      iosUrl: (json['iosUrl'] as String?) ?? '',
      androidUrl: (json['androidUrl'] as String?) ?? '',
      releaseNotes: (json['releaseNotes'] as String?) ?? '',
      announcement:
          announcementJson != null
              ? AppAnnouncement.fromJson(announcementJson)
              : null,
      roomsEnabled: (json['roomsEnabled'] as bool?) ?? true,
      reelsEnabled: (json['reelsEnabled'] as bool?) ?? false,
    );
  }
}

/// Compares two semantic version strings (e.g. "1.3.8" vs "1.4.0").
/// Returns negative if [a] < [b], 0 if equal, positive if [a] > [b].
/// Non-numeric or missing segments are treated as 0.
int compareSemver(String a, String b) {
  final aParts = _split(a);
  final bParts = _split(b);
  final length = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < length; i++) {
    final ai = i < aParts.length ? aParts[i] : 0;
    final bi = i < bParts.length ? bParts[i] : 0;
    if (ai != bi) return ai - bi;
  }
  return 0;
}

List<int> _split(String version) {
  // Strip build metadata "1.3.8+10539" -> "1.3.8"
  final clean = version.split('+').first.split('-').first;
  return clean
      .split('.')
      .map((s) => int.tryParse(s.trim()) ?? 0)
      .toList(growable: false);
}
