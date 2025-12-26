import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

class BookmarkService {
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

  /// Bookmark a message
  static Future<Map<String, dynamic>> bookmarkMessage({
    required String messageId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.bookmarkMessageURL(messageId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Message bookmarked',
          'data': data['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to bookmark message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Remove bookmark from a message
  static Future<Map<String, dynamic>> removeBookmark({
    required String messageId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.bookmarkMessageURL(messageId)}');

      final response = await http.delete(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Bookmark removed',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to remove bookmark',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get all bookmarked messages
  static Future<Map<String, dynamic>> getBookmarks({
    int? page,
    int? limit,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = {
        if (page != null) 'page': page.toString(),
        if (limit != null) 'limit': limit.toString(),
      };
      
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.getBookmarksURL}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'count': data['count'] ?? 0,
          'total': data['total'] ?? 0,
          'pages': data['pages'] ?? 1,
          'data': (data['data'] as List?)
                  ?.map((item) => BookmarkedMessage.fromJson(item))
                  .toList() ??
              [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get bookmarks',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Toggle bookmark on a message
  static Future<Map<String, dynamic>> toggleBookmark({
    required String messageId,
    required bool isCurrentlyBookmarked,
  }) async {
    if (isCurrentlyBookmarked) {
      return await removeBookmark(messageId: messageId);
    } else {
      return await bookmarkMessage(messageId: messageId);
    }
  }
}

