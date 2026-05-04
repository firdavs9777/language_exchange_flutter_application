import 'dart:convert';
import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotificationApiClient {
  final String baseUrl = Endpoints.baseURL;

  // Cached SharedPreferences instance
  static SharedPreferences? _cachedPrefs;
  static String? _cachedToken;
  static DateTime? _tokenCacheTime;
  static const Duration _tokenCacheDuration = Duration(minutes: 5);

  /// Get authorization header with token (cached)
  Future<Map<String, String>> _getHeaders() async {
    // Initialize SharedPreferences if not cached
    _cachedPrefs ??= await SharedPreferences.getInstance();

    // Refresh token cache if expired or not set
    final now = DateTime.now();
    if (_cachedToken == null ||
        _tokenCacheTime == null ||
        now.difference(_tokenCacheTime!) > _tokenCacheDuration) {
      _cachedToken = _cachedPrefs!.getString('token') ?? '';
      _tokenCacheTime = now;
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_cachedToken',
    };
  }

  /// Clear cached token (call on logout or token refresh)
  static void clearTokenCache() {
    _cachedToken = null;
    _tokenCacheTime = null;
  }

  /// Refresh token from SharedPreferences (call after login)
  static Future<void> refreshTokenCache() async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    _cachedToken = _cachedPrefs!.getString('token') ?? '';
    _tokenCacheTime = DateTime.now();
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
        return {'success': true, 'message': 'Token registered successfully'};
      } else {
        return {
          'success': false,
          'message': 'Failed to register token: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// DELETE /api/v1/notifications/remove-token/:deviceId
  Future<Map<String, dynamic>> removeToken(String deviceId) async {
    try {
      final url =
          Uri.parse('${baseUrl}notifications/remove-token/$deviceId');
      final headers = await _getHeaders();


      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Token removed successfully'};
      } else {
        return {
          'success': false,
          'message': 'Failed to remove token: ${response.statusCode}',
        };
      }
    } catch (e) {
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
        // Backend returns { success: true, data: { settings... } }
        return NotificationSettings.fromJson(data['data'] ?? data['settings'] ?? data);
      } else {
        return null;
      }
    } catch (e) {
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
        return {'success': true, 'message': 'Settings updated successfully'};
      } else {
        return {
          'success': false,
          'message': 'Failed to update settings: ${response.statusCode}',
        };
      }
    } catch (e) {
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
        return {'success': true, 'message': 'Conversation muted'};
      } else {
        return {
          'success': false,
          'message': 'Failed to mute conversation: ${response.statusCode}',
        };
      }
    } catch (e) {
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
        return {'success': true, 'message': 'Conversation unmuted'};
      } else {
        return {
          'success': false,
          'message': 'Failed to unmute conversation: ${response.statusCode}',
        };
      }
    } catch (e) {
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

        // Handle different response formats
        List<dynamic> notifications;
        if (data is List) {
          // Direct list response
          notifications = data;
        } else if (data is Map) {
          // Nested response: { success: true, data: { notifications: [...] } }
          final innerData = data['data'];
          if (innerData is Map && innerData['notifications'] is List) {
            notifications = innerData['notifications'];
          } else if (data['notifications'] is List) {
            notifications = data['notifications'];
          } else if (innerData is List) {
            notifications = innerData;
          } else {
            return [];
          }
        } else {
          return [];
        }

        // Filter out chat_message notifications (they're shown in chat, not notification list)
        final filteredNotifications = notifications
            .where((item) => item['type'] != 'chat_message')
            .toList();

        return filteredNotifications
            .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
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
        return {'success': true, 'message': 'All marked as read'};
      } else {
        return {
          'success': false,
          'message': 'Failed to mark all as read: ${response.statusCode}',
        };
      }
    } catch (e) {
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
        return {'success': true, 'message': 'All notifications cleared'};
      } else {
        return {
          'success': false,
          'message': 'Failed to clear notifications: ${response.statusCode}',
        };
      }
    } catch (e) {
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
        return null;
      }
    } catch (e) {
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
        return {'success': true, 'message': 'Badge reset successfully'};
      } else {
        return {
          'success': false,
          'message': 'Failed to reset badge: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// POST /api/v1/notifications/sync-badges
  /// Syncs badge counts with actual data from server
  Future<BadgeCount?> syncBadges() async {
    try {
      final url = Uri.parse('${baseUrl}notifications/sync-badges');
      final headers = await _getHeaders();


      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BadgeCount.fromJson(data['data'] ?? data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// POST /api/v1/messages
  ///
  /// Used by NotificationRouter to send an inline-reply when the user taps
  /// the "Reply" action on a chat-message notification (iOS text input or
  /// Android quick-reply). Returns true on 2xx, false otherwise.
  Future<bool> sendQuickReply({
    required String receiverId,
    required String message,
  }) async {
    try {
      final url = Uri.parse('${baseUrl}messages');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'receiver': receiverId,
          'message': message,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
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
        return {'success': true, 'message': 'Test notification sent'};
      } else {
        return {
          'success': false,
          'message': 'Failed to send test notification: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}

