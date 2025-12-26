import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class ProfileVisitorService {
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

  /// Record a profile visit
  /// [userId] - The ID of the profile being visited
  /// [source] - Where the visit came from ('search', 'moments', 'chat', 'direct', 'followers')
  static Future<Map<String, dynamic>> recordProfileVisit({
    required String userId,
    String source = 'direct',
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.recordProfileVisitURL(userId)}',
      );

      // Determine device type (ios, android, or web)
      String deviceType = 'web'; // default for web/desktop
      try {
        if (Platform.isIOS) {
          deviceType = 'ios';
        } else if (Platform.isAndroid) {
          deviceType = 'android';
        }
      } catch (e) {
        // Platform not available on web, keep 'web' as default
      }

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'source': source, 'deviceType': deviceType}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Visit recorded',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to record visit',
        };
      }
    } catch (e) {
      print('Error recording profile visit: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get list of profile visitors
  /// [userId] - The ID of the profile owner
  /// [limit] - Number of visitors to return (default: 20)
  /// [page] - Page number for pagination (default: 1)
  static Future<Map<String, dynamic>> getProfileVisitors({
    required String userId,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};

      if (limit != 20) queryParams['limit'] = limit.toString();
      if (page != 1) queryParams['page'] = page.toString();

      final uri = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.getProfileVisitorsURL(userId)}',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(uri, headers: _getHeaders(token));

      // Check if response is HTML (endpoint doesn't exist)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'error':
              'Visitor tracking not available. Backend needs to be updated.',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'count': data['count'] ?? 0,
          'stats': data['stats'],
          'visitors': data['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch visitors',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Visitor tracking not available'};
    }
  }

  /// Get visitor statistics for the current user
  static Future<Map<String, dynamic>> getMyVisitorStats() async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.getMyVisitorStatsURL}',
      );

      final response = await http.get(url, headers: _getHeaders(token));

      // Check if response is HTML (endpoint doesn't exist)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'error':
              'API endpoint not available. Backend needs to be updated with visitor tracking features.',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Backend returns: { success: true, data: { totalVisits, uniqueVisitors, ... } }
        return {
          'success': true,
          'stats': data['data'], // The stats are directly in data
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch stats',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Visitor tracking not available'};
    }
  }

  /// Clear visitor history
  static Future<Map<String, dynamic>> clearMyVisitors() async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.clearMyVisitorsURL}',
      );

      final response = await http.delete(url, headers: _getHeaders(token));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Visitor history cleared',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to clear visitors',
        };
      }
    } catch (e) {
      print('Error clearing visitors: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get list of profiles the current user has visited
  static Future<Map<String, dynamic>> getVisitedProfiles({
    int? limit,
    int? skip,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};

      if (limit != null) queryParams['limit'] = limit.toString();
      if (skip != null) queryParams['skip'] = skip.toString();

      final uri = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.getVisitedProfilesURL}',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(uri, headers: _getHeaders(token));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'profiles': data['data']['profiles'] ?? [],
          'pagination': data['data']['pagination'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch visited profiles',
        };
      }
    } catch (e) {
      print('Error fetching visited profiles: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
