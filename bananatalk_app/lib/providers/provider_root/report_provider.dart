import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';

class ReportService {
  // Get auth token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }
  // ========================================================================
  // USER ENDPOINTS (Any authenticated user can use these)
  // ========================================================================

  /// Create a new report
  /// [type] - Type of content: 'user', 'moment', 'comment', 'message', 'story'
  /// [reportId] - ID of the reported content/user (backend expects 'reportId')
  /// [reportedUser] - ID of the user who owns the content
  /// [reason] - Reason: 'spam', 'harassment', 'hate_speech', 'violence', 'nudity', 'false_information', 'copyright', 'other'
  /// [description] - Optional additional details
  Future<Map<String, dynamic>> createReport({
    required String type,
    required String reportId,
    required String reportedUser,
    required String reason,
    String? description,
  }) async {
    try {
      // Validate required fields
      if (type.isEmpty) {
        return {
          'success': false,
          'error': 'Report type is required',
        };
      }
      if (reportId.isEmpty) {
        return {
          'success': false,
          'error': 'Report ID is required',
        };
      }
      if (reportedUser.isEmpty) {
        return {
          'success': false,
          'error': 'Reported user ID is required',
        };
      }
      if (reason.isEmpty) {
        return {
          'success': false,
          'error': 'Report reason is required',
        };
      }

      final headers = await _getHeaders();
      final requestBody = {
        'type': type,
        'reportId': reportId, // Backend expects 'reportId', not 'reportedId'
        'reportedUser': reportedUser,
        'reason': reason,
        'description': description ?? '', // Always include description, use empty string if null
      };
      
      final body = json.encode(requestBody);
      
      // Debug logging
      print('📋 Creating report:');
      print('   Type: $type');
      print('   Report ID: $reportId');
      print('   Reported User: $reportedUser');
      print('   Reason: $reason');
      print('   Description: ${description ?? 'none'}');
      print('   URL: ${Endpoints.baseURL}reports');

      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}reports'),
        headers: headers,
        body: body,
      );
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Report submitted successfully',
          'data': responseData['data'],
        };
      } else {
        // Extract detailed error message
        String errorMessage = 'Failed to create report';
        if (responseData['error'] != null) {
          errorMessage = responseData['error'].toString();
        } else if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        } else if (responseData['errors'] != null) {
          // Handle validation errors
          final errors = responseData['errors'];
          if (errors is Map) {
            final errorList = errors.values.expand((e) => e is List ? e : [e]).toList();
            errorMessage = errorList.join(', ');
          } else {
            errorMessage = errors.toString();
          }
        }
        
        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get all reports submitted by current user
  Future<Map<String, dynamic>> getMyReports() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}reports/my-reports'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'count': responseData['count'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch reports',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // ========================================================================
  // ADMIN ENDPOINTS (Require admin role)
  // ========================================================================

  /// Get all reports with optional filters
  ///
  /// [status] - Filter by status: 'pending', 'under_review', 'resolved', 'dismissed'
  /// [type] - Filter by type: 'user', 'moment', 'comment', 'message', 'story'
  /// [priority] - Filter by priority: 'low', 'medium', 'high', 'urgent'
  Future<Map<String, dynamic>> getAllReports({
    String? status,
    String? type,
    String? priority,
  }) async {
    try {
      final headers = await _getHeaders();

      // Build query parameters
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      if (priority != null) queryParams['priority'] = priority;

      final uri = Uri.parse('${Endpoints.baseURL}reports').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(uri, headers: headers);
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'count': responseData['count'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch reports',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get a single report by ID
  Future<Map<String, dynamic>> getReport(String reportId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}reports/$reportId'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Report not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get all reports about a specific user
  Future<Map<String, dynamic>> getReportsByUser(String userId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}reports/user/$userId'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'count': responseData['count'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch reports',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get count of pending reports
  Future<Map<String, dynamic>> getPendingCount() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}reports/stats/pending'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'pendingCount': responseData['data']['pendingReports'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch count',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get report statistics (by status and reason)
  Future<Map<String, dynamic>> getReportStats() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}reports/stats'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch stats',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Start reviewing a report (mark as under_review)
  Future<Map<String, dynamic>> startReview(String reportId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('${Endpoints.baseURL}reports/$reportId/review'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to start review',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Resolve a report with moderator action
  ///
  /// [reportId] - ID of the report
  /// [action] - Action taken: 'none', 'content_removed', 'user_warned', 'user_suspended', 'user_banned', 'no_violation'
  /// [notes] - Optional moderator notes
  Future<Map<String, dynamic>> resolveReport({
    required String reportId,
    required String action,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'action': action,
        if (notes != null) 'notes': notes,
      });

      final response = await http.put(
        Uri.parse('${Endpoints.baseURL}reports/$reportId/resolve'),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to resolve report',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Dismiss a report (no violation found)
  ///
  /// [reportId] - ID of the report
  /// [notes] - Optional moderator notes
  Future<Map<String, dynamic>> dismissReport({
    required String reportId,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        if (notes != null) 'notes': notes,
      });

      final response = await http.put(
        Uri.parse('${Endpoints.baseURL}reports/$reportId/dismiss'),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to dismiss report',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Delete a report
  Future<Map<String, dynamic>> deleteReport(String reportId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('${Endpoints.baseURL}reports/$reportId'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to delete report',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  /// Check if user has already reported specific content
  /// This is a client-side check - backend also validates
  Future<bool> hasUserReported({
    required String type,
    required String contentId,
  }) async {
    try {
      final result = await getMyReports();
      if (result['success'] == true) {
        final reports = result['data'] as List;
        return reports.any((report) =>
            report['type'] == type && report['reportedId'] == contentId);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
