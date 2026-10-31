import 'dart:convert';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/utils/string_sanitizer.dart';

/// A failed `POST community/wave`. Carries the HTTP status so callers can
/// tell the daily cap (429) apart from other refusals. [toString] is exactly
/// what the previous `Exception(message)` produced (`Exception: <message>`),
/// so every existing string-matching caller behaves identically.
class WaveSendException implements Exception {
  const WaveSendException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// Machine-readable error code from the body (`wave_cap` for the daily
  /// cap; absent for the rate limiter and older servers).
  final String? code;

  @override
  String toString() => 'Exception: $message';
}

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

  /// Get all community members (legacy - fetches first page only)
  Future<List<Community>> getCommunity() async {
    final result = await getCommunityPaginated(page: 1, limit: 20);
    return result.users;
  }

  /// Get community members with pagination and server-side filtering
  /// One page of `/users` for an already-built query
  /// ([PartnerFilterParams.toQuery]).
  Future<PaginatedCommunityResponse> getUsersPage(
    Map<String, String> query,
  ) async {
    final page = int.tryParse(query['page'] ?? '') ?? 1;
    final url = Uri.parse(
      '${Endpoints.baseURL}${Endpoints.usersURL}',
    ).replace(queryParameters: query);
    // Not ApiClient: it unwraps `data` and drops total/pages/hasMore.
    final response = await _getWithRefresh(url);
    if (response.statusCode == 200) {
      return PaginatedCommunityResponse.fromBody(
        json.decode(response.body) as Map<String, dynamic>,
        page: page,
      );
    }
    throw Exception(_serverError(response.body, response.statusCode));
  }

  /// GET with a timeout and, on a 401, one retry after refreshing the token
  /// (as ApiClient does). It used to refresh and then throw anyway.
  Future<http.Response> _getWithRefresh(Uri url) async {
    const timeout = Duration(seconds: 20);
    var response =
        await http.get(url, headers: await _getHeaders()).timeout(timeout);
    if (response.statusCode == 401 && await _apiClient.handleUnauthorized()) {
      response =
          await http.get(url, headers: await _getHeaders()).timeout(timeout);
    }
    return response;
  }

  static String _serverError(String body, int status) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {}
    return 'Request failed ($status)';
  }

  Future<PaginatedCommunityResponse> getCommunityPaginated({
    int page = 1,
    int limit = 20,
    String? nativeLanguage,
    String? learningLanguage,
    bool matchLanguage = false,
    String? gender,
    int? minAge,
    int? maxAge,
    bool? onlineOnly,
    String? country,
    String? languageLevel,
    String? search, // Server-side search
    String? sort, // e.g. 'recently_active'
    bool reciprocal = false,
    String? activeWithin, // '7d' | '30d'
    String? joinedWithin, // '7d' | '30d'
    List<String> topics = const [],
    int topicsAtLeast = 0,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Add filter parameters
      if (nativeLanguage != null && nativeLanguage.isNotEmpty) {
        queryParams['nativeLanguage'] = nativeLanguage;
      }
      if (learningLanguage != null && learningLanguage.isNotEmpty) {
        queryParams['learningLanguage'] = learningLanguage;
      }
      if (matchLanguage) {
        queryParams['matchLanguage'] = 'true';
      }
      if (gender != null && gender.isNotEmpty) {
        queryParams['gender'] = gender;
      }
      if (minAge != null && minAge > 18) {
        queryParams['minAge'] = minAge.toString();
      }
      if (maxAge != null && maxAge < 100) {
        queryParams['maxAge'] = maxAge.toString();
      }
      if (onlineOnly == true) {
        queryParams['onlineOnly'] = 'true';
      }
      if (country != null && country.isNotEmpty) {
        queryParams['country'] = country;
      }
      if (languageLevel != null && languageLevel.isNotEmpty) {
        queryParams['languageLevel'] = languageLevel;
      }
      // Server-side search
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      // Sort order
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }
      // Segment params (additive; only '7d'/'30d' are honored server-side)
      if (reciprocal) queryParams['reciprocal'] = 'true';
      if (activeWithin != null && activeWithin.isNotEmpty) {
        queryParams['activeWithin'] = activeWithin;
      }
      if (joinedWithin != null && joinedWithin.isNotEmpty) {
        queryParams['joinedWithin'] = joinedWithin;
      }
      // Same encoding as the filter sheet's live count (/users/count).
      if (topics.isNotEmpty) queryParams['topics'] = topics.join(',');
      if (topicsAtLeast > 0) {
        queryParams['topicsAtLeast'] = topicsAtLeast.toString();
      }

      final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.usersURL}',
      ).replace(queryParameters: queryParams);

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return PaginatedCommunityResponse.fromBody(
          json.decode(response.body) as Map<String, dynamic>,
          page: page,
        );
      } else if (response.statusCode == 401) {
        await _apiClient.handleUnauthorized();
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load community: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load community: $error');
    }
  }

  /// Get single user profile
  Future<Community?> getSingleCommunity({required id}) async {
    final response = await _getWithRefresh(
      Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/$id'),
    );
    if (response.statusCode == 200) {
      final userData = json.decode(response.body)['data'];
      if (userData is! Map<String, dynamic>) return null;
      return Community.fromJson(userData);
    }
    if (response.statusCode == 401) return null;
    // The server's message, once (it was wrapped twice and unreadable).
    throw Exception(_serverError(response.body, response.statusCode));
  }

  /// Follow a user (requires auth)
  /// Returns: 'success' | 'already_following' | 'error'
  Future<String> followUser({required userId, required targetUserId}) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
      '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/follow/$targetUserId',
    );
    try {
      final response = await http.put(url, headers: headers);

      if (response.statusCode == 401) {
        await _apiClient.handleUnauthorized();
        throw Exception('Authentication required');
      } else if (response.statusCode == 403) {
        _apiClient.onAuthorizationError?.call('You cannot follow this user');
        throw Exception('Not authorized');
      } else if (response.statusCode == 429) {
        _apiClient.onRateLimitError?.call(
          'Too many follow requests. Slow down!',
        );
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
        return 'error';
      } else {
        return 'error';
      }
    } catch (error) {
      rethrow;
    }
  }

  /// Unfollow a user (requires auth)
  /// Returns: 'success' | 'not_following' | 'error'
  Future<String> unfollowUser({required userId, required targetUserId}) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
      '${Endpoints.baseURL}${Endpoints.usersURL}/$userId/unfollow/$targetUserId',
    );
    try {
      final response = await http.put(url, headers: headers);

      if (response.statusCode == 401) {
        await _apiClient.handleUnauthorized();
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
        return 'error';
      } else {
        return 'error';
      }
    } catch (error) {
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
        throw WaveSendException(
          'Too many waves. Please slow down!',
          statusCode: response.statusCode,
          code: response.errorCode,
        );
      } else {
        throw WaveSendException(
          response.error ?? 'Failed to send wave',
          statusCode: response.statusCode,
          code: response.errorCode,
        );
      }
    } catch (error) {
      rethrow;
    }
  }

  /// Get waves received
  Future<List<Wave>> getWavesReceived({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    bool archive = false,
    bool reveal = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'unreadOnly': unreadOnly.toString(),
      };
      if (archive) queryParams['archive'] = 'true';
      // Opt in to the gated shape (masked rows + `revealed`); only sent when
      // the boostsEnabled flag is on, so live builds get today's payload.
      if (reveal) queryParams['reveal'] = '1';
      final response = await _apiClient.get(
        Endpoints.wavesReceivedURL,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        // ApiClient returns the full body when the response has both
        // `data` and `pagination` keys. The waves endpoint's `data` is
        // itself an object: { waves: [...], unreadCount: N }.
        // Older endpoints used `data: [...]` directly, so support both.
        final inner = response.data['data'];
        final List dataList;
        if (inner is List) {
          dataList = inner;
        } else if (inner is Map && inner['waves'] is List) {
          dataList = inner['waves'] as List;
        } else {
          dataList = const [];
        }
        return dataList
            .map((item) => Wave.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.error ?? 'Failed to get waves');
      }
    } catch (error) {
      rethrow;
    }
  }

  /// Server-side unread wave count (the `unreadCount` field of the waves
  /// response) -- not the size of the returned page.
  Future<int> getWavesUnreadCount() async {
    final response = await _apiClient.get(
      Endpoints.wavesReceivedURL,
      queryParams: {'page': '1', 'limit': '1', 'unreadOnly': 'true'},
    );
    if (response.success && response.data != null) {
      return parseWavesUnreadCount(response.data);
    }
    throw Exception(response.error ?? 'Failed to get waves');
  }

  /// Mark waves as read
  Future<void> markWavesAsRead({List<String>? waveIds}) async {
    try {
      await _apiClient.put(
        Endpoints.wavesReadURL,
        body: waveIds != null ? {'waveIds': waveIds} : null,
      );
    } catch (error) {
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
        final dataList =
            response.data['data'] as List? ?? response.data as List? ?? [];
        return dataList
            .map((item) => Topic.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.error ?? 'Failed to get topics');
      }
    } catch (error) {
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
        queryParams: {'page': page.toString(), 'limit': limit.toString()},
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
      rethrow;
    }
  }

  /// Get countries list
  Future<void> getCountriesList() async {
    final url = Uri.parse(Endpoints.countriesURL);
    try {
      await http.get(url);
    } catch (error) {
      throw Exception('Failed to call the api: $error');
    }
  }

  /// Get push notification preferences for the current user.
  Future<Map<String, bool>> getNotificationPreferences() async {
    final response = await _apiClient.get(
      '${Endpoints.usersURL}/me/notification-preferences',
    );
    if (response.success && response.data != null) {
      final data = response.data is Map ? response.data : null;
      final prefs = data?['prefs'] as Map?;
      return prefs?.map((k, v) => MapEntry(k.toString(), v == true)) ?? {};
    }
    throw Exception(response.error ?? 'Failed to load preferences');
  }

  /// Update push notification preferences for the current user (partial update OK).
  Future<Map<String, bool>> updateNotificationPreferences(
    Map<String, bool> prefs,
  ) async {
    final response = await _apiClient.put(
      '${Endpoints.usersURL}/me/notification-preferences',
      body: {'prefs': prefs},
    );
    if (response.success && response.data != null) {
      final data = response.data is Map ? response.data : null;
      final returned = data?['prefs'] as Map?;
      return returned?.map((k, v) => MapEntry(k.toString(), v == true)) ?? {};
    }
    throw Exception(response.error ?? 'Failed to update preferences');
  }

  /// Get matching user count for a given filter map (used by live match-count in filter sheet).
  Future<int> getUsersCount({Map<String, dynamic>? filters}) async {
    try {
      final params = <String, String>{};
      if (filters != null) {
        filters.forEach((k, v) {
          if (v == null || v == '') return;
          if (v is List) {
            if (v.isEmpty) return;
            // Serialize lists as comma-separated values (e.g. topics=a,b,c)
            params[k] = v.join(',');
          } else {
            params[k] = v.toString();
          }
        });
      }
      final response = await _apiClient.get(
        '${Endpoints.usersURL}/count',
        queryParams: params,
      );
      if (response.success && response.data != null) {
        final data = response.data is Map ? response.data as Map : null;
        return (data?['count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

// ==================== MODELS ====================

/// Nearby users response
class NearbyUsersResponse {
  final List<NearbyUser> users;
  final NearbyPagination pagination;

  /// The radius the server actually searched and the most this account may
  /// ask for (free accounts are capped); null from older servers.
  final int? searchedRadiusKm;
  final int? maxRadiusKm;

  NearbyUsersResponse({
    required this.users,
    required this.pagination,
    this.searchedRadiusKm,
    this.maxRadiusKm,
  });

  factory NearbyUsersResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List? ?? [];
    return NearbyUsersResponse(
      users: dataList
          .map((item) => NearbyUser.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: NearbyPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
      searchedRadiusKm: (json['search'] is Map && json['search']['radiusKm'] is num)
          ? (json['search']['radiusKm'] as num).round()
          : null,
      maxRadiusKm: (json['search'] is Map && json['search']['maxRadiusKm'] is num)
          ? (json['search']['maxRadiusKm'] as num).round()
          : null,
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
  final PrivacySettings? privacySettings;
  final int? age;

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
    this.privacySettings,
    this.age,
  });

  factory NearbyUser.fromJson(Map<String, dynamic> json) {
    // Calculate age from birth_year
    int? age;
    final birthYear = json['birth_year'];
    if (birthYear != null) {
      final year = int.tryParse(birthYear.toString());
      if (year != null && year > 0) {
        age = DateTime.now().year - year;
      }
    }

    return NearbyUser(
      id: json['_id'] ?? json['id'] ?? '',
      name: sanitize(json['name']),
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
      privacySettings: json['privacySettings'] != null
          ? PrivacySettings.fromJson(
              json['privacySettings'] as Map<String, dynamic>,
            )
          : null,
      age: age,
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
      message: json['message'] ?? '',
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

  /// False when the server masked the sender (`?reveal=1` and the viewer has
  /// not unlocked it): `from` carries no id and no name. Defaults to true so
  /// legacy payloads (no `revealed` key) render exactly as before.
  final bool revealed;

  Wave({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserImage,
    this.message,
    required this.isRead,
    required this.createdAt,
    this.revealed = true,
  });

  factory Wave.fromJson(Map<String, dynamic> json) {
    final from = json['from'];
    final fromMap = from is Map<String, dynamic> ? from : null;
    final images = fromMap?['images'];
    return Wave(
      id: json['waveId'] ?? json['_id'] ?? json['id'] ?? '',
      fromUserId: (fromMap?['_id'] ?? json['fromUserId'] ?? '') as String,
      fromUserName: (fromMap?['name'] ?? json['fromUserName'] ?? '') as String,
      fromUserImage: (images is List && images.isNotEmpty)
          ? images.first as String?
          : json['fromUserImage'] as String?,
      message: json['message'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      revealed: json['revealed'] as bool? ?? true,
    );
  }
}

// Topic model is imported from lib/models/community/topic_model.dart

/// Paginated community response
class PaginatedCommunityResponse {
  final List<Community> users;
  final int total;
  final int page;
  final int pages;
  final bool hasMore;

  PaginatedCommunityResponse({
    required this.users,
    required this.total,
    required this.page,
    required this.pages,
    required this.hasMore,
  });

  /// A `/users` body. `hasMore` is the server's when it sends one (backend
  /// cc5064b+), else `page < pages` as before.
  factory PaginatedCommunityResponse.fromBody(
    Map<String, dynamic> data, {
    required int page,
  }) {
    final dataList = data['data'];
    final pages = data['pages'] as int? ?? 1;
    if (dataList is! List) {
      return PaginatedCommunityResponse(
        users: [],
        total: 0,
        page: page,
        pages: 1,
        hasMore: false,
      );
    }
    return PaginatedCommunityResponse(
      users: [
        for (final item in dataList)
          if (item is Map<String, dynamic>) Community.fromJson(item),
      ],
      total: data['total'] as int? ?? 0,
      page: page,
      pages: pages,
      hasMore: data['hasMore'] as bool? ?? page < pages,
    );
  }
}

/// State for paginated community list
class PaginatedCommunityState {
  final List<Community> users;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const PaginatedCommunityState({
    this.users = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedCommunityState copyWith({
    List<Community>? users,
    int? currentPage,
    int? totalPages,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedCommunityState(
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// State notifier for paginated community
class PaginatedCommunityNotifier
    extends StateNotifier<PaginatedCommunityState> {
  final CommunityService _service;
  static const int _pageSize = 20;

  PaginatedCommunityNotifier(this._service)
    : super(const PaginatedCommunityState());

  /// Load initial data (first page)
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getCommunityPaginated(
        page: 1,
        limit: _pageSize,
      );

      // Sort with VIP users first, then by online status
      final sortedUsers = List<Community>.from(response.users);
      sortedUsers.sort((a, b) {
        if (a.isVip && !b.isVip) return -1;
        if (!a.isVip && b.isVip) return 1;
        if (a.isOnline && !b.isOnline) return -1;
        if (!a.isOnline && b.isOnline) return 1;
        return 0;
      });

      state = state.copyWith(
        users: sortedUsers,
        currentPage: 1,
        totalPages: response.pages,
        total: response.total,
        hasMore: response.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load next page
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _service.getCommunityPaginated(
        page: nextPage,
        limit: _pageSize,
      );

      // Sort new users with VIP first
      final sortedNewUsers = List<Community>.from(response.users);
      sortedNewUsers.sort((a, b) {
        if (a.isVip && !b.isVip) return -1;
        if (!a.isVip && b.isVip) return 1;
        if (a.isOnline && !b.isOnline) return -1;
        if (!a.isOnline && b.isOnline) return 1;
        return 0;
      });

      state = state.copyWith(
        users: [...state.users, ...sortedNewUsers],
        currentPage: nextPage,
        totalPages: response.pages,
        total: response.total,
        hasMore: response.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Refresh (reload from first page)
  Future<void> refresh() async {
    state = const PaginatedCommunityState();
    await loadInitial();
  }
}

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

/// Live match-count provider — call with [FilterState.toJson()] as the family key.
/// Uses [Map<String, dynamic>] so identical filter maps share the same cache slot.
final filterMatchCountProvider = FutureProvider.autoDispose
    .family<int, Map<String, dynamic>>((ref, filters) {
      return ref.read(communityServiceProvider).getUsersCount(filters: filters);
    });

/// Single user/community provider - fetches user details by ID
final singleCommunityProvider = FutureProvider.family<Community?, String>((
  ref,
  userId,
) async {
  final service = ref.read(communityServiceProvider);
  return service.getSingleCommunity(id: userId);
});

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

/// Returns the count of unread waves for the current user. Refresh on
/// app resume and after `markWavesAsRead`.
final wavesUnreadProvider = FutureProvider<int>((ref) async {
  final service = ref.read(communityServiceProvider);
  try {
    return await service.getWavesUnreadCount();
  } catch (e) {
    // Errors read as 0 deliberately: a badge that can't be verified is
    // hidden rather than showing a stale or guessed number.
    return 0;
  }
});

/// Pure mapping from the waves response body to the unread badge count.
/// The body is `{ data: { waves: [...], unreadCount: N }, pagination }`.
/// Anything missing or malformed reads as 0.
int parseWavesUnreadCount(dynamic body) {
  if (body is! Map) return 0;
  final inner = body['data'];
  if (inner is! Map) return 0;
  final n = inner['unreadCount'];
  if (n is int) return n < 0 ? 0 : n;
  if (n is num) return n.toInt() < 0 ? 0 : n.toInt();
  if (n is String) return int.tryParse(n) ?? 0;
  return 0;
}

/// Pending (unread) intros/waves for the current user, consumed by the
/// intros strip and the waves badge.
final pendingIntrosProvider = FutureProvider<List<Wave>>((ref) {
  return ref
      .read(communityServiceProvider)
      .getWavesReceived(unreadOnly: true, limit: 20);
});

// ==================== TOPIC USERS PAGINATED ====================

/// State for paginated topic users
class TopicUsersState {
  final String? topicId;
  final List<Community> users;
  final int currentPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const TopicUsersState({
    this.topicId,
    this.users = const [],
    this.currentPage = 0,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  TopicUsersState copyWith({
    String? topicId,
    List<Community>? users,
    int? currentPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return TopicUsersState(
      topicId: topicId ?? this.topicId,
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Notifier for paginated topic users
class TopicUsersNotifier extends StateNotifier<TopicUsersState> {
  final CommunityService _service;
  static const int _pageSize = 20;

  TopicUsersNotifier(this._service) : super(const TopicUsersState());

  /// Load users for a topic
  Future<void> loadTopic(String topicId) async {
    if (state.isLoading) return;

    // Reset if different topic
    if (state.topicId != topicId) {
      state = TopicUsersState(topicId: topicId, isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final users = await _service.getUsersByTopic(
        topicId,
        page: 1,
        limit: _pageSize,
      );

      state = state.copyWith(
        users: users,
        currentPage: 1,
        hasMore: users.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more users for current topic
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.topicId == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final users = await _service.getUsersByTopic(
        state.topicId!,
        page: nextPage,
        limit: _pageSize,
      );

      state = state.copyWith(
        users: [...state.users, ...users],
        currentPage: nextPage,
        hasMore: users.length >= _pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Clear current topic
  void clear() {
    state = const TopicUsersState();
  }
}

/// Provider for paginated topic users
final topicUsersProvider =
    StateNotifierProvider<TopicUsersNotifier, TopicUsersState>((ref) {
      final service = ref.read(communityServiceProvider);
      return TopicUsersNotifier(service);
    });

// ==================== PARTNER FILTER (SERVER-SIDE) ====================

/// Filter parameters for partner discovery
class PartnerFilterParams {
  final String? nativeLanguage;
  final String? learningLanguage;
  final String? gender;
  final int? minAge;
  final int? maxAge;
  final bool onlineOnly;
  final String? country;
  final String? languageLevel;
  final String? search; // Server-side search query
  final String? sort; // e.g. 'recently_active'
  final bool reciprocal;
  final String? activeWithin; // '7d' | '30d'
  final String? joinedWithin; // '7d' | '30d'
  final List<String> topics;
  final int topicsAtLeast; // 0 = off
  final bool sameCity; // the viewer's own city (backend cc5064b+)

  const PartnerFilterParams({
    this.nativeLanguage,
    this.learningLanguage,
    this.gender,
    this.minAge,
    this.maxAge,
    this.onlineOnly = false,
    this.country,
    this.languageLevel,
    this.search,
    this.sort,
    this.reciprocal = false,
    this.activeWithin,
    this.joinedWithin,
    this.topics = const [],
    this.topicsAtLeast = 0,
    this.sameCity = false,
  });

  PartnerFilterParams copyWith({
    String? nativeLanguage,
    String? learningLanguage,
    String? gender,
    int? minAge,
    int? maxAge,
    bool? onlineOnly,
    String? country,
    String? languageLevel,
    String? search,
    String? sort,
    bool? reciprocal,
    String? activeWithin,
    String? joinedWithin,
    List<String>? topics,
    int? topicsAtLeast,
    bool? sameCity,
  }) {
    return PartnerFilterParams(
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      learningLanguage: learningLanguage ?? this.learningLanguage,
      gender: gender ?? this.gender,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      country: country ?? this.country,
      languageLevel: languageLevel ?? this.languageLevel,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      reciprocal: reciprocal ?? this.reciprocal,
      activeWithin: activeWithin ?? this.activeWithin,
      joinedWithin: joinedWithin ?? this.joinedWithin,
      topics: topics ?? this.topics,
      topicsAtLeast: topicsAtLeast ?? this.topicsAtLeast,
      sameCity: sameCity ?? this.sameCity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartnerFilterParams &&
          nativeLanguage == other.nativeLanguage &&
          learningLanguage == other.learningLanguage &&
          gender == other.gender &&
          minAge == other.minAge &&
          maxAge == other.maxAge &&
          onlineOnly == other.onlineOnly &&
          country == other.country &&
          languageLevel == other.languageLevel &&
          search == other.search &&
          sort == other.sort &&
          reciprocal == other.reciprocal &&
          activeWithin == other.activeWithin &&
          joinedWithin == other.joinedWithin &&
          listEquals(topics, other.topics) &&
          topicsAtLeast == other.topicsAtLeast &&
          sameCity == other.sameCity;

  @override
  int get hashCode =>
      nativeLanguage.hashCode ^
      learningLanguage.hashCode ^
      gender.hashCode ^
      minAge.hashCode ^
      maxAge.hashCode ^
      onlineOnly.hashCode ^
      country.hashCode ^
      languageLevel.hashCode ^
      search.hashCode ^
      sort.hashCode ^
      reciprocal.hashCode ^
      activeWithin.hashCode ^
      joinedWithin.hashCode ^
      Object.hashAll(topics) ^
      topicsAtLeast.hashCode ^
      sameCity.hashCode;

  /// The `/users` query string. The list always sends `matchLanguage=true`;
  /// the filter sheet's count calls this without paging/sort so both ask the
  /// server the same question.
  Map<String, String> toQuery({int? page, int? limit, String? sort}) {
    bool set(String? v) => v != null && v.isNotEmpty;
    return {
      if (page != null) 'page': '$page',
      if (limit != null) 'limit': '$limit',
      if (set(nativeLanguage)) 'nativeLanguage': nativeLanguage!,
      if (set(learningLanguage)) 'learningLanguage': learningLanguage!,
      'matchLanguage': 'true',
      if (set(gender)) 'gender': gender!,
      if (minAge != null && minAge! > 18) 'minAge': '$minAge',
      if (maxAge != null && maxAge! < 100) 'maxAge': '$maxAge',
      if (onlineOnly) 'onlineOnly': 'true',
      if (set(country)) 'country': country!,
      if (set(languageLevel)) 'languageLevel': languageLevel!,
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (set(sort)) 'sort': sort!,
      if (reciprocal) 'reciprocal': 'true',
      if (set(activeWithin)) 'activeWithin': activeWithin!,
      if (set(joinedWithin)) 'joinedWithin': joinedWithin!,
      if (topics.isNotEmpty) 'topics': topics.join(','),
      if (topicsAtLeast > 0) 'topicsAtLeast': '$topicsAtLeast',
      if (sameCity) 'sameCity': 'true',
    };
  }
}

/// Quick segment over the partner list (mutually exclusive).
enum PartnerSegment {
  all,
  serious,
  newMembers;

  /// Recency window sent as `activeWithin` (null = not restricted).
  String? get activeWithin => this == serious ? '7d' : null;

  /// Join window sent as `joinedWithin` (null = not restricted).
  String? get joinedWithin => this == newMembers ? '7d' : null;
}

/// Currently selected partner segment. Shared so the filter sheet's live
/// count can request the same segment as the list.
final partnerSegmentProvider = StateProvider<PartnerSegment>(
  (ref) => PartnerSegment.all,
);

/// State for server-side filtered partners
class PartnerFilterState {
  final PartnerFilterParams? filters;
  final List<Community> users;
  final int currentPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const PartnerFilterState({
    this.filters,
    this.users = const [],
    this.currentPage = 0,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  PartnerFilterState copyWith({
    PartnerFilterParams? filters,
    List<Community>? users,
    int? currentPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return PartnerFilterState(
      filters: filters ?? this.filters,
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Notifier for server-side filtered partners
class PartnerFilterNotifier extends StateNotifier<PartnerFilterState> {
  final CommunityService _service;

  /// Whether the server offers the ranked list, read at REQUEST time rather
  /// than at construction: the app-config fetch may still be in flight when
  /// this notifier is built, and a flag latched too early would be wrong for
  /// the rest of the session.
  final bool Function() _smartSortEnabled;

  static const int _pageSize = 20;

  PartnerFilterNotifier(this._service, this._smartSortEnabled)
    : super(const PartnerFilterState());

  /// The sort to ask the server for.
  ///
  /// An explicit user choice always wins -- picking "recently active" and
  /// silently getting relevance ranking would be a lie. Only the DEFAULT
  /// becomes `smart`, and only when the server says it is available; an older
  /// server ignores the parameter anyway, but asking for something it does not
  /// offer would misdescribe the response.
  String? _sortFor(PartnerFilterParams filters) {
    final chosen = filters.sort;
    if (chosen != null && chosen.isNotEmpty) return chosen;
    return _smartSortEnabled() ? 'smart' : null;
  }

  /// Bumped by every page-1 load (new filters or refresh). A page-2 response
  /// started under an older generation is dropped: a refresh that finished
  /// first used to end with the old page 2 appended to the new page 1.
  int _generation = 0;

  /// Load partners with filters (server-side)
  Future<void> loadWithFilters(PartnerFilterParams filters) async {
    // A CHANGED filters value must proceed even mid-load (a chip tap would
    // otherwise be dropped forever); the stale response is discarded below.
    if (state.isLoading && state.filters == filters) return;

    _generation++;
    // Reset if different filters; same filters (refresh) keep the rows on
    // screen until page 1 arrives instead of flashing the skeleton.
    if (state.filters != filters) {
      state = PartnerFilterState(filters: filters, isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _service.getUsersPage(
        filters.toQuery(page: 1, limit: _pageSize, sort: _sortFor(filters)),
      );

      // Filters changed while this request was in flight: drop the stale page.
      if (state.filters != filters) return;

      // If 0 results returned, set hasMore to false to prevent infinite loading
      final hasMore = response.users.isNotEmpty && response.hasMore;

      state = state.copyWith(
        users: response.users,
        currentPage: 1,
        total: response.total,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      if (state.filters != filters) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more partners with same filters
  /// When the last page request failed. Scroll events fire continuously at
  /// the end of the list, so without a pause a dropped connection turned
  /// into a stream of requests.
  DateTime? _loadMoreFailedAt;
  static const loadMoreRetryPause = Duration(seconds: 5);

  /// [force]: the user tapped Retry, so skip the pause.
  Future<void> loadMore({bool force = false}) async {
    if (state.isLoadingMore || !state.hasMore || state.filters == null) return;
    final failedAt = _loadMoreFailedAt;
    if (!force &&
        failedAt != null &&
        DateTime.now().difference(failedAt) < loadMoreRetryPause) {
      return;
    }

    final filtersAtStart = state.filters;
    final generationAtStart = _generation;
    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final filters = state.filters!;
      // Same sort resolution as page 1: under the smart default, sending the
      // raw choice made later pages use another order (dupes and gaps).
      final response = await _service.getUsersPage(
        filters.toQuery(page: nextPage, limit: _pageSize, sort: _sortFor(filters)),
      );

      // Segment/filters switched, or page 1 reloaded, mid-request: drop it.
      if (state.filters != filtersAtStart || _generation != generationAtStart) {
        return;
      }

      // If 0 results returned on load more, stop trying to load more
      final hasMore = response.users.isNotEmpty && response.hasMore;

      // A Profile Boost puts a booster on page 1 out of order, so the same
      // person can come back on a later page; list them once.
      final seen = {for (final u in state.users) u.id};
      state = state.copyWith(
        users: [
          ...state.users,
          ...response.users.where((u) => seen.add(u.id)),
        ],
        currentPage: nextPage,
        total: response.total,
        hasMore: hasMore,
        isLoadingMore: false,
      );
      _loadMoreFailedAt = null;
    } catch (e) {
      if (state.filters != filtersAtStart || _generation != generationAtStart) {
        return;
      }
      _loadMoreFailedAt = DateTime.now();
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Refresh with current filters. The current rows stay until page 1
  /// arrives; an in-flight page 2 is dropped (see [_generation]).
  Future<void> refresh() async {
    final filters = state.filters;
    if (filters == null) return;
    state = state.copyWith(isLoading: false, isLoadingMore: false);
    await loadWithFilters(filters);
  }

  /// Clear state
  void clear() {
    state = const PartnerFilterState();
  }
}

/// Provider for server-side filtered partners
final partnerFilterProvider =
    StateNotifierProvider<PartnerFilterNotifier, PartnerFilterState>((ref) {
      final service = ref.read(communityServiceProvider);
      return PartnerFilterNotifier(
        service,
        () =>
            ref
                .read(appConfigProvider)
                .maybeWhen(
                  data: (config) => config?.smartSortEnabled,
                  orElse: () => false,
                ) ??
            false,
      );
    });
