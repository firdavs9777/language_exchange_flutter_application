import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Community service with authentication support for all endpoints
class CommunityService {
  final ApiClient _apiClient = ApiClient();

  /// Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all community members
  Future<List<Community>> getCommunity() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}'),
        headers: headers,
      );

      debugPrint('🔍 getCommunity response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dataList = data['data'];
        if (dataList == null || dataList is! List) {
          debugPrint('🔍 getCommunity: dataList is null or not a list');
          return [];
        }

        // Debug: Print first user's data
        if (dataList.isNotEmpty) {
          final firstUser = dataList[0];
          debugPrint('🔍 First user data sample:');
          debugPrint('   id: ${firstUser['_id']}');
          debugPrint('   images: ${firstUser['images']}');
          debugPrint('   imageUrls: ${firstUser['imageUrls']}');
          debugPrint('   followers: ${firstUser['followers']}');
          debugPrint('   following: ${firstUser['following']}');
        }

        return dataList
            .where((item) => item != null && item is Map<String, dynamic>)
            .map((postJson) =>
                Community.fromJson(postJson as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        _apiClient.onAuthenticationError?.call();
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load community: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error fetching community: $error');
      throw Exception('Failed to load community: $error');
    }
  }

  /// Get single user profile
  Future<Community?> getSingleCommunity({required id}) async {
    try {
      final headers = await _getHeaders();
      final url = '${Endpoints.baseURL}${Endpoints.usersURL}/$id';
      debugPrint('🔍 getSingleCommunity URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('🔍 getSingleCommunity response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data'];
        if (userData == null || userData is! Map<String, dynamic>) {
          debugPrint('Warning: User data is null or invalid for id: $id');
          return null;
        }

        // Debug: Print user data
        debugPrint('🔍 Single user data:');
        debugPrint('   id: ${userData['_id']}');
        debugPrint('   name: ${userData['name']}');
        debugPrint('   images: ${userData['images']}');
        debugPrint('   imageUrls: ${userData['imageUrls']}');
        debugPrint('   followers: ${userData['followers']}');
        debugPrint('   following: ${userData['following']}');
        debugPrint('   location: ${userData['location']}');

        return Community.fromJson(userData);
      } else if (response.statusCode == 401) {
        _apiClient.onAuthenticationError?.call();
        return null;
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error fetching community: $error');
      throw Exception('Failed to load community: $error');
    }
  }

  /// Follow a user (requires auth)
  /// Returns: 'success' | 'already_following' | 'error'
  Future<String> followUser({required userId, required targetUserId}) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/follow/$targetUserId');
    try {
      final response = await http.put(url, headers: headers);
      debugPrint('Follow response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 401) {
        _apiClient.onAuthenticationError?.call();
        throw Exception('Authentication required');
      } else if (response.statusCode == 403) {
        _apiClient.onAuthorizationError?.call('You cannot follow this user');
        throw Exception('Not authorized');
      } else if (response.statusCode == 429) {
        _apiClient.onRateLimitError?.call('Too many follow requests. Slow down!');
        throw Exception('Rate limited');
      } else if (response.statusCode >= 200 && response.statusCode < 300) {
        return 'success';
      } else if (response.statusCode == 400) {
        // Check if it's "Already following" error
        try {
          final body = json.decode(response.body);
          if (body['error']?.toString().contains('Already following') == true) {
            return 'already_following';
          }
        } catch (_) {}
        debugPrint('Follow failed with status: ${response.statusCode}');
        return 'error';
      } else {
        debugPrint('Follow failed with status: ${response.statusCode}');
        return 'error';
      }
    } catch (error) {
      debugPrint('Error when following the user: $error');
      rethrow;
    }
  }

  /// Unfollow a user (requires auth)
  /// Returns: 'success' | 'not_following' | 'error'
  Future<String> unfollowUser({required userId, required targetUserId}) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/unfollow/$targetUserId');
    try {
      final response = await http.put(url, headers: headers);
      debugPrint('Unfollow response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 401) {
        _apiClient.onAuthenticationError?.call();
        throw Exception('Authentication required');
      } else if (response.statusCode >= 200 && response.statusCode < 300) {
        return 'success';
      } else if (response.statusCode == 400) {
        // Check if it's "Not following" error
        try {
          final body = json.decode(response.body);
          if (body['error']?.toString().contains('not following') == true ||
              body['error']?.toString().contains('Not following') == true) {
            return 'not_following';
          }
        } catch (_) {}
        debugPrint('Unfollow failed with status: ${response.statusCode}');
        return 'error';
      } else {
        debugPrint('Unfollow failed with status: ${response.statusCode}');
        return 'error';
      }
    } catch (error) {
      debugPrint('Error when unfollowing the user: $error');
      rethrow;
    }
  }

  // ==================== NEW COMMUNITY ENDPOINTS ====================

  /// Get nearby users based on location
  Future<NearbyUsersResponse> getNearbyUsers({
    required double latitude,
    required double longitude,
    int? radius,
    int? limit,
    int? offset,
    String? language,
    int? minAge,
    int? maxAge,
    String? gender,
    bool? onlineOnly,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        if (radius != null) 'radius': radius.toString(),
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
        if (language != null) 'language': language,
        if (minAge != null) 'minAge': minAge.toString(),
        if (maxAge != null) 'maxAge': maxAge.toString(),
        if (gender != null) 'gender': gender,
        if (onlineOnly != null) 'onlineOnly': onlineOnly.toString(),
      };

      final response = await _apiClient.get(
        Endpoints.nearbyUsersURL,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        return NearbyUsersResponse.fromJson(response.data);
      } else {
        throw Exception(response.error ?? 'Failed to get nearby users');
      }
    } catch (error) {
      debugPrint('Error getting nearby users: $error');
      rethrow;
    }
  }

  /// Send a wave to another user
  Future<WaveResponse> sendWave({
    required String targetUserId,
    String? message,
  }) async {
    try {
      final response = await _apiClient.post(
        Endpoints.waveURL,
        body: {
          'targetUserId': targetUserId,
          if (message != null) 'message': message,
        },
      );

      if (response.success && response.data != null) {
        return WaveResponse.fromJson(response.data);
      } else if (response.isRateLimited) {
        throw Exception('Too many waves. Please slow down!');
      } else {
        throw Exception(response.error ?? 'Failed to send wave');
      }
    } catch (error) {
      debugPrint('Error sending wave: $error');
      rethrow;
    }
  }

  /// Get waves received
  Future<List<Wave>> getWavesReceived({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _apiClient.get(
        Endpoints.wavesReceivedURL,
        queryParams: {
          'page': page.toString(),
          'limit': limit.toString(),
          'unreadOnly': unreadOnly.toString(),
        },
      );

      if (response.success && response.data != null) {
        final dataList = response.data['data'] as List? ?? [];
        return dataList
            .map((item) => Wave.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.error ?? 'Failed to get waves');
      }
    } catch (error) {
      debugPrint('Error getting waves: $error');
      rethrow;
    }
  }

  /// Mark waves as read
  Future<void> markWavesAsRead({List<String>? waveIds}) async {
    try {
      await _apiClient.put(
        Endpoints.wavesReadURL,
        body: waveIds != null ? {'waveIds': waveIds} : null,
      );
    } catch (error) {
      debugPrint('Error marking waves as read: $error');
      rethrow;
    }
  }

  /// Get all topics
  Future<List<Topic>> getTopics({String? category, String? lang}) async {
    try {
      final response = await _apiClient.get(
        Endpoints.topicsURL,
        queryParams: {
          if (category != null) 'category': category,
          if (lang != null) 'lang': lang,
        },
      );

      if (response.success && response.data != null) {
        final dataList = response.data['data'] as List? ?? response.data as List? ?? [];
        return dataList
            .map((item) => Topic.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.error ?? 'Failed to get topics');
      }
    } catch (error) {
      debugPrint('Error getting topics: $error');
      rethrow;
    }
  }

  /// Get users by topic
  Future<List<Community>> getUsersByTopic(
    String topicId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        Endpoints.topicUsersURL(topicId),
        queryParams: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.success && response.data != null) {
        final dataList = response.data['data'] as List? ?? [];
        return dataList
            .map((item) => Community.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.error ?? 'Failed to get users by topic');
      }
    } catch (error) {
      debugPrint('Error getting users by topic: $error');
      rethrow;
    }
  }

  /// Update my topics
  Future<void> updateMyTopics(List<String> topicIds) async {
    try {
      final response = await _apiClient.put(
        Endpoints.myTopicsURL,
        body: {'topics': topicIds},
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to update topics');
      }
    } catch (error) {
      debugPrint('Error updating topics: $error');
      rethrow;
    }
  }

  /// Get countries list
  Future<void> getCountriesList() async {
    final url = Uri.parse(Endpoints.countriesURL);
    try {
      final response = await http.get(url);
      debugPrint('Countries response: ${response.statusCode}');
    } catch (error) {
      debugPrint('Error when getting countries list $error');
      throw Exception('Failed to call the api: $error');
    }
  }
}

// ==================== MODELS ====================

/// Nearby users response
class NearbyUsersResponse {
  final List<NearbyUser> users;
  final NearbyPagination pagination;

  NearbyUsersResponse({required this.users, required this.pagination});

  factory NearbyUsersResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List? ?? [];
    return NearbyUsersResponse(
      users: dataList
          .map((item) => NearbyUser.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: NearbyPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class NearbyUser {
  final String id;
  final String name;
  final List<String> images;
  final String? city;
  final String? country;
  final double distance;
  final String? nativeLanguage;
  final String? languageToLearn;
  final bool isOnline;
  final DateTime? lastSeen;

  NearbyUser({
    required this.id,
    required this.name,
    required this.images,
    this.city,
    this.country,
    required this.distance,
    this.nativeLanguage,
    this.languageToLearn,
    required this.isOnline,
    this.lastSeen,
  });

  factory NearbyUser.fromJson(Map<String, dynamic> json) {
    return NearbyUser(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      images: (json['images'] as List?)?.cast<String>() ?? [],
      city: (json['location'] as Map?)?['city'] as String?,
      country: (json['location'] as Map?)?['country'] as String?,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      nativeLanguage: json['native_language'] as String?,
      languageToLearn: json['language_to_learn'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String)
          : null,
    );
  }
}

class NearbyPagination {
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  NearbyPagination({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory NearbyPagination.fromJson(Map<String, dynamic> json) {
    return NearbyPagination(
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

/// Wave response
class WaveResponse {
  final String waveId;
  final bool isMutual;
  final String message;

  WaveResponse({
    required this.waveId,
    required this.isMutual,
    required this.message,
  });

  factory WaveResponse.fromJson(Map<String, dynamic> json) {
    return WaveResponse(
      waveId: json['waveId'] ?? '',
      isMutual: json['isMutual'] as bool? ?? false,
      message: json['message'] ?? 'Wave sent!',
    );
  }
}

/// Wave model
class Wave {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserImage;
  final String? message;
  final bool isRead;
  final DateTime createdAt;

  Wave({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserImage,
    this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory Wave.fromJson(Map<String, dynamic> json) {
    return Wave(
      id: json['_id'] ?? json['id'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUserName: json['fromUserName'] ?? '',
      fromUserImage: json['fromUserImage'] as String?,
      message: json['message'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// Topic model is imported from lib/models/community/topic_model.dart

// ==================== PROVIDERS ====================

final communityProvider = FutureProvider<List<Community>>((ref) async {
  final service = CommunityService();
  final communities = await service.getCommunity();

  // Sort with VIP users first, then by online status
  communities.sort((a, b) {
    // VIP users come first
    if (a.isVip && !b.isVip) return -1;
    if (!a.isVip && b.isVip) return 1;

    // Then online users
    if (a.isOnline && !b.isOnline) return -1;
    if (!a.isOnline && b.isOnline) return 1;

    return 0;
  });

  return communities;
});

final communityServiceProvider = Provider((ref) => CommunityService());

/// Nearby users provider with location parameters
final nearbyUsersProvider = FutureProvider.family<NearbyUsersResponse, NearbyUsersParams>(
  (ref, params) async {
    final service = ref.read(communityServiceProvider);
    return service.getNearbyUsers(
      latitude: params.latitude,
      longitude: params.longitude,
      radius: params.radius,
      limit: params.limit,
      offset: params.offset,
      language: params.language,
      onlineOnly: params.onlineOnly,
    );
  },
);

class NearbyUsersParams {
  final double latitude;
  final double longitude;
  final int? radius;
  final int? limit;
  final int? offset;
  final String? language;
  final bool? onlineOnly;

  NearbyUsersParams({
    required this.latitude,
    required this.longitude,
    this.radius,
    this.limit,
    this.offset,
    this.language,
    this.onlineOnly,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyUsersParams &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radius == other.radius &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      radius.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}

/// Topics provider
final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final service = ref.read(communityServiceProvider);
  return service.getTopics();
});

/// Waves received provider
final wavesProvider = FutureProvider<List<Wave>>((ref) async {
  final service = ref.read(communityServiceProvider);
  return service.getWavesReceived();
});
