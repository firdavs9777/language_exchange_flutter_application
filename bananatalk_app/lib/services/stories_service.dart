import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

class StoriesService {
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

  // ==================== BASIC STORY OPERATIONS ====================

  /// Get stories feed
  static Future<StoriesResponse> getStoriesFeed({int page = 1, int limit = 20}) async {
    try {
      final token = await _getToken();
      final currentUserId = await _getCurrentUserId();
      
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storiesFeedURL}')
          .replace(queryParameters: {'page': '$page', 'limit': '$limit'});

      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📚 Stories Feed Response: success=${data['success']}, count=${data['count']}');
        
        if (data['success'] == true) {
          // API returns: { success: true, count: 3, data: [UserStories, UserStories] }
          final userStoriesList = data['data'] != null
              ? (data['data'] as List)
                  .map((d) => UserStories.fromJson(d, currentUserId ?? ''))
                  .toList()
              : <UserStories>[];
          
          print('📚 Parsed ${userStoriesList.length} user story groups');
          
          return StoriesResponse(
            success: true,
            count: data['count'] ?? userStoriesList.length,
            data: userStoriesList,
            message: data['message'],
          );
        }
        
        return StoriesResponse(
          success: false,
          error: data['error'] ?? data['message'] ?? 'Failed to load stories',
        );
      }
      return StoriesResponse(success: false, error: 'Failed to load stories');
    } catch (e) {
      print('Error in getStoriesFeed: $e');
      return StoriesResponse(success: false, error: e.toString());
    }
  }

  /// Get my stories
  static Future<StoriesResponse> getMyStories() async {
    try {
      final token = await _getToken();
      final currentUserId = await _getCurrentUserId();
      
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.myStoriesURL}');
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // API returns: { success: true, count: 2, data: [Story, Story] }
        // We need to convert to UserStories format
        if (data['success'] == true && data['data'] != null) {
          final stories = (data['data'] as List)
              .map((s) => Story.fromJson(s))
              .toList();
          
          // Group stories by user (should all be current user's stories)
          if (stories.isNotEmpty) {
            final firstStory = stories.first;
            final userStories = UserStories(
              user: firstStory.user,
              stories: stories,
              hasUnviewed: false, // My own stories are always viewed
              unviewedCount: 0,
              latestStory: stories.isNotEmpty ? stories.last : null,
            );
            
            return StoriesResponse(
              success: true,
              count: data['count'] ?? stories.length,
              data: [userStories],
              message: data['message'],
            );
          }
          
          // No stories - return empty but successful
          return StoriesResponse(
            success: true,
            count: 0,
            data: [],
            message: data['message'] ?? 'No active stories found',
          );
        }
        
        return StoriesResponse(
          success: false,
          error: data['error'] ?? data['message'] ?? 'Failed to load stories',
        );
      }
      return StoriesResponse(success: false, error: 'Failed to load stories');
    } catch (e) {
      print('Error in getMyStories: $e');
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
        return StoriesResponse.fromJson(data, currentUserId ?? '');
      } else if (response.statusCode == 403) {
        return StoriesResponse(success: true, blocked: true, message: 'Content not available');
      }
      return StoriesResponse(success: false, error: 'Failed to load stories');
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
      return SingleStoryResponse(success: false, error: 'Failed to load story');
    } catch (e) {
      return SingleStoryResponse(success: false, error: e.toString());
    }
  }

  /// Create story with all features
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
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.storiesURL}');

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add media files
      if (mediaFiles != null) {
        for (final file in mediaFiles) {
          final mimeType = _getMimeType(file.path);
          request.files.add(await http.MultipartFile.fromPath(
            'media', file.path, contentType: MediaType.parse(mimeType),
          ));
        }
      }

      // Add fields
      if (text != null) request.fields['text'] = text;
      if (backgroundColor != null) request.fields['backgroundColor'] = backgroundColor;
      if (textColor != null) request.fields['textColor'] = textColor;
      if (fontStyle != null) request.fields['fontStyle'] = fontStyle;
      request.fields['privacy'] = privacy.value;
      request.fields['allowReplies'] = allowReplies.toString();
      request.fields['allowSharing'] = allowSharing.toString();

      // Advanced features as JSON
      if (poll != null) {
        request.fields['poll'] = jsonEncode({
          'question': poll.question,
          'options': poll.options.map((o) => o.text).toList(),
          'isAnonymous': poll.isAnonymous,
        });
      }

      if (questionBox != null) {
        request.fields['questionBox'] = jsonEncode({'prompt': questionBox.prompt});
      }

      if (location != null) request.fields['location'] = jsonEncode(location.toJson());
      if (link != null) request.fields['link'] = jsonEncode(link.toJson());
      if (mentions != null && mentions.isNotEmpty) {
        request.fields['mentions'] = jsonEncode(mentions.map((m) => m.toJson()).toList());
      }
      if (hashtags != null && hashtags.isNotEmpty) {
        request.fields['hashtags'] = jsonEncode(hashtags);
      }
      if (music != null) request.fields['music'] = jsonEncode(music.toJson());

      print('📤 Sending story creation request...');
      print('📤 Media files: ${mediaFiles?.length ?? 0}');
      print('📤 Text mode: ${text != null}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Story creation response status: ${response.statusCode}');
      print('📡 Story creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Story created successfully');
        return SingleStoryResponse.fromJson(data);
      }

      // Parse error message from backend
      String errorMessage = 'Failed to create story';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to create story (${response.statusCode})';
        print('❌ Story creation failed: $errorMessage');
      } catch (parseError) {
        errorMessage = 'Failed to create story: Server error (${response.statusCode})';
        print('❌ Story creation failed with unparseable response: ${response.body}');
      }

      return SingleStoryResponse(success: false, error: errorMessage);
    } catch (e) {
      print('❌ Story creation exception: $e');
      return SingleStoryResponse(success: false, error: 'Network error: ${e.toString()}');
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
      return {'success': false, 'error': 'Failed to delete story'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mark story as viewed
  static Future<Map<String, dynamic>> viewStory({
    required String storyId,
    int? viewDuration,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.viewStoryURL(storyId)}');
      
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({if (viewDuration != null) 'viewDuration': viewDuration}),
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
      final response = await http.get(url, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'viewCount': data['data']?['viewCount'] ?? 0,
          'views': (data['data']?['views'] as List?)
              ?.map((v) => StoryView.fromJson(v)).toList() ?? [],
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
      final response = await http.get(url, headers: _getHeaders(token));

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
      
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'text': text, 'isAnonymous': isAnonymous}),
      );

      if (response.statusCode == 200) {
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
              ?.map((r) => StoryQuestionResponse.fromJson(r)).toList() ?? [],
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
      return ArchiveResponse(success: false, error: 'Failed to load archive');
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
      return HighlightsResponse(success: false, error: 'Failed to load highlights');
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
      return HighlightsResponse(success: false, error: 'Failed to load highlights');
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
