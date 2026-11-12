import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When the app may offer "Share as a moment" (spec 7.2).
///
/// - at most one offer per local day (an offer counts once it is shown);
/// - after two consecutive dismissals, none for the next 7 days;
/// - an accept resets the dismissal count.
///
/// State is per user: every key starts with `share_offer_` and none is in
/// `kDeviceLevelPrefsKeys`, so sign-out removes them. "Day" is the calendar
/// date of the instant given, read in the device's local time zone.
class ShareOfferPolicy {
  static const _lastShownKey = 'share_offer_last_shown_day';
  static const _dismissalsKey = 'share_offer_consecutive_dismissals';
  static const _blockedUntilKey = 'share_offer_blocked_until_day';

  /// Days with no offers after the second consecutive dismissal.
  static const quietDays = 7;

  /// Local calendar day as `yyyy-mm-dd`; compares correctly as a string.
  static String _day(DateTime t) {
    final l = t.toLocal();
    return '${l.year.toString().padLeft(4, '0')}-'
        '${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }

  Future<bool> canOffer(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _day(now);
    if (prefs.getString(_lastShownKey) == today) return false;
    final blockedUntil = prefs.getString(_blockedUntilKey);
    if (blockedUntil != null && today.compareTo(blockedUntil) < 0) {
      return false;
    }
    return true;
  }

  Future<void> recordShown(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastShownKey, _day(now));
  }

  Future<void> recordDismissed(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_dismissalsKey) ?? 0) + 1;
    if (count >= 2) {
      final l = now.toLocal();
      // Day + 8 is the first day offers are allowed again.
      await prefs.setString(
        _blockedUntilKey,
        _day(DateTime(l.year, l.month, l.day + quietDays + 1)),
      );
      await prefs.setInt(_dismissalsKey, 0);
    } else {
      await prefs.setInt(_dismissalsKey, count);
    }
  }

  Future<void> recordAccepted(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissalsKey, 0);
  }
}

/// Overridable in tests. Stateless (reads SharedPreferences on use), but
/// listed as user-scoped in session_reset.dart.
final shareOfferPolicyProvider = Provider<ShareOfferPolicy>(
  (ref) => ShareOfferPolicy(),
);
