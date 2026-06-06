import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';

/// AdminService — Flutter client for the /api/v1/admin/* endpoints
/// added in Step 15. Mirrors the existing ReportService pattern
/// (lib/providers/provider_root/report_provider.dart): manual http.*
/// calls, header construction inline, returns Map<String, dynamic>
/// with `success` + `data` / `error` shape.
class AdminService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Search users by free-text + optional facet filters.
  Future<Map<String, dynamic>> searchUsers({
    String? q,
    bool bannedOnly = false,
    bool adminsOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
      if (bannedOnly) params['banned'] = 'true';
      if (adminsOnly) params['adminsOnly'] = 'true';

      final uri = Uri.parse('${Endpoints.baseURL}admin/users')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'],
          'pagination': body['pagination'],
        };
      }
      return {
        'success': false,
        'error': body['error'] ?? 'Failed to search users',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get admin-view detail for a single user (richer than the public
  /// /users/:id endpoint; includes ban + role metadata + recent
  /// audit log entries targeting this user).
  Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}admin/users/$userId'),
        headers: headers,
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {
        'success': false,
        'error': body['error'] ?? 'Failed to load user',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Ban a user manually (no report required). Reason is required
  /// server-side; an empty reason will return 400.
  Future<Map<String, dynamic>> banUser(String userId, String reason) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}admin/users/$userId/ban'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      }
      return {
        'success': false,
        'error': body['error'] ?? 'Ban failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Unban a user. Reason is required server-side.
  Future<Map<String, dynamic>> unbanUser(String userId, String reason) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}admin/users/$userId/unban'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      }
      return {
        'success': false,
        'error': body['error'] ?? 'Unban failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Change a user's role. role must be 'admin' or 'user'. Reason is
  /// required server-side.
  Future<Map<String, dynamic>> changeRole(
    String userId,
    String role,
    String reason,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Endpoints.baseURL}admin/users/$userId/role'),
        headers: headers,
        body: json.encode({'role': role, 'reason': reason}),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {
        'success': false,
        'error': body['error'] ?? 'Role change failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Aggregate user stats for the analytics screen.
  /// Returns total + byGender + byRole + byMode + counters + top languages.
  Future<Map<String, dynamic>> getStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}admin/stats'),
        headers: headers,
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {
        'success': false,
        'error': body['error'] ?? 'Failed to load stats',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// User activity overview — active counts + recently active users list.
  Future<Map<String, dynamic>> getActivity({int limit = 50}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${Endpoints.baseURL}admin/activity')
          .replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(uri, headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['error'] ?? 'Failed to load activity'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// AI feature usage aggregation (total + byFeature + byDay).
  Future<Map<String, dynamic>> getAIUsage({
    String? feature,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = <String, String>{};
      if (feature != null) params['feature'] = feature;
      if (from != null) params['from'] = from.toUtc().toIso8601String();
      if (to != null) params['to'] = to.toUtc().toIso8601String();
      final uri = Uri.parse('${Endpoints.baseURL}admin/ai-usage')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri, headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'error': body['error'] ?? 'Failed to load AI usage'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Paginated raw AI usage log entries with populated user info.
  Future<Map<String, dynamic>> getAIUsageLogs({
    String? feature,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (feature != null) params['feature'] = feature;
      if (from != null) params['from'] = from.toUtc().toIso8601String();
      if (to != null) params['to'] = to.toUtc().toIso8601String();
      final uri = Uri.parse('${Endpoints.baseURL}admin/ai-usage/logs')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'],
          'pagination': body['pagination'],
        };
      }
      return {'success': false, 'error': body['error'] ?? 'Failed to load logs'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Paginated audit log. All filter parameters are optional.
  Future<Map<String, dynamic>> getAuditLog({
    String? moderatorId,
    String? targetId,
    String? action,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (moderatorId != null) params['moderatorId'] = moderatorId;
      if (targetId != null) params['targetId'] = targetId;
      if (action != null) params['action'] = action;

      final uri = Uri.parse('${Endpoints.baseURL}admin/audit-log')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'],
          'pagination': body['pagination'],
        };
      }
      return {
        'success': false,
        'error': body['error'] ?? 'Failed to load audit log',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
