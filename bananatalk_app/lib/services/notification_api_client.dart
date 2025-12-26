import 'dart:convert';
import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotificationApiClient {
  final String baseUrl = Endpoints.baseURL;

  /// Get authorization header with token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// POST /api/v1/notifications/register-token
  Future<Map<String, dynamic>> registerToken(
    String token,
    String platform,
    String deviceId,
  ) async {
    try {
      final url = Uri.parse('${baseUrl}notifications/register-token');
      final headers = await _getHeaders();

      debugPrint('📤 Registering FCM token for device: $deviceId');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'token': token,
          'platform': platform,
          'deviceId': deviceId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ FCM token registered successfully');
        return {'success': true, 'message': 'Token registered successfully'};
      } else {
        debugPrint('❌ Token registration failed: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to register token: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error registering token: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// DELETE /api/v1/notifications/remove-token/:deviceId
  Future<Map<String, dynamic>> removeToken(String deviceId) async {
    try {
      final url =
          Uri.parse('${baseUrl}notifications/remove-token/$deviceId');
      final headers = await _getHeaders();

      debugPrint('📤 Removing FCM token for device: $deviceId');

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token removed successfully');
        return {'success': true, 'message': 'Token removed successfully'};
      } else {
        debugPrint('❌ Token removal failed: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to remove token: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error removing token: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// GET /api/v1/notifications/settings
  Future<NotificationSettings?> getSettings() async {
    try {
      final url = Uri.parse('${baseUrl}notifications/settings');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationSettings.fromJson(data['settings'] ?? data);
      } else {
        debugPrint('❌ Failed to get notification settings: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting notification settings: $e');
      return null;
    }
  }

  /// PUT /api/v1/notifications/settings
  Future<Map<String, dynamic>> updateSettings(
    NotificationSettings settings,
  ) async {
    try {
      final url = Uri.parse('${baseUrl}notifications/settings');
      final headers = await _getHeaders();

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notification settings updated successfully');
        return {'success': true, 'message': 'Settings updated successfully'};
      } else {
        debugPrint('❌ Failed to update settings: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to update settings: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error updating settings: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// POST /api/v1/notifications/mute-chat/:conversationId
  Future<Map<String, dynamic>> muteConversation(String conversationId) async {
    try {
      final url =
          Uri.parse('${baseUrl}notifications/mute-chat/$conversationId');
      final headers = await _getHeaders();

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        debugPrint('✅ Conversation muted successfully');
        return {'success': true, 'message': 'Conversation muted'};
      } else {
        debugPrint('❌ Failed to mute conversation: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to mute conversation: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error muting conversation: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// POST /api/v1/notifications/unmute-chat/:conversationId
  Future<Map<String, dynamic>> unmuteConversation(String conversationId) async {
    try {
      final url =
          Uri.parse('${baseUrl}notifications/unmute-chat/$conversationId');
      final headers = await _getHeaders();

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        debugPrint('✅ Conversation unmuted successfully');
        return {'success': true, 'message': 'Conversation unmuted'};
      } else {
        debugPrint('❌ Failed to unmute conversation: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to unmute conversation: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error unmuting conversation: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// GET /api/v1/notifications/history
  Future<List<NotificationItem>> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url = Uri.parse(
        '${baseUrl}notifications/history?page=$page&limit=$limit',
      );
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifications = data['notifications'] ?? data['data'] ?? [];
        return (notifications as List)
            .map((item) => NotificationItem.fromJson(item))
            .toList();
      } else {
        debugPrint('❌ Failed to get notification history: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting notification history: $e');
      return [];
    }
  }

  /// POST /api/v1/notifications/mark-read/:notificationId
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final url =
          Uri.parse('${baseUrl}notifications/mark-read/$notificationId');
      final headers = await _getHeaders();

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Marked as read'};
      } else {
        return {
          'success': false,
          'message': 'Failed to mark as read: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// POST /api/v1/notifications/mark-all-read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final url = Uri.parse('${baseUrl}notifications/mark-all-read');
      final headers = await _getHeaders();

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        debugPrint('✅ All notifications marked as read');
        return {'success': true, 'message': 'All marked as read'};
      } else {
        return {
          'success': false,
          'message': 'Failed to mark all as read: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// DELETE /api/v1/notifications/clear-all
  Future<Map<String, dynamic>> clearAll() async {
    try {
      final url = Uri.parse('${baseUrl}notifications/clear-all');
      final headers = await _getHeaders();

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        debugPrint('✅ All notifications cleared');
        return {'success': true, 'message': 'All notifications cleared'};
      } else {
        return {
          'success': false,
          'message': 'Failed to clear notifications: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// GET /api/v1/notifications/badge-count
  Future<BadgeCount?> getBadgeCount() async {
    try {
      final url = Uri.parse('${baseUrl}notifications/badge-count');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BadgeCount.fromJson(data['badges'] ?? data);
      } else {
        debugPrint('❌ Failed to get badge count: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting badge count: $e');
      return null;
    }
  }

  /// POST /api/v1/notifications/reset-badge
  Future<Map<String, dynamic>> resetBadge(String type) async {
    try {
      final url = Uri.parse('${baseUrl}notifications/reset-badge');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'type': type}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Badge reset successfully for type: $type');
        return {'success': true, 'message': 'Badge reset successfully'};
      } else {
        return {
          'success': false,
          'message': 'Failed to reset badge: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error resetting badge: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// POST /api/v1/notifications/test (for debugging)
  Future<Map<String, dynamic>> sendTestNotification({
    String? userId,
    String type = 'system',
  }) async {
    try {
      final url = Uri.parse('${baseUrl}notifications/test');
      final headers = await _getHeaders();

      final body = <String, dynamic>{'type': type};
      if (userId != null) {
        body['userId'] = userId;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Test notification sent');
        return {'success': true, 'message': 'Test notification sent'};
      } else {
        return {
          'success': false,
          'message': 'Failed to send test notification: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}

