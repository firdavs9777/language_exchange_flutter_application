import 'package:shared_preferences/shared_preferences.dart';

/// Daily essay-evaluation quota for non-VIP users.
///
/// Pattern matches the existing translation gate (5/day for free users
/// per `translation_bottom_sheet.dart`). VIP bypass is handled at the
/// call site — this class just tracks usage counters.
///
/// Storage shape is one key per user-day:
///   `exam_essay_evals:<userId>:<YYYY-MM-DD>` → integer count
/// Old days expire naturally because each day uses a new key; on first
/// hit of a new day the prior keys are pruned to keep prefs tidy.
class ExamEssayQuota {
  static const int dailyLimit = 5;
  static const String _keyPrefix = 'exam_essay_evals:';

  /// Current usage for [userId] today (0 when untouched).
  static Future<int> usedToday(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(userId)) ?? 0;
  }

  /// True when the user can still submit an essay today.
  static Future<bool> hasRemaining(String userId) async {
    return (await usedToday(userId)) < dailyLimit;
  }

  /// Increment the counter. Call this after a successful submit.
  /// Cleans up any prior-day keys for the same user along the way.
  static Future<void> recordSubmission(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _key(userId);
    final prefix = '$_keyPrefix$userId:';
    for (final k in prefs.getKeys()) {
      if (k.startsWith(prefix) && k != todayKey) {
        await prefs.remove(k);
      }
    }
    final next = (prefs.getInt(todayKey) ?? 0) + 1;
    await prefs.setInt(todayKey, next);
  }

  static String _key(String userId) {
    final now = DateTime.now();
    final ymd = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return '$_keyPrefix$userId:$ymd';
  }
}
