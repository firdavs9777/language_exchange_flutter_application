import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/pages/moments/create/moment_media_rules.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/moments_service.dart' as api;
// Only imported for the active-tab → provider mapping reused by
// `invalidateMomentFeeds` below (`MomentsFeedTab`/`momentsFeedTabProvider`/
// `baseProviderFor` live there since they're intrinsic to the feed screen's
// tab state). This does create an import edge back to a page-level file,
// which Dart's compiler handles fine (no `part`-style restriction on
// import cycles) — see the moments audit I2/P1 fix report for why reusing
// the existing mapping was preferred over duplicating/moving it.
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart'
    show momentsFeedTabProvider, baseProviderFor;

typedef MomentsServiceAPI = api.MomentsService;

class MomentsService {
  int count = 0;

  // Updated getMoments with pagination support
  /// GET /clubs/:id/moments — a club's members-only and shared posts (clubs
  /// v2). Same shape as the main feed.
  Future<List<Moments>> getClubMoments(String clubId, {int page = 1, int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('${Endpoints.baseURL}clubs/$clubId/moments?page=$page&limit=$limit'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load club posts (${response.statusCode})');
    }
    final data = json.decode(response.body);
    final list = data is Map ? data['moments'] : null;
    return list is List
        ? list.whereType<Map<String, dynamic>>().map(Moments.fromJson).toList()
        : <Moments>[];
  }

  Future<Map<String, dynamic>> getMoments(
      {int page = 1, int limit = 10, String? feed, String? q}) async {
    // Enforce max limit of 50 per page
    if (limit > 50) {
      limit = 50;
    }

    // Include auth token so backend can filter blocked users and populate likedUsers correctly
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    var url = '${Endpoints.baseURL}${Endpoints.momentsURL}?page=$page&limit=$limit';
    if (feed != null) {
      url += '&feed=$feed';
    }
    // Server-side search (title, caption, tags; lib/momentFilters).
    if (q != null && q.trim().isNotEmpty) {
      url += '&q=${Uri.encodeQueryComponent(q.trim())}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> momentsList = data['moments'] ?? [];
      final pagination = data['pagination'] ?? {};

      return {
        'moments':
            momentsList.map((postJson) => Moments.fromJson(postJson)).toList(),
        'pagination': pagination,
        'feedMode': data['feedMode'],
      };
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ??
                          errorData['message'] ??
                          'Failed to load moments';

      // Log the actual backend error for debugging

      throw Exception(errorMessage);
    }
  }

  /// Fetch the deterministic prompt-of-the-day. Language is derived
  /// server-side from the authenticated user's `language_to_learn` when
  /// omitted, so no param is required from the client.
  Future<Map<String, dynamic>> getPromptOfDay({String? language}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    var url = '${Endpoints.baseURL}${Endpoints.momentsURL}/prompt-of-day';
    if (language != null && language.isNotEmpty) {
      url += '?language=$language';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Map<String, dynamic>.from(data['data']);
      }
      throw Exception(data['error'] ?? 'Failed to load prompt of the day');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ??
          errorData['message'] ??
          'Failed to load prompt of the day');
    }
  }

  Future<List<Moments>> getMomentsUser({required String id, int page = 1, int limit = 10}) async {
    // Enforce max limit of 50 per page
    if (limit > 50) {
      limit = 50;
    }

    // Authenticated: without the token the server can't filter blocked
    // users, include the caller's own non-public moments, or stamp
    // isLiked/isSaved/likedUsers for the like and bookmark buttons.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = '${Endpoints.baseURL}${Endpoints.momentsURL}/user/$id?page=$page&limit=$limit';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List<dynamic> momentsList = data['data'] ?? [];
        count = data['count'] ?? 0;

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('count', count.toString());

        return momentsList.map((json) => Moments.fromJson(json)).toList();
      } else {
        throw Exception(data['error'] ?? 'Failed to load user moments');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ??
                     errorData['message'] ??
                     'Failed to load user moments');
    }
  }

  Future<Moments> createMoments({
    required String description,
    String privacy = 'public',
    String category = 'general',
    String language = 'en',
    String? mood,
    List<String>? tags,
    String? scheduledFor,
    Map<String, dynamic>? location,
    String? backgroundColor,
    String? promptId,
    bool isReel = false,
    String? club,
    Map<String, int>? activity,
  }) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    // Build the request body - DO NOT include 'user' field (backend uses authenticated user from token)
    final Map<String, dynamic> body = {
      'description': description.trim(),
      'privacy': privacy,
      'category': category,
      'language': language,
    };

    // Add optional fields only if they have values
    if (mood != null && mood.isNotEmpty) {
      body['mood'] = mood;
    }
    if (tags != null && tags.isNotEmpty) {
      // Enforce max 5 tags
      body['tags'] = tags.take(5).toList();
    }
    if (scheduledFor != null && scheduledFor.isNotEmpty) {
      body['scheduledFor'] = scheduledFor;
    }
    if (location != null && location.isNotEmpty) {
      body['location'] = location;
    }
    if (backgroundColor != null && backgroundColor.isNotEmpty) {
      body['backgroundColor'] = backgroundColor;
    }
    if (promptId != null && promptId.isNotEmpty) {
      body['promptId'] = promptId;
    }
    // Workstream G: flags the moment as a Reel (thumbnail-grid + swipe-feed
    // surface) instead of a regular card-feed post. Backend contract:
    // `docs/superpowers/plans/2026-07-14-reels.md` Task 1.
    if (isReel) {
      body['isReel'] = true;
    }
    // Clubs v2: a post in a club's feed (privacy 'club' or 'public').
    if (club != null && club.isNotEmpty) {
      body['club'] = club;
      if (activity != null && activity.isNotEmpty) body['activity'] = activity;
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Moments.fromJson(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Failed to create moment');
      }
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ??
                          errorData['message'] ??
                          'Failed to create moment';
      throw Exception(errorMessage);
    }
  }

  Future<Moments> getSingleMoment({required String id}) async {
    // Authenticated for the same reason as getMoments: isLiked/isSaved and
    // blocked-user handling only exist when the server knows the viewer.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Moments.fromJson(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Moment not found');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Moment not found');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 
                     errorData['message'] ?? 
                     'Failed to load moment');
    }
  }

  /// Updates a moment. Nullable fields are omitted when null; a non-null
  /// empty value is SENT, so `mood: ''`, `tags: []` and
  /// `backgroundColor: ''` clear the field (the server accepts all three).
  ///
  /// [location] / [scheduledFor] are sent only when [includeLocation] /
  /// [includeScheduledFor] is true, and then a null value clears them
  /// (the server publishes a scheduled moment immediately when its schedule
  /// is cleared). `images` is not sent: the server ignores it on update.
  Future<Moments> updateMoment({
    required String id,
    required String description,
    String? category,
    String? mood,
    List<String>? tags,
    String? backgroundColor,
    String? language,
    String? privacy,
    bool includeLocation = false,
    Map<String, dynamic>? location,
    bool includeScheduledFor = false,
    String? scheduledFor,
  }) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/$id');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final body = momentUpdateBody(
      description: description,
      category: category,
      mood: mood,
      tags: tags,
      backgroundColor: backgroundColor,
      language: language,
      privacy: privacy,
      includeLocation: includeLocation,
      location: location,
      includeScheduledFor: includeScheduledFor,
      scheduledFor: scheduledFor,
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Moments.fromJson(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Failed to update moment');
      }
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? 
                          errorData['message'] ?? 
                          'Failed to update moment';
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> deleteUserMoment({required String id}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final response = await http.delete(
      Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return {
          "success": true,
          "data": data['data'] ?? {},
          "message": data['message'] ?? 'Moment deleted successfully',
        };
      } else {
        throw Exception(data['error'] ?? 'Failed to delete moment');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Not authorized to delete this moment');
    } else if (response.statusCode == 404) {
      throw Exception('Moment not found');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 
                     errorData['message'] ?? 
                     'Failed to delete moment');
    }
  }

  Future<void> uploadMomentPhotos(
      String momentId, List<File> imageFiles) async {
    if (imageFiles.isEmpty) {
      throw Exception('No images to upload');
    }

    // Enforce max 10 images per moment
    if (imageFiles.length > 10) {
      throw Exception('Maximum 10 images allowed per moment');
    }

    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/photo');
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    // Validate and add files
    for (var imageFile in imageFiles) {
      // Same rule the composer and the upload queue check BEFORE creating
      // the moment (moment_media_rules.dart); kept here as the last guard.
      final problem = momentImageProblem(
        path: imageFile.path,
        sizeBytes: await imageFile.length(),
      );
      if (problem != null) throw Exception(problem);

      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = kMomentImageMimeTypes[extension]!;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] != true) {
          throw Exception(responseData['error'] ?? 'Failed to upload images');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 
                       errorData['message'] ?? 
                       'Failed to upload images');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error uploading images: $e');
    }
  }

  /// Upload video to moment (max 10 minutes, max 1GB)
  /// Returns the updated moment with video data
  /// Includes progress callback for upload tracking
  Future<Map<String, dynamic>> uploadMomentVideo(
    String momentId,
    File videoFile, {
    Function(int)? onProgress,
  }) async {
    // Validate file size (1GB max)
    final fileSize = await videoFile.length();
    if (fileSize > 1024 * 1024 * 1024) {
      throw Exception('Video size exceeds 1GB limit');
    }

    // Validate file extension
    final extension = videoFile.path.split('.').last.toLowerCase();
    String? mimeType;
    switch (extension) {
      case 'mp4':
        mimeType = 'video/mp4';
        break;
      case 'mov':
        mimeType = 'video/quicktime';
        break;
      case 'avi':
        mimeType = 'video/x-msvideo';
        break;
      case 'webm':
        mimeType = 'video/webm';
        break;
      case '3gp':
        mimeType = 'video/3gpp';
        break;
      case 'm4v':
        mimeType = 'video/x-m4v';
        break;
      default:
        throw Exception(
            'Unsupported video format: $extension. Supported: MP4, MOV, AVI, WebM, 3GP, M4V');
    }

    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/video');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    try {

      final streamedResponse = await request.send();


      // Track upload progress
      int uploaded = 0;
      final totalBytes = fileSize;

      final responseBytes = <int>[];
      await for (final chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        uploaded += chunk.length;
        final progress = ((uploaded / totalBytes) * 100).clamp(0, 100).toInt();
        onProgress?.call(progress);
      }

      final response = http.Response.bytes(
        responseBytes,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
      );


      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData['data'] ?? {};
      } else {
        // Handle specific backend errors
        final errorMessage = responseData['error'] ??
            responseData['message'] ??
            'Failed to upload video';


        // Check for video service unavailable errors
        if (errorMessage.toString().toLowerCase().contains('unavailable') ||
            errorMessage.toString().toLowerCase().contains('processing') ||
            errorMessage.toString().toLowerCase().contains('service')) {
          throw Exception('Video Service processing unavailable: $errorMessage');
        }

        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error uploading video: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response from server. Video service may be unavailable.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error uploading video: $e');
    }
  }

  /// Upload audio (voice note) to a moment (max 60 seconds, max 10MB).
  /// Mirrors `uploadMomentVideo`; hits the Task 4 backend contract at
  /// PUT /moments/:id/audio (multipart field name `audio`, plus
  /// `duration` and optional `waveform` fields).
  /// Returns the updated moment's audio data (`{_id, audio, mediaType}`).
  Future<Map<String, dynamic>> uploadMomentAudio(
    String momentId,
    File audioFile,
    int durationSeconds, {
    List<double>? waveform,
  }) async {
    // Validate duration (backend also enforces <=60s)
    if (durationSeconds > 60) {
      throw Exception('Audio duration cannot exceed 60 seconds');
    }

    // Validate file size (10MB max)
    final fileSize = await audioFile.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('Audio size exceeds 10MB limit');
    }

    // Determine content type from file extension
    final extension = audioFile.path.split('.').last.toLowerCase();
    String mimeType;
    switch (extension) {
      case 'm4a':
        mimeType = 'audio/m4a';
        break;
      case 'mp3':
        mimeType = 'audio/mpeg';
        break;
      case 'wav':
        mimeType = 'audio/wav';
        break;
      case 'aac':
        mimeType = 'audio/aac';
        break;
      case 'ogg':
        mimeType = 'audio/ogg';
        break;
      default:
        mimeType = 'audio/mpeg';
    }

    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/audio');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['duration'] = durationSeconds.toString();
    if (waveform != null && waveform.isNotEmpty) {
      request.fields['waveform'] = jsonEncode(waveform);
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData['data'] ?? {};
      } else {
        final errorMessage = responseData['error'] ??
            responseData['message'] ??
            'Failed to upload audio';
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error uploading audio: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid response from server: ${e.message}');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error uploading audio: $e');
    }
  }

  /// Delete video from moment
  Future<void> deleteMomentVideo(String momentId) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/video');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = json.decode(response.body);

    if (response.statusCode != 200 || responseData['success'] != true) {
      throw Exception(responseData['error'] ??
          responseData['message'] ??
          'Failed to delete video');
    }
  }

  /// Posts a batch of reel view events.
  ///
  /// Telemetry: the server always answers 200, even for a malformed body, and
  /// a failure here must never surface to the user or interrupt scrolling.
  /// ReelViewTracker swallows whatever this throws.
  Future<void> recordReelViews(List<Map<String, dynamic>> batch) async {
    if (batch.isEmpty) return;
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/views');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'views': batch}),
    );
  }

  Future<Map<String, dynamic>> likeMoment(String momentId) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/like');

    debugPrint('❤️ [Provider] likeMoment: POST $url');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      debugPrint('❤️ [Provider] likeMoment: No token!');
      throw Exception('Authentication required. Please login again.');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('❤️ [Provider] likeMoment: status=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        return {
          'success': true,
          'likeCount': responseData['data']?['likeCount'] ?? 0,
          'isLiked': responseData['data']?['isLiked'] ?? true,
        };
      } else {
        throw Exception(responseData['error'] ?? 'Failed to like moment');
      }
    } else {
      final errorData = json.decode(response.body);
      debugPrint('❤️ [Provider] likeMoment ERROR: $errorData');
      throw Exception(errorData['error'] ??
                     errorData['message'] ??
                     'Failed to like moment');
    }
  }

  Future<Map<String, dynamic>> dislikeMoment(String momentId) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${Endpoints.momentsURL}/$momentId/dislike');

    debugPrint('💔 [Provider] dislikeMoment: POST $url');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      debugPrint('💔 [Provider] dislikeMoment: No token!');
      throw Exception('Authentication required. Please login again.');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('💔 [Provider] dislikeMoment: status=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        return {
          'success': true,
          'likeCount': responseData['data']?['likeCount'] ?? 0,
          'isLiked': responseData['data']?['isLiked'] ?? false,
        };
      } else {
        throw Exception(responseData['error'] ?? 'Failed to dislike moment');
      }
    } else {
      final errorData = json.decode(response.body);
      debugPrint('💔 [Provider] dislikeMoment ERROR: $errorData');
      throw Exception(errorData['error'] ??
                     errorData['message'] ??
                     'Failed to dislike moment');
    }
  }
}

// Updated provider with family for pagination
final momentsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, page) async {
  final service = MomentsService();
  return service.getMoments(page: page, limit: 10);
});

/// Stale-while-revalidate freshness marker for the moments feed — set to the
/// timestamp of the most recent successful fetch by any of the feed
/// providers below (`momentsFeedProvider`, `forYouMomentsProvider`,
/// `followingMomentsProvider`, `trendingMomentsProvider`). Read by
/// [refreshMomentsIfStale] to decide whether a silent revalidation is due.
final momentsFeedFreshnessProvider = StateProvider<DateTime?>((ref) => null);

/// Invalidates the moments feed providers when the last successful fetch is
/// older than [maxAge] (default 60s), so returning to the Moments tab (or a
/// periodic focus check) picks up new moments without a manual pull-to-
/// refresh. No polling loop — callers invoke this only on tab-return/focus.
///
/// Invisible to the user: the feed's `.when(...)` passes
/// `skipLoadingOnRefresh`/`skipLoadingOnReload` (see `moments_feed_widget.dart`)
/// so the invalidated providers refetch in place, keeping the previous data
/// on screen instead of flashing a loading spinner.
void refreshMomentsIfStale(WidgetRef ref,
    {Duration maxAge = const Duration(seconds: 60)}) {
  final last = ref.read(momentsFeedFreshnessProvider);
  if (last != null && DateTime.now().difference(last) < maxAge) return;
  // The paged tabs re-read page 1 in place and keep the pages scrolled
  // past, so the list never collapses under the reader.
  for (final provider in [
    forYouMomentsProvider,
    followingMomentsProvider,
    trendingMomentsProvider,
  ]) {
    if (ref.exists(provider)) ref.read(provider.notifier).softRefresh();
  }
  ref.invalidate(momentsFeedProvider);
}

/// Shared invalidation for the moment feed providers, called after a
/// like/react/comment/correction changes a moment's `likeCount`/
/// `commentCount` (see moments audit P1: this exact 4-line
/// `ref.invalidate(...)` block used to be copy-pasted at 7 call sites
/// across `moment_card.dart`, `single_moment.dart`, `comments_main.dart`,
/// and `create_comment.dart`).
///
/// Scoped to just the base `momentsFeedProvider` (the legacy combined feed)
/// plus whichever of the three tab feeds is *currently visible*
/// (`momentsFeedTabProvider` + `baseProviderFor`, both from
/// `moments_main.dart`), instead of unconditionally invalidating all four
/// feed providers (see moments audit I2). A single like tap previously
/// forced up to 4 full network refetches of up to 50 moments each,
/// regardless of which tab the user was even looking at; this cuts it to
/// (usually) 2, while still guaranteeing the tab the user can actually see
/// goes stale and refetches. The other, currently-hidden tabs are left
/// stale until the user switches to them (`refreshMomentsIfStale` then
/// covers that case on tab focus/return) or the 60s freshness window
/// elapses — an intentional tradeoff per the audit's suggested fix.
void invalidateMomentFeeds(WidgetRef ref) {
  ref.invalidate(momentsFeedProvider);
  final activeTab = ref.read(momentsFeedTabProvider);
  // Soft: page 1 is re-read, the pages loaded below it are kept (a like on
  // the 120th card must not snap the feed back to 50).
  ref.read(baseProviderFor(activeTab).notifier).softRefresh();
}

/// Provider that returns a single, denormalized list of moments that can be
/// further filtered on the client (used by the new HelloTalk-style feed).
final momentsFeedProvider = FutureProvider<List<Moments>>((ref) async {
  final service = ref.watch(momentsServiceProvider);
  final response = await service.getMoments(page: 1, limit: 50);
  final moments = response['moments'];

  // Stamp freshness after the fetch succeeds. Deferred to a microtask so we
  // never write to another provider synchronously from inside this
  // provider's build (the analyzer flags that as a
  // modifying-provider-during-build hazard even though this call happens
  // post-await).
  Future.microtask(() {
    ref.read(momentsFeedFreshnessProvider.notifier).state = DateTime.now();
  });

  if (moments is List<Moments>) {
    return moments;
  }

  if (moments is List) {
    return moments.cast<Moments>();
  }

  return <Moments>[];
});

/// Page size of the card feed tabs (the backend caps a page at 50).
const int kMomentsFeedPageSize = 50;

/// One page of a feed endpoint.
class MomentsFeedPage {
  final List<Moments> moments;
  final bool hasMore;
  const MomentsFeedPage(this.moments, {required this.hasMore});
}

typedef MomentsPageFetcher = Future<MomentsFeedPage> Function(
    Ref ref, int page);

/// [current] with its first page replaced by [freshFirstPage]: the items
/// that came from page 1 ([oldFirstPageCount] of them) are dropped, and the
/// pages below are kept minus anything page 1 now already shows.
List<Moments> mergeFreshFirstPage(
  List<Moments> freshFirstPage,
  List<Moments> current,
  int oldFirstPageCount,
) {
  final seen = freshFirstPage.map((m) => m.id).toSet();
  final tail = current
      .skip(oldFirstPageCount.clamp(0, current.length))
      .where((m) => seen.add(m.id));
  return [...freshFirstPage, ...tail];
}

/// [current] followed by the items of [nextPage] it does not already show
/// (a ranked or fast-moving feed can repeat an item across pages).
List<Moments> appendMomentsPage(List<Moments> current, List<Moments> nextPage) {
  final seen = current.map((m) => m.id).toSet();
  return [...current, ...nextPage.where((m) => seen.add(m.id))];
}

/// A card feed tab that pages: [build] loads page 1, [loadMore] appends the
/// next one as the reader nears the end (the feed used to load 50 and stop).
///
/// A plain `ref.invalidate` reloads from page 1 (pull-to-refresh, a new
/// post, sign-out); [softRefresh] re-reads page 1 in place and keeps the
/// pages already scrolled past.
class PagedMomentsFeedNotifier extends AsyncNotifier<List<Moments>> {
  PagedMomentsFeedNotifier(this._fetch);

  final MomentsPageFetcher _fetch;
  int _page = 1;
  int _firstPageCount = 0;
  bool _hasMore = false;
  bool _loadingMore = false;

  /// Whether another page may exist below the loaded ones.
  bool get hasMore => _hasMore;

  void _stampFreshness() {
    // Deferred so no other provider is written synchronously from a build.
    Future.microtask(() {
      ref.read(momentsFeedFreshnessProvider.notifier).state = DateTime.now();
    });
  }

  @override
  Future<List<Moments>> build() async {
    _page = 1;
    _hasMore = false;
    _loadingMore = false;
    final first = await _fetch(ref, 1);
    _firstPageCount = first.moments.length;
    _hasMore = first.hasMore && first.moments.isNotEmpty;
    _stampFreshness();
    return first.moments;
  }

  /// Appends the next page. No-op while one is loading, before the first
  /// page arrives, or once the end is reached. A failure keeps what is
  /// shown; the next scroll retries.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || state.isLoading || !_hasMore || _loadingMore) {
      return;
    }
    _loadingMore = true;
    try {
      final next = await _fetch(ref, _page + 1);
      // Reloaded meanwhile: this page belongs to the old list.
      if (!identical(state.valueOrNull, current)) return;
      _page += 1;
      _hasMore = next.hasMore && next.moments.isNotEmpty;
      state = AsyncData(appendMomentsPage(current, next.moments));
    } catch (_) {
      // Keep the loaded list; the next scroll to the end retries.
    } finally {
      _loadingMore = false;
    }
  }

  /// Re-reads page 1 and keeps the pages below it. Falls back to a full
  /// reload when only one page is loaded (the same result, simpler).
  Future<void> softRefresh() async {
    final current = state.valueOrNull;
    if (current == null || _page <= 1 || state.isLoading) {
      ref.invalidateSelf();
      return;
    }
    try {
      final first = await _fetch(ref, 1);
      if (!identical(state.valueOrNull, current)) return;
      state = AsyncData(
        mergeFreshFirstPage(first.moments, current, _firstPageCount),
      );
      _firstPageCount = first.moments.length;
      _stampFreshness();
    } catch (_) {
      // Keep what is shown.
    }
  }

  /// Replaces the moment [id] in the loaded pages (edit, save, like), so a
  /// card rebuilt after scrolling away shows the change.
  void patchMoment(String id, Moments Function(Moments) update) {
    final current = state.valueOrNull;
    if (current == null || !current.any((m) => m.id == id)) return;
    state = AsyncData([
      for (final m in current) m.id == id ? update(m) : m,
    ]);
  }

  /// Drops the moment [id] from the loaded pages (deleted).
  void removeMoment(String id) {
    final current = state.valueOrNull;
    if (current == null || !current.any((m) => m.id == id)) return;
    state = AsyncData([
      for (final m in current)
        if (m.id != id) m,
    ]);
  }
}

/// The paged card tabs. A change made on one card (or in the detail screen)
/// must reach every tab: they are separate lists of the same moments.
List<AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>>
    get _pagedCardFeeds => [
          forYouMomentsProvider,
          followingMomentsProvider,
          trendingMomentsProvider,
        ];

/// Applies [update] to moment [id] wherever it is loaded.
void patchMomentInFeeds(
  WidgetRef ref,
  String id,
  Moments Function(Moments) update,
) {
  for (final feed in _pagedCardFeeds) {
    if (ref.exists(feed)) ref.read(feed.notifier).patchMoment(id, update);
  }
}

/// Removes deleted moment [id] from every feed. The non-paged lists reload.
void removeMomentFromFeeds(WidgetRef ref, String id) {
  for (final feed in _pagedCardFeeds) {
    if (ref.exists(feed)) ref.read(feed.notifier).removeMoment(id);
  }
  ref.invalidate(momentsFeedProvider);
  ref.invalidate(momentsProvider(1));
}

/// A [MomentsPageFetcher] over `GET /moments` for [feed].
MomentsPageFetcher momentsFeedFetcher(String feed) => (ref, page) async {
      final service = ref.read(momentsServiceProvider);
      final response = await service.getMoments(
        page: page,
        limit: kMomentsFeedPageSize,
        feed: feed,
      );
      final raw = response['moments'];
      final moments = raw is List ? raw.cast<Moments>() : <Moments>[];
      final pagination = response['pagination'];
      final hasNext = pagination is Map ? pagination['hasNextPage'] : null;
      return MomentsFeedPage(
        moments,
        hasMore: hasNext is bool
            ? hasNext
            : moments.length >= kMomentsFeedPageSize,
      );
    };

/// "For You" feed tab — personalized feed filtered/sorted server-side by
/// the user's native/learning languages when eligible; falls back to the
/// default feed otherwise (see backend `feed=forYou` contract).
final forYouMomentsProvider =
    AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>(
  () => PagedMomentsFeedNotifier(momentsFeedFetcher('forYou')),
);

/// "Following" feed tab — moments authored by users the current user
/// follows; falls back to the default feed server-side when the user
/// follows no one (see backend `feed=following` contract).
final followingMomentsProvider =
    AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>(
  () => PagedMomentsFeedNotifier(momentsFeedFetcher('following')),
);

/// Deterministic prompt-of-the-day shown above the feed tabs.
final promptOfDayProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(momentsServiceProvider);
  return service.getPromptOfDay();
});

// Provider for user moments with family support
final userMomentsProvider = FutureProvider.family<List<Moments>, String>((ref, userId) async {
  final service = MomentsService();
  return service.getMomentsUser(id: userId, page: 1, limit: 50);
});

final momentsServiceProvider = Provider((ref) => MomentsService());

/// Clubs v2: a club's latest posts (first 20). Refreshed after posting.
final clubMomentsProvider =
    FutureProvider.autoDispose.family<List<Moments>, String>((ref, clubId) {
  return ref.read(momentsServiceProvider).getClubMoments(clubId);
});

/// Provider for explore/discover moments (backend explore endpoint)
final exploreMomentsProvider = FutureProvider<List<Moments>>((ref) async {
  final response = await MomentsServiceAPI.exploreMoments();
  if (response.success) {
    return response.data;
  }
  return <Moments>[];
});

/// Trending page size, as it was before trending paged (Explore shows it too).
const int kTrendingPageSize = 10;

/// Provider for trending moments (backend trending endpoint). Paged like the
/// other card tabs; the endpoint returns no pagination block, so a full page
/// means there may be another.
final trendingMomentsProvider =
    AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>(
  () => PagedMomentsFeedNotifier((ref, page) async {
    final response = await MomentsServiceAPI.getTrendingMoments(
      page: page,
      limit: kTrendingPageSize,
    );
    if (!response.success) {
      // Page 1 keeps its old behaviour (an empty list); a later page throws
      // so loadMore keeps what is shown and retries on the next scroll.
      if (page > 1) throw Exception(response.error ?? 'trending failed');
      return const MomentsFeedPage(<Moments>[], hasMore: false);
    }
    return MomentsFeedPage(
      response.data,
      hasMore: response.data.length >= kTrendingPageSize,
    );
  }),
);

/// The PUT /moments/:id body for [MomentsService.updateMoment]. See there
/// for which values are omitted and which are sent to clear a field.
Map<String, dynamic> momentUpdateBody({
  required String description,
  String? category,
  String? mood,
  List<String>? tags,
  String? backgroundColor,
  String? language,
  String? privacy,
  bool includeLocation = false,
  Map<String, dynamic>? location,
  bool includeScheduledFor = false,
  String? scheduledFor,
}) {
  final Map<String, dynamic> body = {
    'description': description.trim(),
  };

  if (category != null && category.isNotEmpty) {
    body['category'] = category;
  }
  // Empty mood / tags are sent on purpose: that is how they are cleared.
  if (mood != null) {
    body['mood'] = mood;
  }
  if (tags != null) {
    // Enforce max 5 tags
    body['tags'] = tags.take(5).toList();
  }
  if (includeLocation) {
    body['location'] = location;
  }
  if (includeScheduledFor) {
    body['scheduledFor'] = scheduledFor;
  }
  if (backgroundColor != null) {
    body['backgroundColor'] = backgroundColor;
  }
  if (language != null && language.isNotEmpty) {
    body['language'] = language;
  }
  if (privacy != null && privacy.isNotEmpty) {
    body['privacy'] = privacy;
  }
  return body;
}
