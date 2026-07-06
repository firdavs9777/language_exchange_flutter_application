import 'package:shared_preferences/shared_preferences.dart';

/// Persists the unsent composer text for a single conversation so it survives
/// leaving the chat screen and full app restarts.
///
/// Keyed by the chat partner's user id — the same value used as the
/// conversation id elsewhere in the chat screen (e.g. `chat_theme_<userId>`).
/// Storage is local-only (SharedPreferences); drafts never leave the device.
///
/// An in-memory [_cache] mirrors the saved drafts and is updated *synchronously*
/// on every [save]/[clear]. This matters because the chat screen writes the
/// draft as the user types, while the chat list reads it back the instant the
/// user navigates back — reading disk there would race the pending write. The
/// list reads the cache instead, so the value is always current.
class ChatDraftService {
  ChatDraftService._();

  static const String _prefix = 'chat_draft_';

  static final Map<String, String> _cache = {};
  static bool _warmed = false;

  static String _key(String conversationId) => '$_prefix$conversationId';

  /// Populates [_cache] from disk on first access.
  static Future<void> _warm() async {
    if (_warmed) return;
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final value = prefs.getString(key);
      if (value != null && value.trim().isNotEmpty) {
        _cache[key.substring(_prefix.length)] = value;
      }
    }
    _warmed = true;
  }

  /// Every saved draft as { conversationId: text } — read by the chat list.
  static Future<Map<String, String>> loadAll() async {
    await _warm();
    return Map<String, String>.from(_cache);
  }

  /// The saved draft for one conversation, or null if none / blank.
  static Future<String?> load(String conversationId) async {
    await _warm();
    final value = _cache[conversationId];
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  /// Saves [text] as the draft, or removes it when blank. The in-memory cache
  /// is updated synchronously (before the await) so concurrent readers see the
  /// new value immediately; disk is updated for cross-restart persistence.
  static Future<void> save(String conversationId, String text) async {
    final isBlank = text.trim().isEmpty;
    if (isBlank) {
      _cache.remove(conversationId);
    } else {
      _cache[conversationId] = text;
    }
    final prefs = await SharedPreferences.getInstance();
    if (isBlank) {
      await prefs.remove(_key(conversationId));
    } else {
      await prefs.setString(_key(conversationId), text);
    }
  }

  /// Removes the draft (e.g. after the message has been sent).
  static Future<void> clear(String conversationId) async {
    _cache.remove(conversationId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(conversationId));
  }
}
