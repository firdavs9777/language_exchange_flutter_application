import 'package:shared_preferences/shared_preferences.dart';

class WelcomeBackService {
  static const _key = 'last_app_open_ms';
  static const _threshold = Duration(days: 7);

  /// Returns true if the user has been away for 7+ days.
  /// Always updates the stored timestamp to now.
  static Future<bool> checkAndMark() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = prefs.getInt(_key);

    await prefs.setInt(_key, now);

    if (last == null) return false; // first ever launch
    final away = Duration(milliseconds: now - last);
    return away >= _threshold;
  }
}
