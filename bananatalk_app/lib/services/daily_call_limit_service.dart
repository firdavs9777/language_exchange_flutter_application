import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily call count for non-VIP users.
/// Free users can make max 3 calls per day.
class DailyCallLimitService {
  static const int maxDailyCalls = 3;
  static const String _key = 'daily_call_ids';
  static const String _dateKey = 'daily_call_date';

  /// Check if user can make another call today.
  static Future<bool> canCall() async {
    final calls = await _getTodayCalls();
    return calls.length < maxDailyCalls;
  }

  /// Record that user made a call.
  static Future<void> recordCall(String callId) async {
    final prefs = await SharedPreferences.getInstance();
    final calls = await _getTodayCalls();
    if (!calls.contains(callId)) {
      calls.add(callId);
      await prefs.setString(_key, jsonEncode(calls.toList()));
    }
  }

  /// Get count of calls made today.
  static Future<int> getTodayCount() async {
    final calls = await _getTodayCalls();
    return calls.length;
  }

  /// Get remaining calls for today.
  static Future<int> getRemaining() async {
    final count = await getTodayCount();
    return (maxDailyCalls - count).clamp(0, maxDailyCalls);
  }

  static Future<Set<String>> _getTodayCalls() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = prefs.getString(_dateKey);

    // Reset if new day
    if (storedDate != today) {
      await prefs.setString(_dateKey, today);
      await prefs.setString(_key, '[]');
      return {};
    }

    final raw = prefs.getString(_key);
    if (raw == null) return {};

    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }
}
