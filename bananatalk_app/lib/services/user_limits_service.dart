import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/models/user_limits.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLimitsService {
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

  /// Fetch current user limits from API
  /// Returns UserLimits model with all limit information
  static Future<UserLimits> getUserLimits(String userId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.getUserLimitsURL(userId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          return UserLimits.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch user limits');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['error'] ?? 'Failed to fetch user limits: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Check if user can perform a specific action
  /// Returns true if action is allowed, false otherwise
  static Future<bool> canPerformAction(
    String userId,
    String actionType,
  ) async {
    try {
      final limits = await getUserLimits(userId);
      
      switch (actionType.toLowerCase()) {
        case 'message':
        case 'messages':
          return limits.canSendMessage();
        case 'moment':
        case 'moments':
          return limits.canCreateMoment();
        case 'story':
        case 'stories':
          return limits.canCreateStory();
        case 'comment':
        case 'comments':
          return limits.canCreateComment();
        case 'profile':
        case 'profileview':
        case 'profileviews':
          return limits.canViewProfile();
        default:
          return true; // Unknown action type, allow by default
      }
    } catch (e) {
      // On error, allow action (fail open)
      print('Error checking limits: $e');
      return true;
    }
  }
}

