import 'package:bananatalk_app/models/app_config.dart';

/// An admin announcement as the app sees it (backend `PublicAnnouncement`),
/// already resolved to the caller's language.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.emoji,
    this.imageUrl,
    this.buttonLabel,
    this.buttonUrl,
    this.priority = 0,
  });

  final String id;
  final String title;
  final String body;
  final String? emoji;
  final String? imageUrl;
  final String? buttonLabel;
  final String? buttonUrl;
  final int priority;

  /// A button needs a label and a link the app will actually open:
  /// http(s)://host (external), bananatalk://... (app router) or an in-app
  /// path like `/boost`. Protocol-relative `//host` and other schemes are
  /// rejected (preflight ruling R1).
  bool get hasButton =>
      (buttonLabel ?? '').isNotEmpty && isOpenableButtonUrl(buttonUrl ?? '');

  /// Shared with the screen that opens the link.
  static bool isOpenableButtonUrl(String url) {
    final u = url.trim();
    if (u.isEmpty || u.startsWith('//')) return false;
    if (u.startsWith('/')) return true;
    final uri = Uri.tryParse(u);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') return uri.host.isNotEmpty;
    return scheme == 'bananatalk' && u.length > 'bananatalk://'.length;
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    String? opt(String key) {
      final v = json[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final p = json['priority'];
    return Announcement(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      emoji: opt('emoji'),
      imageUrl: opt('imageUrl'),
      buttonLabel: opt('buttonLabel'),
      buttonUrl: opt('buttonUrl'),
      priority: p is num ? p.toInt() : 0,
    );
  }

  /// The single env-var `announcement` older servers send, or null when it
  /// is inactive, unnamed or empty.
  static Announcement? fromLegacy(AppAnnouncement? a) {
    if (a == null || !a.active || a.id.isEmpty) return null;
    if (a.title.isEmpty && a.body.isEmpty) return null;
    return Announcement(
      id: a.id,
      title: a.title,
      body: a.body,
      emoji: a.emoji.isEmpty ? null : a.emoji,
      buttonLabel: a.buttonLabel.isEmpty ? null : a.buttonLabel,
      buttonUrl: a.buttonUrl.isEmpty ? null : a.buttonUrl,
    );
  }
}
