import 'dart:convert';

import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-image display rotation, chosen by the viewer and remembered on device.
///
/// Some older moment photos are stored already rotated: they were uploaded
/// before the server honoured EXIF orientation, which baked the wrong
/// rotation into the pixels and stripped the orientation tag. Nothing can
/// detect those automatically — a wrongly-rotated portrait and a genuine
/// landscape are indistinguishable once the tag is gone — so this lets a
/// person supply the missing quarter-turn by hand.
///
/// Scope: this is **local to the device**. Correcting it for everyone would
/// need the rotation stored server-side against the moment.
class ImageRotationStore extends ChangeNotifier {
  ImageRotationStore._();

  static final ImageRotationStore instance = ImageRotationStore._();

  static const String _prefsKey = 'moment_image_rotations';

  /// Normalized image URL -> quarter turns clockwise (0-3).
  Map<String, int> _turns = <String, int>{};

  bool _loaded = false;
  Future<void>? _loading;

  /// Loads persisted rotations once. Safe to call from every widget that
  /// needs them; later calls await the same future.
  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _turns = decoded.map(
            (key, value) => MapEntry('$key', (value as num).toInt() & 3),
          );
        }
      }
    } catch (e) {
      // A corrupt or unreadable entry just means no saved rotations.
      debugPrint('ImageRotationStore: failed to load rotations: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  String _key(String url) => ImageUtils.normalizeImageUrl(url);

  /// Quarter turns clockwise to apply to [url]. 0 when nothing is stored.
  int turnsFor(String url) => _turns[_key(url)] ?? 0;

  /// Advances [url] by one quarter turn clockwise and persists the result.
  Future<void> rotateClockwise(String url) async {
    final key = _key(url);
    final next = ((_turns[key] ?? 0) + 1) & 3;
    if (next == 0) {
      _turns.remove(key);
    } else {
      _turns[key] = next;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_turns.isEmpty) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, jsonEncode(_turns));
      }
    } catch (e) {
      // Rotation still applies for this session; it just won't survive a
      // restart.
      debugPrint('ImageRotationStore: failed to persist rotations: $e');
    }
  }
}
