import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/service/endpoints.dart';

/// Backend-synced store for the "Most Used" tab phrases, with a
/// SharedPreferences cache so the panel renders instantly while the
/// network request flies and stays usable offline.
///
/// On signed-out / offline access [load] falls through to the cache.
/// [add] / [remove] update the cache optimistically before calling the
/// backend; if the backend rejects, the cache is reconciled to the
/// authoritative server response on the next [load].
class SavedPhrasesService {
  static String _cacheKey(String userId) => 'chat_saved_phrases_$userId';

  /// Default phrases seeded when the user has never saved one. Matches the
  /// HelloTalk first-launch UX where the panel isn't empty.
  static const List<String> _defaults = [
    "How's your day going? Working or chilling?",
    "Long time no chatting — how have you been?",
    "Nice to meet you here!",
    "Are you learning my language too?",
    "What part of the country are you in?",
  ];

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<List<String>> _readCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_cacheKey(userId));
    if (stored == null) return List<String>.from(_defaults);
    return stored;
  }

  static Future<void> _writeCache(String userId, List<String> phrases) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cacheKey(userId), phrases);
  }

  static List<String> _parseList(dynamic body) {
    if (body is Map && body['data'] is List) {
      return (body['data'] as List).map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Load phrases: prefer server, fall back to cache on any network error
  /// or when the user is signed out.
  static Future<List<String>> load(String userId) async {
    if (userId.isEmpty) return const [];
    final token = await _token();
    if (token == null) return _readCache(userId);
    try {
      final res = await http.get(
        Uri.parse('${Endpoints.baseURL}${Endpoints.chatPhrasesURL}'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final list = _parseList(jsonDecode(res.body));
        await _writeCache(userId, list);
        return list;
      }
    } catch (_) {
      // Fall through to cache.
    }
    return _readCache(userId);
  }

  /// Optimistically prepend to cache, then sync to server.
  /// Server is the source of truth — its response overwrites cache.
  static Future<void> add(String userId, String phrase) async {
    final trimmed = phrase.trim();
    if (trimmed.isEmpty || userId.isEmpty) return;

    final current = await _readCache(userId);
    if (!current.contains(trimmed)) {
      await _writeCache(userId, [trimmed, ...current]);
    }

    final token = await _token();
    if (token == null) return;
    try {
      final res = await http.post(
        Uri.parse('${Endpoints.baseURL}${Endpoints.chatPhrasesURL}'),
        headers: _headers(token),
        body: jsonEncode({'phrase': trimmed}),
      );
      if (res.statusCode == 200) {
        final list = _parseList(jsonDecode(res.body));
        await _writeCache(userId, list);
      }
    } catch (_) {
      // Cache already updated optimistically; next load will reconcile.
    }
  }

  /// Optimistically drop from cache, then sync to server.
  static Future<void> remove(String userId, String phrase) async {
    if (userId.isEmpty) return;

    final current = await _readCache(userId);
    final next = current.where((p) => p != phrase).toList();
    await _writeCache(userId, next);

    final token = await _token();
    if (token == null) return;
    try {
      final res = await http.delete(
        Uri.parse('${Endpoints.baseURL}${Endpoints.chatPhrasesURL}'),
        headers: _headers(token),
        body: jsonEncode({'phrase': phrase}),
      );
      if (res.statusCode == 200) {
        final list = _parseList(jsonDecode(res.body));
        await _writeCache(userId, list);
      }
    } catch (_) {
      // Cache already updated optimistically; next load will reconcile.
    }
  }
}
