import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// On a thrown failure (offline, timeout, bad JSON) `error` is the raw
/// exception text: show it through `friendlyErrorMessage`, not as-is.
/// A text story needs text or at least one overlay. An emoji-only story has
/// no text overlay, so the composer sends a single space (the backend only
/// asks for non-empty `text`) — refusing blank text alone blocked it.
bool textStoryHasContent(String text, List<Map<String, dynamic>>? overlays) =>
    text.trim().isNotEmpty || (overlays?.isNotEmpty ?? false);

class StoriesService {
  /// Test seam: replaces the HTTP client for the methods that use [_client].
  @visibleForTesting
  static http.Client? httpClient;

  static http.Client get _client => httpClient ?? _defaultClient;

  /// One client per request, closed when its response is read: exactly what
  /// the top-level `http.post` / `request.send()` calls did before the seam.
  static final http.Client _defaultClient = _PerRequestClient();

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== VIDEO CONFIG ====================

  /// Get video upload configuration (max duration, size, formats)
  static Future<Map<String, dynamic>> getVideoConfig() async {
    try {
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storiesVideoConfigURL}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      }
      return {'success': false, 'error': 'Failed to get video config'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== BASIC STORY OPERATIONS ====================

  /// Get stories feed. `followed` is `data`; `discover` is `[]` unless the
  /// server sent it.
  static Future<StoriesFeedResult> getStoriesFeed({int page = 1, int limit = 20}) async {
    try {
      final token = await _getToken();
      final currentUserId = await _getCurrentUserId();

      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storiesFeedURL}')
          .replace(queryParameters: {'page': '$page', 'limit': '$limit'});

      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // API returns: { success, count, data: [UserStories], discover?: [UserStories] }
          return StoriesFeedResult.fromJson(
            Map<String, dynamic>.from(data as Map),
            currentUserId ?? '',
          );
        }

        return StoriesFeedResult.failure(error: data['error'] ?? data['message']);
      }
      return StoriesFeedResult.failure();
    } catch (e) {
      return StoriesFeedResult.failure(error: e.toString());
    }
  }

  /// Get my stories
  static Future<StoriesResponse> getMyStories() async {
    try {
      final token = await _getToken();

      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.myStoriesURL}');
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Same flat-array shape as /stories/user/:id, so it shares that
        // parser. This wrap was duplicated inline here, which is exactly how
        // two copies of one rule drift apart.
        if (data['success'] == true && data['data'] != null) {
          final parsed = StoriesResponse.fromUserStoriesJson(data, '');
          if (parsed.data.isNotEmpty) return parsed;
          return StoriesResponse(
            success: true,
            count: 0,
            data: const [],
            message: data['message'] ?? 'No active stories found',
          );
        }
        
        return StoriesResponse(
          success: false,
          error: data['error'] ?? data['message'],
        );
      }
      return StoriesResponse(success: false, error: null);
    } catch (e) {
      return StoriesResponse(success: false, error: e.toString());
    }
  }

  /// Get user's stories (handles blocking)
  static Future<StoriesResponse> getUserStories({required String userId}) async {
    try {
      final token = await _getToken();
      final currentUserId = await _getCurrentUserId();
      
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.userStoriesURL(userId)}');
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['blocked'] == true) {
          return StoriesResponse(success: true, blocked: true, message: 'Content not available');
        }
        // This endpoint returns a FLAT array of stories; the feed endpoint
        // returns user GROUPS. Running this through the group parser turned
        // each story into a group holding zero stories, so the viewer opened
        // and rendered "No stories" for every user who had one.
        return StoriesResponse.fromUserStoriesJson(data, currentUserId ?? '');
      } else if (response.statusCode == 403) {
        return StoriesResponse(success: true, blocked: true, message: 'Content not available');
      }
      return StoriesResponse(success: false, error: null);
    } catch (e) {
      return StoriesResponse(success: false, error: e.toString());
    }
  }

  /// Get single story
  static Future<SingleStoryResponse> getStory({required String storyId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.singleStoryURL(storyId)}');
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return SingleStoryResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        return SingleStoryResponse(success: false, blocked: true, error: 'Content not available');
      }
      return SingleStoryResponse(success: false, error: null);
    } catch (e) {
      return SingleStoryResponse(success: false, error: e.toString());
    }
  }

  /// Create story - images and videos use different endpoints
  /// Video: POST /stories/video with field 'video'
  /// Image: POST /stories with field 'media'
  static Future<SingleStoryResponse> createStory({
    List<File>? mediaFiles,
    String? text,
    String? backgroundColor,
    String? textColor,
    String? fontStyle,
    StoryPrivacy privacy = StoryPrivacy.everyone,
    StoryPoll? poll,
    StoryQuestionBox? questionBox,
    StoryLocation? location,
    StoryLink? link,
    List<StoryMention>? mentions,
    List<String>? hashtags,
    StoryMusic? music,
    bool allowReplies = true,
    bool allowSharing = true,
    List<Map<String, dynamic>>? overlays,
    StoryCorrectionSticker? correctionSticker,
    StoryQuizSticker? quizSticker,
    StoryWordSticker? wordSticker,

    /// Sent as the `Idempotency-Key` header when non-null. Never logged.
    String? idempotencyKey,
  }) async {
    try {
      final token = await _getToken();

      // Validate - must have media files (images or video)
      if (mediaFiles == null || mediaFiles.isEmpty) {
        return SingleStoryResponse(
          success: false,
          failure: StoryPostFailure.noMedia,
        );
      }

      // Check if it's a video or image based on MIME type
      final firstFile = mediaFiles.first;
      final mimeType = _getMimeType(firstFile.path);
      final isVideo = mimeType.startsWith('video/');

      // Use different endpoint for video vs image
      final endpoint = isVideo ? Endpoints.storiesVideoURL : Endpoints.storiesURL;
      final url = Uri.parse('${Endpoints.baseURL}$endpoint');
      final fieldName = isVideo ? 'video' : 'media';


      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // For video stories, only one video file is allowed
      if (isVideo) {
        final file = mediaFiles.first;
        final fileSize = await file.length();


        // Validate video size (max 1GB)
        if (fileSize > 1024 * 1024 * 1024) {
          return SingleStoryResponse(
            success: false,
            failure: StoryPostFailure.videoTooLarge,
          );
        }

        request.files.add(await http.MultipartFile.fromPath(
          fieldName, file.path, contentType: MediaType.parse(mimeType),
        ));

        // Add optional fields for video story
        if (text != null && text.isNotEmpty) request.fields['text'] = text;
        if (backgroundColor != null) request.fields['backgroundColor'] = backgroundColor;
        if (textColor != null) request.fields['textColor'] = textColor;
        request.fields['privacy'] = _mapPrivacyToBackend(privacy);
        if (overlays != null && overlays.isNotEmpty) {
          request.fields['overlays'] = jsonEncode(overlays);
        }
        if (poll != null) {
          request.fields['poll'] = jsonEncode(poll.toJson());
        }
        if (questionBox != null) {
          request.fields['questionBox'] = jsonEncode(questionBox.toJson());
        }
        if (hashtags != null && hashtags.isNotEmpty) {
          request.fields['hashtags'] = jsonEncode(hashtags);
        }
        // The parameter existed and was never sent — the sticker could not
        // have worked even once. Server-side parseStoryLink stays
        // authoritative about what is acceptable.
        if (link != null) {
          request.fields['link'] = jsonEncode(link.toJson());
        }
        if (location != null) {
          request.fields['location'] = jsonEncode(location.toJson());
        }
        if (mentions != null && mentions.isNotEmpty) {
          request.fields['mentions'] = jsonEncode(_mentionsToBackendJson(mentions));
        }
      } else {
        // For image stories, multiple images allowed
        for (final file in mediaFiles) {
          final fileMimeType = _getMimeType(file.path);
          request.files.add(await http.MultipartFile.fromPath(
            fieldName, file.path, contentType: MediaType.parse(fileMimeType),
          ));
        }
        // These were only ever sent on the video branch, so a photo story
        // silently lost its caption and colours, kept the link sticker
        // client-side only, and — worst — ALWAYS posted with the server's
        // default privacy: a story set to close friends went out to friends.
        if (text != null && text.isNotEmpty) request.fields['text'] = text;
        if (backgroundColor != null) request.fields['backgroundColor'] = backgroundColor;
        if (textColor != null) request.fields['textColor'] = textColor;
        request.fields['privacy'] = _mapPrivacyToBackend(privacy);
        if (overlays != null && overlays.isNotEmpty) {
          request.fields['overlays'] = jsonEncode(overlays);
        }
        if (poll != null) {
          request.fields['poll'] = jsonEncode(poll.toJson());
        }
        if (questionBox != null) {
          request.fields['questionBox'] = jsonEncode(questionBox.toJson());
        }
        if (hashtags != null && hashtags.isNotEmpty) {
          request.fields['hashtags'] = jsonEncode(hashtags);
        }
        if (link != null) {
          request.fields['link'] = jsonEncode(link.toJson());
        }
        if (location != null) {
          request.fields['location'] = jsonEncode(location.toJson());
        }
        if (mentions != null && mentions.isNotEmpty) {
          request.fields['mentions'] = jsonEncode(_mentionsToBackendJson(mentions));
        }
      }
      // Accepted by both POST /stories and POST /stories/video
      // (parseStoryToggles) and previously never sent, so "replies off"
      // never stuck on a photo or video story. Music is not sent: the
      // server ignores it.
      if (fontStyle != null && fontStyle.isNotEmpty) {
        request.fields['fontStyle'] = fontStyle;
      }
      request.fields['allowReplies'] = allowReplies.toString();
      request.fields['allowSharing'] = allowSharing.toString();
      if (correctionSticker != null) {
        request.fields['correctionSticker'] =
            jsonEncode(correctionSticker.toCreateJson());
      }
      if (quizSticker != null) {
        request.fields['quizSticker'] = jsonEncode(quizSticker.toCreateJson());
      }
      if (wordSticker != null) {
        request.fields['wordSticker'] = jsonEncode(wordSticker.toCreateJson());
      }
      if (idempotencyKey != null) {
        request.headers['Idempotency-Key'] = idempotencyKey;
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SingleStoryResponse.fromJson(data);
      }

      return _createFailure(response, 'createStory');
    } catch (e) {
      debugPrint('StoriesService.createStory failed: $e');
      return SingleStoryResponse(success: false, error: e.toString());
    }
  }

  /// Maps a refused story create to its outcome. The two 409s differ by
  /// message: "already in progress" is retry-later, "already posted" is
  /// terminal. Anything unrecognised stays a generic failure.
  static SingleStoryResponse _createFailure(
      http.Response response, String call) {
    final error = _serverErrorOf(response, call);
    final status = response.statusCode;
    StoryPostFailure? failure;
    if (status == 409) {
      final message = (error ?? '').toLowerCase();
      // Server message "Story upload already in progress" (retry later).
      if (message.contains('already in progress')) {
        failure = StoryPostFailure.inProgress;
      // Server message "Story was already posted" (terminal).
      } else if (message.contains('already posted')) {
        failure = StoryPostFailure.alreadyPosted;
      }
    } else if (status == 503) {
      failure = StoryPostFailure.tryAgain;
    }
    return SingleStoryResponse(
      success: false,
      error: error,
      failure: failure,
      limitReached: status == 429,
    );
  }

  /// Backend's `parseMentions` expects the client-declared, flat shape
  /// `[{ user, x, y }]` (it looks up each user server-side and stamps in
  /// `username` itself) — NOT [StoryMention.toJson]'s persisted shape
  /// (`{ user, username, position: { x, y } }`), which is what a story
  /// looks like *after* the server has already processed it.
  static List<Map<String, dynamic>> _mentionsToBackendJson(List<StoryMention> mentions) {
    return mentions
        .map((m) => {'user': m.userId, 'x': m.x, 'y': m.y})
        .toList();
  }

  /// Map StoryPrivacy enum to backend expected values
  static String _mapPrivacyToBackend(StoryPrivacy privacy) {
    switch (privacy) {
      case StoryPrivacy.everyone:
        return 'public';
      case StoryPrivacy.friends:
        return 'friends';
      case StoryPrivacy.closeFriends:
        return 'close_friends';
    }
  }

  /// Create a text-only story (no media required)
  static Future<SingleStoryResponse> createTextStory({
    required String text,
    required String backgroundColor,
    String textColor = '#FFFFFF',
    String fontStyle = 'normal',
    StoryPrivacy privacy = StoryPrivacy.everyone,
    bool allowReplies = true,
    bool allowSharing = true,
    List<Map<String, dynamic>>? overlays,
    List<String>? hashtags,
    StoryLocation? location,
    List<StoryMention>? mentions,
    /// A text story carries a link just as usefully as a photo one.
    StoryLink? link,
    /// Poll or question sticker (mutually exclusive, as on media stories).
    StoryPoll? poll,
    StoryQuestionBox? questionBox,
    StoryCorrectionSticker? correctionSticker,
    StoryQuizSticker? quizSticker,
    StoryWordSticker? wordSticker,

    /// Sent as the `Idempotency-Key` header when non-null. Never logged.
    String? idempotencyKey,
  }) async {
    try {
      final token = await _getToken();

      if (!textStoryHasContent(text, overlays)) {
        return SingleStoryResponse(
          success: false,
          failure: StoryPostFailure.noText,
        );
      }

      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storiesURL}');


      final body = <String, dynamic>{
        'text': text.trim(),
        'backgroundColor': backgroundColor,
        'textColor': textColor,
        'fontStyle': fontStyle,
        'mediaType': 'text',
        'privacy': _mapPrivacyToBackend(privacy),
        'allowReplies': allowReplies,
        'allowSharing': allowSharing,
        if (overlays != null && overlays.isNotEmpty) 'overlays': overlays,
        if (hashtags != null && hashtags.isNotEmpty) 'hashtags': hashtags,
        if (link != null) 'link': link.toJson(),
        if (location != null) 'location': location.toJson(),
        if (mentions != null && mentions.isNotEmpty)
          'mentions': _mentionsToBackendJson(mentions),
        if (poll != null) 'poll': poll.toJson(),
        if (questionBox != null) 'questionBox': questionBox.toJson(),
        if (correctionSticker != null)
          'correctionSticker': correctionSticker.toCreateJson(),
        if (quizSticker != null) 'quizSticker': quizSticker.toCreateJson(),
        if (wordSticker != null) 'wordSticker': wordSticker.toCreateJson(),
      };

      final response = await _client.post(
        url,
        headers: {
          ..._getHeaders(token),
          if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
        },
        body: jsonEncode(body),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SingleStoryResponse.fromJson(data);
      }

      return _createFailure(response, 'createTextStory');
    } catch (e) {
      debugPrint('StoriesService.createTextStory failed: $e');
      return SingleStoryResponse(success: false, error: e.toString());
    }
  }

  /// Delete story
  static Future<Map<String, dynamic>> deleteStory({required String storyId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.singleStoryURL(storyId)}');
      final response = await http.delete(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': serverErrorOf(response)};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mark story as viewed
  static Future<Map<String, dynamic>> viewStory({
    required String storyId,
    int? viewDuration,

    /// Only sent when true: the viewer reached the end of the story.
    bool completed = false,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.viewStoryURL(storyId)}');
      
      final response = await _client.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          if (viewDuration != null) 'viewDuration': viewDuration,
          if (completed) 'completed': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'viewCount': data['viewCount'] ?? 0};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get story viewers (owner only)
  static Future<Map<String, dynamic>> getStoryViewers({required String storyId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyViewsURL(storyId)}');
      final response = await _client.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'viewCount': data['data']?['viewCount'] ?? 0,
          'views': (data['data']?['views'] as List?)
              ?.map((v) => StoryView.fromJson(v)).toList() ?? [],
          'summary': StoryViewsSummary.fromJsonOrNull(data['data']?['summary']),
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== REACTIONS ====================

  /// React to story
  static Future<Map<String, dynamic>> reactToStory({
    required String storyId,
    required String emoji,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyReactURL(storyId)}');
      
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'emoji': emoji}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reactionCount': data['data']?['reactionCount'] ?? 0,
          'userReaction': data['data']?['userReaction'],
        };
      } else if (response.statusCode == 403) {
        return {'success': false, 'blocked': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Remove reaction
  static Future<Map<String, dynamic>> removeReaction({required String storyId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyReactURL(storyId)}');
      final response = await http.delete(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'reactionCount': data['data']?['reactionCount'] ?? 0};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get story reactions (owner only)
  static Future<Map<String, dynamic>> getStoryReactions({required String storyId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyReactionsURL(storyId)}');
      final response = await _client.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reactionCount': data['data']?['reactionCount'] ?? 0,
          'reactions': (data['data']?['reactions'] as List?)
              ?.map((r) => StoryReaction.fromJson(r)).toList() ?? [],
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== REPLIES ====================

  /// Reply to story
  static Future<Map<String, dynamic>> replyToStory({
    required String storyId,
    required String message,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyReplyURL(storyId)}');
      
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['data']?['message'], 'replyCount': data['data']?['replyCount']};
      } else if (response.statusCode == 403) {
        return {'success': false, 'blocked': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== POLLS ====================

  /// Vote on story poll
  static Future<Map<String, dynamic>> votePoll({
    required String storyId,
    required int optionIndex,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyPollVoteURL(storyId)}');
      
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'optionIndex': optionIndex}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'poll': data['data']?['poll'] != null 
              ? StoryPoll.fromJson(data['data']['poll']) 
              : null,
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== LEARNING STICKERS ====================

  /// Send a correction for a story's correction sticker. It reaches the
  /// author as a chat message, so the chat's message limit applies.
  static Future<CorrectionResult> submitCorrection({
    required String storyId,
    required String text,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyCorrectionURL(storyId)}');
      final response = await _client.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'text': text}),
      );
      final message = serverErrorOf(response);
      switch (response.statusCode) {
        case 201:
          // A sent correction is never reported as failed, even when the
          // body is unreadable: the UI would invite a second send.
          int? count;
          try {
            final data = (jsonDecode(response.body) as Map?)?['data'];
            final raw = data is Map ? data['correctionCount'] : null;
            count = raw is num ? raw.toInt() : null;
          } catch (_) {}
          return CorrectionResult(
            outcome: CorrectionOutcome.success,
            correctionCount: count,
          );
        case 409:
          return CorrectionResult(
              outcome: CorrectionOutcome.alreadyCorrected, message: message);
        case 403:
          return CorrectionResult(
            outcome: _correction403Outcome(response, message),
            message: message,
          );
        case 429:
          return CorrectionResult(
              outcome: CorrectionOutcome.limitReached, message: message);
        case 400:
          return CorrectionResult(
              outcome: CorrectionOutcome.invalid, message: message);
        case 404:
          return CorrectionResult(
              outcome: CorrectionOutcome.unavailable, message: message);
      }
      return CorrectionResult(
          outcome: CorrectionOutcome.failure, message: message);
    } catch (e) {
      debugPrint('StoriesService.submitCorrection failed: $e');
      return CorrectionResult(
          outcome: CorrectionOutcome.failure, message: e.toString());
    }
  }

  /// The correction endpoint answers several different refusals with 403.
  static CorrectionOutcome _correction403Outcome(
      http.Response response, String? message) {
    String? code;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['code'] is String) code = body['code'];
    } catch (_) {}
    // Server body `code: CONVERSATION_START_LIMIT` (the chat path's cap on
    // starting conversations): a product limit, not a block.
    if (code == 'CONVERSATION_START_LIMIT') return CorrectionOutcome.limitReached;
    final text = (message ?? '').toLowerCase();
    // Server message "This content is not available" (viewer may not see it).
    if (text.contains('not available')) return CorrectionOutcome.unavailable;
    // Server message "Replies are disabled for this story".
    if (text.contains('replies are disabled')) {
      return CorrectionOutcome.repliesDisabled;
    }
    // "Cannot reply to this story" (a block either way) and anything else.
    return CorrectionOutcome.blocked;
  }

  /// Answer a story quiz. A repeat returns the first answer's result.
  static Future<QuizAnswerResult> answerQuiz({
    required String storyId,
    required int optionIndex,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyQuizAnswerURL(storyId)}');
      final response = await _client.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'optionIndex': optionIndex}),
      );
      if (response.statusCode == 200) {
        Object? data;
        try {
          data = (jsonDecode(response.body) as Map?)?['data'];
        } catch (_) {}
        final quiz = data is Map
            ? StoryQuizSticker.fromJsonOrNull(data['quiz'])
            : null;
        // The answer was recorded even when the body is unreadable: success
        // without a quiz, so the viewer keeps the pick instead of failing.
        return QuizAnswerResult(
          success: true,
          quiz: quiz,
          isCorrect: data is Map && data['isCorrect'] == true,
        );
      }
      return QuizAnswerResult(
          success: false, error: serverErrorOf(response));
    } catch (e) {
      debugPrint('StoriesService.answerQuiz failed: $e');
      return QuizAnswerResult(success: false, error: e.toString());
    }
  }

  // ==================== QUESTION BOX ====================

  /// Answer question on story
  static Future<Map<String, dynamic>> answerQuestion({
    required String storyId,
    required String text,
    bool isAnonymous = false,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyQuestionAnswerURL(storyId)}');
      
      final response = await _client.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'text': text, 'isAnonymous': isAnonymous}),
      );

      // The server answers 201 for a created answer.
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get question responses (owner only)
  static Future<Map<String, dynamic>> getQuestionResponses({required String storyId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyQuestionResponsesURL(storyId)}');
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'prompt': data['data']?['prompt'],
          'responses': (data['data']?['responses'] as List?)
                  ?.whereType<Map>()
                  .map((r) => StoryQuestionResponse.fromJson(
                        Map<String, dynamic>.from(r),
                      ))
                  .toList() ??
              <StoryQuestionResponse>[],
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== SHARING ====================

  /// Share story
  static Future<Map<String, dynamic>> shareStory({
    required String storyId,
    required String sharedTo, // 'dm', 'story', 'external'
    String? receiverId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyShareURL(storyId)}');
      
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'sharedTo': sharedTo,
          if (receiverId != null) 'receiverId': receiverId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'shareCount': data['data']?['shareCount'] ?? 0};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== ARCHIVE ====================

  /// Get archived stories
  static Future<ArchiveResponse> getArchivedStories({int page = 1, int limit = 20}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyArchiveURL}')
          .replace(queryParameters: {'page': '$page', 'limit': '$limit'});
      
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return ArchiveResponse.fromJson(jsonDecode(response.body));
      }
      return ArchiveResponse(success: false, error: null);
    } catch (e) {
      return ArchiveResponse(success: false, error: e.toString());
    }
  }

  /// Archive story manually
  static Future<Map<String, dynamic>> archiveStory({required String storyId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.archiveStoryURL(storyId)}');
      final response = await http.post(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== HIGHLIGHTS ====================

  /// Get my highlights
  static Future<HighlightsResponse> getMyHighlights() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyHighlightsURL}');
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return HighlightsResponse.fromJson(jsonDecode(response.body));
      }
      return HighlightsResponse(success: false, error: null);
    } catch (e) {
      return HighlightsResponse(success: false, error: e.toString());
    }
  }

  /// Get user's highlights
  static Future<HighlightsResponse> getUserHighlights({required String userId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.highlightUserURL(userId)}');
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return HighlightsResponse.fromJson(jsonDecode(response.body));
      }
      return HighlightsResponse(success: false, error: null);
    } catch (e) {
      return HighlightsResponse(success: false, error: e.toString());
    }
  }

  /// Create highlight
  static Future<Map<String, dynamic>> createHighlight({
    required String title,
    String? storyId,
    String? coverImage,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storyHighlightsURL}');
      
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'title': title,
          if (storyId != null) 'storyId': storyId,
          if (coverImage != null) 'coverImage': coverImage,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] != null ? StoryHighlight.fromJson(data['data']) : null,
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update highlight
  static Future<Map<String, dynamic>> updateHighlight({
    required String highlightId,
    String? title,
    String? coverImage,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.singleHighlightURL(highlightId)}');
      
      final response = await http.put(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          if (title != null) 'title': title,
          if (coverImage != null) 'coverImage': coverImage,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete highlight
  static Future<Map<String, dynamic>> deleteHighlight({required String highlightId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.singleHighlightURL(highlightId)}');
      final response = await http.delete(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Add story to highlight
  static Future<Map<String, dynamic>> addToHighlight({
    required String highlightId,
    required String storyId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.highlightStoriesURL(highlightId)}');
      
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'storyId': storyId}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Remove story from highlight
  static Future<Map<String, dynamic>> removeFromHighlight({
    required String highlightId,
    required String storyId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.removeFromHighlightURL(highlightId, storyId)}');
      final response = await http.delete(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== CLOSE FRIENDS ====================

  /// Get close friends list
  static Future<Map<String, dynamic>> getCloseFriends() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.closeFriendsURL}');
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'count': data['count'] ?? 0,
          'data': (data['data'] as List?)
              ?.map((u) => Community.fromJson(u)).toList() ?? [],
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Add to close friends
  static Future<Map<String, dynamic>> addCloseFriend({required String userId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.closeFriendURL(userId)}');
      final response = await http.post(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Remove from close friends
  static Future<Map<String, dynamic>> removeCloseFriend({required String userId}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.closeFriendURL(userId)}');
      final response = await http.delete(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== HELPERS ====================

  /// The backend's own sentence from a failed response, or null.
  ///
  /// There used to be an English fallback here ("Failed to create story
  /// (500)"), which the screen showed as-is; with null the screen shows its
  /// localized "couldn't post story" instead.
  @visibleForTesting
  static String? serverErrorOf(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is! Map) return null;
      final message = body['message'] ?? body['error'];
      return message is String && message.trim().isNotEmpty ? message : null;
    } catch (_) {
      return null;
    }
  }

  static String? _serverErrorOf(http.Response response, String call) {
    final message = serverErrorOf(response);
    if (message == null) {
      debugPrint('StoriesService.$call failed: HTTP ${response.statusCode}');
    }
    return message;
  }

  static String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }
}

/// Sends every request through `BaseRequest.send()`, which makes a fresh
/// client and closes it once the response stream is done.
class _PerRequestClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      request.send();
}
