import 'package:shared_preferences/shared_preferences.dart';

class WelcomeBackService {
  static const _key = 'last_app_open_ms';
  static const _threshold = Duration(days: 7);

  /// True if the user has been away for 7+ days since the last launch that
  /// was marked. Read-only: call [markOpened] once the launch is settled.
  static Future<bool> isDue() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_key);
    if (last == null) return false; // first ever launch
    final away = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch - last);
    return away >= _threshold;
  }

  /// Records this launch as the last open. A due welcome-back is marked only
  /// once its sheet actually shows, so an update dialog that took the launch's
  /// pop-up budget leaves it armed for the next launch.
  static Future<void> markOpened() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, DateTime.now().millisecondsSinceEpoch);
  }
}
