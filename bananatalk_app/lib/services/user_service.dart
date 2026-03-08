import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// Service for user-related API calls
class UserService {
  final ApiClient _apiClient = ApiClient();

  /// Get user by username (exact match)
  /// Accepts username with or without @ prefix
  Future<Community?> getUserByUsername(String username) async {
    try {
      // Remove @ prefix if present
      final cleanUsername = username.startsWith('@')
          ? username.substring(1)
          : username;

      if (cleanUsername.isEmpty) {
        debugPrint('⚠️ Empty username provided');
        return null;
      }

      final response = await _apiClient.get(
        Endpoints.getUserByUsernameURL(cleanUsername),
      );

      if (response.success && response.data != null) {
        return Community.fromJson(response.data);
      }

      debugPrint('⚠️ User not found: $username');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user by username: $e');
      return null;
    }
  }

  /// Search users by username (partial match)
  /// Returns list of matching users
  Future<List<Community>> searchUsersByUsername(
    String query, {
    int limit = 20,
  }) async {
    try {
      // Remove @ prefix if present
      final cleanQuery = query.startsWith('@')
          ? query.substring(1)
          : query;

      if (cleanQuery.length < 2) {
        debugPrint('⚠️ Search query too short (min 2 characters)');
        return [];
      }

      final response = await _apiClient.get(
        '${Endpoints.searchByUsernameURL}?q=$cleanQuery&limit=$limit',
      );

      if (response.success && response.data != null) {
        final List<dynamic> usersJson = response.data is List
            ? response.data
            : response.data['data'] ?? [];

        return usersJson
            .map((json) => Community.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error searching users by username: $e');
      return [];
    }
  }
}
