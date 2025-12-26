import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

class MomentsService {
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

  // ==================== SAVE/BOOKMARK ====================

  /// Save/Bookmark a moment
  static Future<Map<String, dynamic>> saveMoment({
    required String momentId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.saveMomentURL(momentId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': {
            'id': data['data']?['_id'],
            'saveCount': data['data']?['saveCount'] ?? 0,
            'isSaved': data['data']?['isSaved'] ?? true,
          },
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to save moment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Unsave/Remove bookmark from a moment
  static Future<Map<String, dynamic>> unsaveMoment({
    required String momentId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.unsaveMomentURL(momentId)}');

      final response = await http.delete(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': {
            'id': data['data']?['_id'],
            'saveCount': data['data']?['saveCount'] ?? 0,
            'isSaved': data['data']?['isSaved'] ?? false,
          },
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to unsave moment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Toggle save/unsave moment
  static Future<Map<String, dynamic>> toggleSave({
    required String momentId,
    required bool currentlySaved,
  }) async {
    if (currentlySaved) {
      return await unsaveMoment(momentId: momentId);
    } else {
      return await saveMoment(momentId: momentId);
    }
  }

  /// Get saved moments
  static Future<MomentsResponse> getSavedMoments({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.savedMomentsURL}')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return MomentsResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        return MomentsResponse(
          success: false,
          error: errorData['error'] ?? 'Failed to get saved moments',
        );
      }
    } catch (e) {
      return MomentsResponse(
        success: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // ==================== SHARE ====================

  /// Increment share count for a moment
  static Future<Map<String, dynamic>> shareMoment({
    required String momentId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.shareMomentURL(momentId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'shareCount': data['shareCount'] ?? 0,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to share moment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get shareable link for a moment
  static String getShareableLink(String momentId) {
    return 'https://banatalk.com/moments/$momentId';
  }

  // ==================== REPORT ====================

  /// Report a moment
  static Future<Map<String, dynamic>> reportMoment({
    required String momentId,
    required MomentReportReason reason,
    String? description,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.reportMomentURL(momentId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'reason': reason.value,
          if (description != null && description.isNotEmpty)
            'description': description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Report submitted successfully',
        };
      } else if (response.statusCode == 400) {
        // Already reported
        return {
          'success': false,
          'alreadyReported': true,
          'error': 'You have already reported this moment',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to report moment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // ==================== TRENDING ====================

  /// Get trending moments
  static Future<MomentsResponse> getTrendingMoments({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.trendingMomentsURL}')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return MomentsResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        return MomentsResponse(
          success: false,
          error: errorData['error'] ?? 'Failed to get trending moments',
        );
      }
    } catch (e) {
      return MomentsResponse(
        success: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // ==================== EXPLORE/DISCOVER ====================

  /// Explore/Discover moments with filters
  static Future<MomentsResponse> exploreMoments({
    MomentsExploreFilter? filter,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = filter?.toQueryParams() ?? {'page': '1', 'limit': '10'};
      
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.exploreMomentsURL}')
          .replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return MomentsResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        return MomentsResponse(
          success: false,
          error: errorData['error'] ?? 'Failed to explore moments',
        );
      }
    } catch (e) {
      return MomentsResponse(
        success: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // ==================== USER MOMENTS ====================

  /// Get moments for a specific user (handles blocking)
  static Future<MomentsResponse> getUserMoments({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.userMomentsURL(userId)}')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return MomentsResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        // User is blocked
        return MomentsResponse(
          success: true,
          blocked: true,
          message: 'Content not available',
        );
      } else {
        final errorData = jsonDecode(response.body);
        return MomentsResponse(
          success: false,
          error: errorData['error'] ?? 'Failed to get user moments',
        );
      }
    } catch (e) {
      return MomentsResponse(
        success: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Get a single moment by ID (handles blocking)
  static Future<Map<String, dynamic>> getMoment({
    required String momentId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.singleMomentURL(momentId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': Moments.fromJson(data['data']),
        };
      } else if (response.statusCode == 403) {
        // Content is blocked
        return {
          'success': false,
          'blocked': true,
          'error': 'This content is not available',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get moment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // ==================== LIKE ====================

  /// Like a moment (handles blocking)
  static Future<Map<String, dynamic>> likeMoment({
    required String momentId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.likeMomentURL(momentId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'blocked': true,
          'error': 'Cannot like this content',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to like moment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // ==================== COMMENTS ====================

  /// Get comments for a moment (blocked users filtered automatically)
  static Future<Map<String, dynamic>> getComments({
    required String momentId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.momentCommentsURL(momentId)}')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'count': data['count'] ?? 0,
          'data': (data['data'] as List?)
                  ?.map((c) => Comment.fromJson(c))
                  .toList() ??
              [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get comments',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Add a comment to a moment (handles blocking)
  static Future<Map<String, dynamic>> addComment({
    required String momentId,
    required String text,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.momentCommentsURL(momentId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] != null ? Comment.fromJson(data['data']) : null,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'blocked': true,
          'error': "You can't comment on this content",
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to add comment',
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

