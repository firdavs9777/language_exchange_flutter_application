import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  /// Upload evidence file for a report
  /// POST /api/v1/reports/:reportId/evidence
  static Future<Map<String, dynamic>> uploadEvidence({
    required String reportId,
    required PlatformFile file,
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
          '${Endpoints.baseURL}/api/v1/reports/$reportId/evidence');

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add file to request
      if (file.bytes != null) {
        final mimeType = _getMimeType(file.name);
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
            contentType: MediaType.parse(mimeType),
          ),
        );
      } else if (file.path != null) {
        final mimeType = _getMimeType(file.name);
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
            contentType: MediaType.parse(mimeType),
          ),
        );
      } else {
        return {
          'success': false,
          'message': 'Unable to read file',
        };
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'File uploaded successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to upload file',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Detect MIME type from file extension
  static String _getMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
  }
}

