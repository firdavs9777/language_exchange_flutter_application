import 'package:shared_preferences/shared_preferences.dart';

/// Whether video plays with sound, remembered across sessions.
///
/// One preference for reels AND stories. Reels had a local `bool _muted` that
/// reset on every open and told stories nothing; stories had no control at
/// all. Muting is a decision about the room you are in, not about one screen,
/// so making it per-screen means making it twice.
///
/// Reads are cached in memory after the first load: this is consulted on every
/// page change in a scrolling feed, which is far too hot for a disk read.
class VideoSoundPreference {
  VideoSoundPreference._();

  static final VideoSoundPreference instance = VideoSoundPreference._();

  static const String _key = 'video_muted';

  /// Null means the user has never chosen.
  ///
  /// Tri-state on purpose. Reels deliberately starts unmuted -- opening a reel
  /// is a deliberate act -- while a story autoplays the moment a ring is
  /// tapped and so starts muted. Collapsing that to one boolean would silently
  /// overrule one of those decisions. Once the user DOES choose, the choice is
  /// shared: muting is about the room you are in, not the screen.
  bool? _cached;
  bool _loaded = false;

  /// The fallback when the user has never chosen. Stories pass true, reels
  /// false.
  static const bool defaultMuted = true;

  bool get hasExplicitChoice => _cached != null;

  bool get isMuted => _cached ?? defaultMuted;

  /// What this surface should do, given its own default.
  bool isMutedOr({required bool fallback}) => _cached ?? fallback;

  /// Loads the stored value once. Safe to call repeatedly.
  Future<bool?> load() async {
    if (_loaded) return _cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cached = prefs.getBool(_key);
    } catch (_) {
      // A preference that cannot be read is not worth failing playback over;
      // the surface falls back to its own default.
      _cached = null;
    }
    _loaded = true;
    return _cached;
  }

  /// Sets the value and persists it. The in-memory value updates immediately
  /// so the UI never waits on the disk write.
  Future<void> setMuted(bool muted) async {
    _cached = muted;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, muted);
    } catch (_) {
      // The session still honours the choice; only persistence is lost.
    }
  }

  /// Flips from [fallback] the first time, since there is nothing to flip yet.
  Future<bool> toggle({bool fallback = defaultMuted}) async {
    await setMuted(!isMutedOr(fallback: fallback));
    return isMuted;
  }

  /// Tests only — clears the in-memory cache so a fresh load is observable.
  void resetForTest() {
    _cached = null;
    _loaded = false;
  }
}
