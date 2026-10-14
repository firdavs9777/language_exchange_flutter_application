import 'package:shared_preferences/shared_preferences.dart';

/// The last `studyHubEnabled` value app-config returned, kept on the device so
/// a cold start can pick the AI Study page without waiting for the network.
///
/// AI Study is the first screen, and app-config is first requested when the
/// tab shell mounts, so the flag is never known on the first frame. Waiting
/// for it put a spinner on every launch; guessing and swapping later flashed
/// the wrong page. Instead the page is chosen once per launch from this value
/// (null -> the legacy page), and a changed flag applies from the next launch.
class StudyHubFlagCache {
  StudyHubFlagCache._();

  static const String prefsKey = 'study_hub_enabled_last';

  /// Loaded in `main()` before `runApp`; null when never stored or unreadable.
  static bool? lastKnown;

  static void loadFrom(SharedPreferences prefs) {
    try {
      lastKnown = prefs.getBool(prefsKey);
    } catch (_) {
      lastKnown = null;
    }
  }

  static Future<void> remember(bool enabled) async {
    lastKnown = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, enabled);
    } catch (_) {}
  }
}
