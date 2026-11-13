import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/models/blocked_user.dart';
import 'package:bananatalk_app/services/blocked_ids_store.dart';
import 'package:bananatalk_app/services/community_first_page_cache.dart';
import 'package:bananatalk_app/services/feed_first_page_cache.dart';
import 'package:bananatalk_app/services/stories_rail_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockService {
  static final StreamController<String> _blocked =
      StreamController<String>.broadcast(sync: true);

  /// Ids of users blocked through [blockUser] (after the server confirmed),
  /// so in-memory lists that outlive a screen can drop them at once.
  static Stream<String> get blockedUserIds => _blocked.stream;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String> _signedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }

  /// Every block goes through [blockUser]: once the server confirms it, the
  /// author leaves the on-disk caches (feed first pages, stories rail,
  /// Partners page 1 and daily matches) and
  /// joins the remembered block list, so no cached list paints them again,
  /// not even offline. Best effort: a failure here never fails the block.
  static Future<void> _forgetBlockedLocally(String blockedUserId) async {
    _blocked.add(blockedUserId);
    try {
      await BlockedIdsStore()
          .add(userId: await _signedInUserId(), id: blockedUserId);
      await FeedFirstPageCache().removeAuthor(blockedUserId);
      await StoriesRailCache().removeUser(blockedUserId);
      // Partners page 1 and today's matches on disk. Not flag-gated: an
      // entry kept while the flag was on must not paint them later either;
      // with no entry this reads two absent keys and writes nothing.
      await CommunityFirstPageCache()
          .removeUser(await _signedInUserId(), blockedUserId);
    } catch (_) {}
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
      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) await _forgetBlockedLocally(blockedUserId);
      return {
        'success': success,
        'message': data['message'] ?? 'User blocked successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
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
      final success = response.statusCode == 200;
      if (success) {
        try {
          await BlockedIdsStore()
              .remove(userId: await _signedInUserId(), id: blockedUserId);
        } catch (_) {}
      }
      return {
        'success': success,
        'message': data['message'] ?? 'User unblocked successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get list of blocked users
  /// GET /api/v1/users/:userId/blocked (userId = current user)
  static Future<List<BlockedUser>> getBlockedUsers({
    required String userId,
  }) async =>
      await fetchBlockedUsers(userId: userId) ?? [];

  /// Like [getBlockedUsers], but null when the list could not be fetched
  /// (no token, offline, non-200), so a caller can tell "you blocked no one"
  /// from "unknown".
  static Future<List<BlockedUser>?> fetchBlockedUsers({
    required String userId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return null;
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
      return null;
    } catch (e) {
      return null;
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
        'error': e.toString(),
      };
    }
  }
}
