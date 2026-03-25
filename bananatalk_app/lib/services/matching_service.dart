import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';

/// Matching Service
/// Handles all API calls for smart matching feature
class MatchingService {
  static const String _tag = '🎯 MatchingService';

  static void _log(String message) {
    developer.log(message, name: _tag);
    // ignore: avoid_print
    print('$_tag: $message');
  }
  /// Get authentication token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Get standard headers for API requests
  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Safely decode JSON response
  static Map<String, dynamic>? _safeJsonDecode(String body) {
    final trimmed = body.trim();
    if (trimmed.startsWith('<!DOCTYPE') ||
        trimmed.startsWith('<html') ||
        trimmed.startsWith('<HTML')) {
      return null;
    }

    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Extract error message from response
  static String _getErrorMessage(Map<String, dynamic>? data, String defaultMsg) {
    if (data == null) return defaultMsg;
    return data['message']?.toString() ??
        data['error']?.toString() ??
        defaultMsg;
  }

  /// Get personalized partner recommendations
  static Future<Map<String, dynamic>> getRecommendations({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      final url = Uri.parse('${Endpoints.baseURL}matching/recommendations')
          .replace(queryParameters: queryParams);

      _log('📤 GET $url');
      _log('📤 Headers: ${_getHeaders(token).keys.toList()}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      _log('📥 Response Status: ${response.statusCode}');
      _log('📥 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final count = data?['count'] ?? (data?['data'] as List?)?.length ?? 0;
        _log('✅ Success: Got $count recommendations');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = _getErrorMessage(data, 'Failed to fetch recommendations');
        _log('❌ Error: $error');
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      _log('❌ Exception: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get quick matches (online users)
  /// timeframe: 'online' (5min), 'recent' (1hr), 'today' (24hr)
  static Future<Map<String, dynamic>> getQuickMatches({
    int limit = 10,
    String timeframe = 'recent',
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'timeframe': timeframe,
      };
      final url = Uri.parse('${Endpoints.baseURL}matching/quick')
          .replace(queryParameters: queryParams);

      _log('📤 GET $url (timeframe: $timeframe)');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      _log('📥 Response Status: ${response.statusCode}');
      _log('📥 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final count = data?['count'] ?? (data?['data'] as List?)?.length ?? 0;
        _log('✅ Success: Got $count quick matches');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = _getErrorMessage(data, 'Failed to fetch quick matches');
        _log('❌ Error: $error');
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      _log('❌ Exception: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Find partners by language
  static Future<Map<String, dynamic>> findByLanguage({
    required String language,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      final url = Uri.parse('${Endpoints.baseURL}matching/language/$language')
          .replace(queryParameters: queryParams);

      _log('📤 GET $url (language: $language)');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      _log('📥 Response Status: ${response.statusCode}');
      _log('📥 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final count = data?['count'] ?? (data?['data'] as List?)?.length ?? 0;
        _log('✅ Success: Got $count partners for $language');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = _getErrorMessage(data, 'Failed to find partners');
        _log('❌ Error: $error');
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      _log('❌ Exception: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get similar users to a profile
  static Future<Map<String, dynamic>> getSimilarUsers({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      final url = Uri.parse('${Endpoints.baseURL}matching/similar/$userId')
          .replace(queryParameters: queryParams);

      _log('📤 GET $url (userId: $userId)');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      _log('📥 Response Status: ${response.statusCode}');
      _log('📥 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final count = data?['count'] ?? (data?['data'] as List?)?.length ?? 0;
        _log('✅ Success: Got $count similar users');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = _getErrorMessage(data, 'Failed to find similar users');
        _log('❌ Error: $error');
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      _log('❌ Exception: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
