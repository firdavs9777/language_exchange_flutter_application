import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';

/// Service for managing user interactions (skip, wave, etc.)
class InteractionService {
  static const String _skippedCacheKey = 'cached_skipped_users';
  static const String _wavedCacheKey = 'cached_waved_users';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Skip a user (won't see them for 24 hours)
  static Future<Map<String, dynamic>> skipUser(String targetUserId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}interactions/skip');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'targetUserId': targetUserId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Also cache locally
        await _addToLocalCache(_skippedCacheKey, targetUserId);

        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        // Still cache locally even if server fails
        await _addToLocalCache(_skippedCacheKey, targetUserId);
        return {'success': false, 'error': 'Server error', 'cached': true};
      }
    } catch (e) {
      // Cache locally on network error
      await _addToLocalCache(_skippedCacheKey, targetUserId);
      return {'success': false, 'error': e.toString(), 'cached': true};
    }
  }

  /// Wave to a user
  static Future<Map<String, dynamic>> waveUser(String targetUserId, {String? message}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}interactions/wave');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'targetUserId': targetUserId,
          if (message != null) 'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _addToLocalCache(_wavedCacheKey, targetUserId);
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        await _addToLocalCache(_wavedCacheKey, targetUserId);
        return {'success': false, 'error': 'Server error', 'cached': true};
      }
    } catch (e) {
      await _addToLocalCache(_wavedCacheKey, targetUserId);
      return {'success': false, 'error': e.toString(), 'cached': true};
    }
  }

  /// Get all excluded user IDs from server
  static Future<Set<String>> getExcludedUsers() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}interactions/excluded');

      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ids = data['data'] ?? [];

        // Update local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_skippedCacheKey, []);
        await prefs.setStringList(_wavedCacheKey, []);

        return ids.map((id) => id.toString()).toSet();
      }
    } catch (e) {
    }

    // Fallback to local cache
    return await getLocalExcludedUsers();
  }

  /// Get skipped user IDs from server
  static Future<Set<String>> getSkippedUsers() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}interactions/skipped');

      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ids = data['data'] ?? [];
        return ids.map((id) => id.toString()).toSet();
      }
    } catch (e) {
    }

    // Fallback to local cache
    return await _getLocalCache(_skippedCacheKey);
  }

  /// Get waved user IDs from server
  static Future<Set<String>> getWavedUsers() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}interactions/waved');

      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ids = data['data'] ?? [];
        return ids.map((id) => id.toString()).toSet();
      }
    } catch (e) {
    }

    // Fallback to local cache
    return await _getLocalCache(_wavedCacheKey);
  }

  /// Undo skip for a user
  static Future<bool> undoSkip(String targetUserId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}interactions/skip/$targetUserId');

      final response = await http.delete(url, headers: _getHeaders(token));

      // Remove from local cache
      await _removeFromLocalCache(_skippedCacheKey, targetUserId);

      return response.statusCode == 200;
    } catch (e) {
      await _removeFromLocalCache(_skippedCacheKey, targetUserId);
      return false;
    }
  }

  /// Clear all skips (reset)
  static Future<bool> clearAllSkips() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}interactions/skips/clear');

      final response = await http.delete(url, headers: _getHeaders(token));

      // Clear local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_skippedCacheKey);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Sync local cache with server (call on app start)
  static Future<void> syncWithServer() async {
    try {
      // Get local cached interactions
      final localSkipped = await _getLocalCache(_skippedCacheKey);
      final localWaved = await _getLocalCache(_wavedCacheKey);

      if (localSkipped.isEmpty && localWaved.isEmpty) return;

      // Batch sync to server
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}interactions/batch');

      final interactions = <Map<String, dynamic>>[];

      for (final userId in localSkipped) {
        interactions.add({'targetUserId': userId, 'type': 'skip'});
      }
      for (final userId in localWaved) {
        interactions.add({'targetUserId': userId, 'type': 'wave'});
      }

      await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'interactions': interactions}),
      );

      // Clear local cache after successful sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_skippedCacheKey);
      await prefs.remove(_wavedCacheKey);

    } catch (e) {
    }
  }

  // === Local cache helpers ===

  static Future<void> _addToLocalCache(String key, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(key) ?? [];
    if (!existing.contains(userId)) {
      existing.add(userId);
      await prefs.setStringList(key, existing);
    }
  }

  static Future<void> _removeFromLocalCache(String key, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(key) ?? [];
    existing.remove(userId);
    await prefs.setStringList(key, existing);
  }

  static Future<Set<String>> _getLocalCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];
    return list.toSet();
  }

  static Future<Set<String>> getLocalExcludedUsers() async {
    final skipped = await _getLocalCache(_skippedCacheKey);
    final waved = await _getLocalCache(_wavedCacheKey);
    return {...skipped, ...waved};
  }
}
