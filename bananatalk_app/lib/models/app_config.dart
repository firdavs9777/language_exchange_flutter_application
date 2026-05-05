class AppConfig {
  final String minVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String iosUrl;
  final String androidUrl;
  final String releaseNotes;

  const AppConfig({
    required this.minVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.iosUrl,
    required this.androidUrl,
    required this.releaseNotes,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      minVersion: (json['minVersion'] as String?) ?? '0.0.0',
      latestVersion: (json['latestVersion'] as String?) ?? '0.0.0',
      forceUpdate: (json['forceUpdate'] as bool?) ?? false,
      iosUrl: (json['iosUrl'] as String?) ?? '',
      androidUrl: (json['androidUrl'] as String?) ?? '',
      releaseNotes: (json['releaseNotes'] as String?) ?? '',
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
