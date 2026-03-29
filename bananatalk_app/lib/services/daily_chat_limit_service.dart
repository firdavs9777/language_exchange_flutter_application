import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks unique chat partners per day for non-VIP users.
/// Free users can chat with max 15 unique people per day.
class DailyChatLimitService {
  static const int maxDailyChats = 15;
  static const String _key = 'daily_chat_partners';
  static const String _dateKey = 'daily_chat_date';

  /// Check if user can open a new chat with [partnerId].
  /// Returns true if already chatted today (existing) or under limit.
  static Future<bool> canChat(String partnerId) async {
    final partners = await _getTodayPartners();
    // Already chatted with this person today — always allow
    if (partners.contains(partnerId)) return true;
    // Under limit — allow
    return partners.length < maxDailyChats;
  }

  /// Record that user opened a chat with [partnerId].
  static Future<void> recordChat(String partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    final partners = await _getTodayPartners();
    if (!partners.contains(partnerId)) {
      partners.add(partnerId);
      await prefs.setString(_key, jsonEncode(partners.toList()));
    }
  }

  /// Get count of unique people chatted with today.
  static Future<int> getTodayCount() async {
    final partners = await _getTodayPartners();
    return partners.length;
  }

  /// Get remaining chats for today.
  static Future<int> getRemaining() async {
    final count = await getTodayCount();
    return (maxDailyChats - count).clamp(0, maxDailyChats);
  }

  static Future<Set<String>> _getTodayPartners() async {
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
