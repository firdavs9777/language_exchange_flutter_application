import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/models/blocked_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockService {
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

  /// Block a user
  /// POST /api/v1/users/:userId/block (userId = user to block)
  static Future<Map<String, dynamic>> blockUser({
    required String currentUserId, // Not used in URL, just for consistency
    required String blockedUserId,
    required String blockedUserName,
    String? blockedUserAvatar,
    String? reason,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // FIXED: Use blockedUserId in URL (the user you want to block)
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.blockUserURL(blockedUserId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          if (reason != null) 'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'User blocked successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Unblock a user
  /// DELETE /api/v1/users/:userId/block (userId = user to unblock)
  static Future<Map<String, dynamic>> unblockUser({
    required String currentUserId, // Not used, just for API consistency
    required String blockedUserId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // FIXED: Use blockedUserId in URL (the user you want to unblock)
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.unblockUserURL(blockedUserId)}');

      final response = await http.delete(
        url,
        headers: _getHeaders(token),
        // REMOVED: No body needed, userId is in URL
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'User unblocked successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Get list of blocked users
  /// GET /api/v1/users/:userId/blocked (userId = current user)
  static Future<List<BlockedUser>> getBlockedUsers({
    required String userId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return [];
      }

      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.getBlockedUsersURL(userId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend returns { success: true, count: X, data: [...] }
        final List blockedList = data['data'] ?? [];
        return blockedList.map((json) => BlockedUser.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getBlockedUsers: $e');
      return [];
    }
  }

  /// Check block status between two users
  /// GET /api/v1/users/:userId/block-status/:targetUserId
  static Future<Map<String, dynamic>> checkBlockStatus({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.checkBlockStatusURL(userId, targetUserId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'isBlocked': data['data']?['isBlocked'] ?? false,
          'isBlockedBy': data['data']?['isBlockedBy'] ?? false,
          'canMessage': data['data']?['canMessage'] ?? true,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to check block status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
