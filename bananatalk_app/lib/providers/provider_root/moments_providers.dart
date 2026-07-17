import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/moments_service.dart' as api;

typedef MomentsServiceAPI = api.MomentsService;

class MomentsService {
  int count = 0;

  // Updated getMoments with pagination support
  Future<Map<String, dynamic>> getMoments(
      {int page = 1, int limit = 10, String? feed}) async {
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

    final url = '${Endpoints.baseURL}${Endpoints.momentsURL}/user/$id?page=$page&limit=$limit';
    final response = await http.get(Uri.parse(url));

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
    final response = await http
        .get(Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/$id'));
    
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

  Future<Moments> updateMoment({
    required String id,
    required String description,
    String? category,
    String? mood,
    List<String>? tags,
    List<String>? images,
    String? backgroundColor,
    String? language,
    String? privacy,
  }) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.momentsURL}/$id');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }

    // Build the request body
    final Map<String, dynamic> body = {
      'description': description.trim(),
    };

    // Add optional fields only if they have values
    if (category != null && category.isNotEmpty) {
      body['category'] = category;
    }
    if (mood != null && mood.isNotEmpty) {
      body['mood'] = mood;
    }
    if (tags != null && tags.isNotEmpty) {
      // Enforce max 5 tags
      body['tags'] = tags.take(5).toList();
    }
    if (images != null) {
      // Send updated images array (filenames only)
      body['images'] = images;
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
      // Check file size (10MB max)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image size exceeds 10MB limit: ${imageFile.path}');
      }

      // Determine content type from file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      String? mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          throw Exception('Unsupported image format: $extension. Supported: JPEG, PNG, GIF, WEBP');
      }

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
    } on FormatException catch (e) {
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
  ref.invalidate(forYouMomentsProvider);
  ref.invalidate(followingMomentsProvider);
  ref.invalidate(trendingMomentsProvider);
  ref.invalidate(momentsFeedProvider);
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

/// "For You" feed tab — personalized feed filtered/sorted server-side by
/// the user's native/learning languages when eligible; falls back to the
/// default feed otherwise (see backend `feed=forYou` contract).
final forYouMomentsProvider = FutureProvider<List<Moments>>((ref) async {
  final service = ref.watch(momentsServiceProvider);
  final response = await service.getMoments(page: 1, limit: 50, feed: 'forYou');
  final moments = response['moments'];

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

/// "Following" feed tab — moments authored by users the current user
/// follows; falls back to the default feed server-side when the user
/// follows no one (see backend `feed=following` contract).
final followingMomentsProvider = FutureProvider<List<Moments>>((ref) async {
  final service = ref.watch(momentsServiceProvider);
  final response =
      await service.getMoments(page: 1, limit: 50, feed: 'following');
  final moments = response['moments'];

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

/// Provider for explore/discover moments (backend explore endpoint)
final exploreMomentsProvider = FutureProvider<List<Moments>>((ref) async {
  final response = await MomentsServiceAPI.exploreMoments();
  if (response.success) {
    return response.data;
  }
  return <Moments>[];
});

/// Provider for trending moments (backend trending endpoint)
final trendingMomentsProvider = FutureProvider<List<Moments>>((ref) async {
  final response = await MomentsServiceAPI.getTrendingMoments();

  Future.microtask(() {
    ref.read(momentsFeedFreshnessProvider.notifier).state = DateTime.now();
  });

  if (response.success) {
    return response.data;
  }
  return <Moments>[];
});
