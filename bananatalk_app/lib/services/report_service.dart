import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportService {
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

  /// Report a user
  /// POST /api/v1/users/:userId/report
  static Future<Map<String, dynamic>> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? details,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.reportUserURL(reportedUserId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Report submitted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to submit report',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Report a moment/post
  /// POST /api/v1/moments/:momentId/report
  static Future<Map<String, dynamic>> reportMoment({
    required String momentId,
    required String reason,
    String? details,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final url = Uri.parse(
          '${Endpoints.baseURL}/api/v1/moments/$momentId/report');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Report submitted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to submit report',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Report a message
  /// POST /api/v1/messages/:messageId/report
  static Future<Map<String, dynamic>> reportMessage({
    required String messageId,
    required String reason,
    String? details,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final url = Uri.parse(
          '${Endpoints.baseURL}/api/v1/messages/$messageId/report');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Report submitted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to submit report',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}

