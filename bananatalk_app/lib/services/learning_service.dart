import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/models/learning/vocabulary_model.dart';
import 'package:bananatalk_app/models/learning/lesson_model.dart';
import 'package:bananatalk_app/models/learning/quiz_model.dart';

/// Learning Service
/// Handles all API calls for the learning feature
class LearningService {
  /// Get authentication token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Get standard headers for API requests
  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Safely decode JSON response
  static Map<String, dynamic>? _safeJsonDecode(String body) {
    // Check if response is HTML (likely 404 or error page)
    final trimmed = body.trim();
    if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html') || trimmed.startsWith('<HTML')) {
      debugPrint('⚠️ Received HTML response instead of JSON (endpoint may not exist)');
      return null;
    }

    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ JSON decode error: $e');
      debugPrint('   Response preview: ${body.length > 100 ? body.substring(0, 100) : body}');
      return null;
    }
  }

  /// Extract error message from response
  static String _getErrorMessage(Map<String, dynamic>? data, String defaultMsg) {
    if (data == null) return defaultMsg;
    return data['message']?.toString() ??
           data['error']?.toString() ??
           defaultMsg;
  }

  // ==================== PROGRESS ====================

  /// Get user's learning progress
  static Future<Map<String, dynamic>> getProgress() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.learningProgressURL}');

      debugPrint('📊 Fetching learning progress...');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data == null || data['data'] == null) {
          debugPrint('⚠️ No progress data returned');
          return {'success': true, 'data': null};
        }
        debugPrint('✅ Learning progress fetched successfully');
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        debugPrint('❌ Failed to fetch progress: ${response.statusCode}');
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch progress'),
        };
      }
    } catch (e) {
      debugPrint('❌ Error fetching progress: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get leaderboard
  static Future<Map<String, dynamic>> getLeaderboard({
    String type = 'weekly',
    String? language,
    int limit = 50,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = {
        'type': type,
        if (language != null) 'language': language,
        'limit': limit.toString(),
      };
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.learningLeaderboardURL}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch leaderboard'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get/Update daily goals
  static Future<Map<String, dynamic>> getDailyGoals() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.learningDailyGoalsURL}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch goals'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Update daily goals
  static Future<Map<String, dynamic>> updateDailyGoals({
    required int dailyGoal,
    required int weeklyGoal,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.learningDailyGoalsURL}');

      final response = await http.put(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'dailyGoal': dailyGoal,
          'weeklyGoal': weeklyGoal,
        }),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to update goals'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== VOCABULARY ====================

  /// Get vocabulary list
  static Future<Map<String, dynamic>> getVocabulary({
    String? language,
    String? srsLevel,
    String? search,
    String? tags,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        if (language != null) 'language': language,
        if (srsLevel != null) 'srsLevel': srsLevel,
        if (search != null) 'query': search,  // Backend expects 'query' not 'search'
        if (tags != null) 'tags': tags,
        'limit': limit.toString(),
        'page': ((offset ~/ limit) + 1).toString(),  // Backend expects 'page' not 'offset'
      };
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.vocabularyURL}')
          .replace(queryParameters: queryParams);

      debugPrint('📚 Fetching vocabulary from: $url');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      debugPrint('📚 Vocabulary response: ${response.statusCode}');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final vocabData = data?['data'];
        debugPrint('📚 Vocabulary data type: ${vocabData.runtimeType}');
        if (vocabData is Map) {
          debugPrint('📚 Vocabulary data keys: ${vocabData.keys.toList()}');
        }

        // Handle both array and object with items
        List<dynamic> items = [];
        if (vocabData is List) {
          items = vocabData;
          debugPrint('📚 Vocabulary items (direct list): ${items.length}');
        } else if (vocabData is Map) {
          // Try different possible keys
          if (vocabData['items'] != null) {
            items = vocabData['items'] as List;
            debugPrint('📚 Vocabulary items (from items): ${items.length}');
          } else if (vocabData['words'] != null) {
            items = vocabData['words'] as List;
            debugPrint('📚 Vocabulary items (from words): ${items.length}');
          } else if (vocabData['vocabulary'] != null) {
            items = vocabData['vocabulary'] as List;
            debugPrint('📚 Vocabulary items (from vocabulary): ${items.length}');
          } else {
            debugPrint('📚 Unknown vocabulary structure, trying to use data directly');
            // Maybe the data itself contains the items at a different structure
            debugPrint('📚 Full data: $vocabData');
          }
        }

        return {
          'success': true,
          'data': items,
          'pagination': data?['pagination'] ?? vocabData?['pagination'],
        };
      } else {
        debugPrint('❌ Vocabulary fetch failed: ${response.statusCode}');
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch vocabulary'),
        };
      }
    } catch (e) {
      debugPrint('❌ Vocabulary fetch error: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Add vocabulary word
  static Future<Map<String, dynamic>> addVocabulary({
    required String word,
    required String translation,
    required String language,
    String? pronunciation,
    String? partOfSpeech,
    String? exampleSentence,
    String? exampleTranslation,
    List<String>? tags,
    String? notes,
    VocabularyContext? context,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.vocabularyURL}');

      final body = {
        'word': word,
        'translation': translation,
        'language': language,
        if (pronunciation != null) 'pronunciation': pronunciation,
        if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
        if (exampleSentence != null) 'exampleSentence': exampleSentence,
        if (exampleTranslation != null) 'exampleTranslation': exampleTranslation,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (notes != null) 'notes': notes,
        if (context != null) 'context': context.toJson(),
      };

      debugPrint('📝 Adding vocabulary: $word');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Vocabulary added successfully');
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        debugPrint('❌ Failed to add vocabulary: ${response.statusCode}');
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to add vocabulary'),
        };
      }
    } catch (e) {
      debugPrint('❌ Error adding vocabulary: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Update vocabulary word
  static Future<Map<String, dynamic>> updateVocabulary({
    required String id,
    String? word,
    String? translation,
    String? pronunciation,
    String? partOfSpeech,
    String? exampleSentence,
    String? exampleTranslation,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.vocabularyItemURL(id)}');

      final body = <String, dynamic>{};
      if (word != null) body['word'] = word;
      if (translation != null) body['translation'] = translation;
      if (pronunciation != null) body['pronunciation'] = pronunciation;
      if (partOfSpeech != null) body['partOfSpeech'] = partOfSpeech;
      if (exampleSentence != null) body['exampleSentence'] = exampleSentence;
      if (exampleTranslation != null) body['exampleTranslation'] = exampleTranslation;
      if (tags != null) body['tags'] = tags;
      if (notes != null) body['notes'] = notes;

      final response = await http.put(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to update vocabulary'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Delete vocabulary word
  static Future<Map<String, dynamic>> deleteVocabulary(String id) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.vocabularyItemURL(id)}');

      final response = await http.delete(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = _safeJsonDecode(response.body);
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to delete vocabulary'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get words due for review
  static Future<Map<String, dynamic>> getDueReviews({
    String? language,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        if (language != null) 'language': language,
        'limit': limit.toString(),
      };
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.vocabularyReviewURL}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch due reviews'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Submit vocabulary review result
  static Future<Map<String, dynamic>> submitReview({
    required String vocabularyId,
    required bool correct,
    int? responseTime,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
          '${Endpoints.baseURL}${Endpoints.vocabularyItemReviewURL(vocabularyId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'correct': correct,
          if (responseTime != null) 'responseTime': responseTime,
        }),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to submit review'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get vocabulary statistics
  static Future<Map<String, dynamic>> getVocabularyStats({
    String? language,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        if (language != null) 'language': language,
      };
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.vocabularyStatsURL}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('📊 Fetching vocabulary stats from: $url');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      debugPrint('📊 Vocabulary stats response: ${response.statusCode}');

      // Check if response is HTML (likely 404 page)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        debugPrint('⚠️ Vocabulary stats endpoint returned HTML (endpoint may not exist)');
        return {'success': false, 'error': 'Endpoint not available'};
      }

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch vocabulary stats'),
        };
      }
    } catch (e) {
      debugPrint('❌ Error fetching vocabulary stats: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== LESSONS ====================

  /// Get lessons - tries regular lessons first, then AI-generated
  static Future<Map<String, dynamic>> getLessons({
    String? language,
    String? level,
    String? category,
    int? unit,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        if (language != null) 'language': language,
        if (level != null) 'level': level,
        if (category != null) 'category': category,
        if (unit != null) 'unit': unit.toString(),
      };

      // Try regular lessons endpoint first
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.lessonsURL}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('📚 Fetching lessons from: $url');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      debugPrint('📚 Lessons response status: ${response.statusCode}');
      debugPrint('📚 Lessons response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        var lessonsData = data?['data'];

        // Handle nested structure like { lessons: [...] }
        if (lessonsData is Map && lessonsData['lessons'] != null) {
          lessonsData = lessonsData['lessons'];
        }

        debugPrint('📚 Lessons data type: ${lessonsData?.runtimeType}');
        debugPrint('📚 Lessons count: ${lessonsData is List ? lessonsData.length : 'not a list'}');

        // If no lessons found, try AI-generated lessons
        if (lessonsData == null || (lessonsData is List && lessonsData.isEmpty)) {
          debugPrint('📚 No regular lessons, trying AI-generated...');
          return await getAIGeneratedLessons(
            language: language,
            level: level,
            category: category,
          );
        }

        return {
          'success': true,
          'data': lessonsData ?? [],
        };
      } else {
        debugPrint('❌ Failed to fetch lessons: ${response.statusCode}');
        // Try AI-generated lessons as fallback
        debugPrint('📚 Trying AI-generated lessons as fallback...');
        return await getAIGeneratedLessons(
          language: language,
          level: level,
          category: category,
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching lessons: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get AI-generated lessons
  static Future<Map<String, dynamic>> getAIGeneratedLessons({
    String? language,
    String? level,
    String? category,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        if (language != null) 'language': language,
        if (level != null) 'level': level,
        if (category != null) 'category': category,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final url = Uri.parse('${Endpoints.baseURL}lessons/ai-generated')
          .replace(queryParameters: queryParams);

      debugPrint('📚 Fetching AI-generated lessons from: $url');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      debugPrint('📚 AI lessons response status: ${response.statusCode}');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        var lessonsData = data?['data'];

        // Handle nested structure like { lessons: [...] }
        if (lessonsData is Map && lessonsData['lessons'] != null) {
          lessonsData = lessonsData['lessons'];
        }

        debugPrint('📚 AI lessons count: ${lessonsData is List ? lessonsData.length : 'not a list'}');

        return {
          'success': true,
          'data': lessonsData ?? [],
        };
      } else {
        debugPrint('❌ Failed to fetch AI lessons: ${response.statusCode}');
        return {
          'success': true,
          'data': [], // Return empty list, not error
        };
      }
    } catch (e) {
      debugPrint('❌ Error fetching AI lessons: $e');
      return {'success': true, 'data': []}; // Return empty, not error
    }
  }

  /// Get recommended lessons
  static Future<Map<String, dynamic>> getRecommendedLessons({
    String? language,
    int limit = 5,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        if (language != null) 'language': language,
        'limit': limit.toString(),
      };
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.lessonsRecommendedURL}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('📚 Fetching recommended lessons from: $url');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      debugPrint('📚 Recommended lessons response status: ${response.statusCode}');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final lessonsData = data?['data'];
        debugPrint('📚 Recommended lessons count: ${lessonsData is List ? lessonsData.length : 'not a list'}');
        return {
          'success': true,
          'data': lessonsData ?? [],
        };
      } else {
        debugPrint('❌ Failed to fetch recommended lessons: ${response.statusCode}');
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch recommended lessons'),
        };
      }
    } catch (e) {
      debugPrint('❌ Error fetching recommended lessons: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get single lesson - tries regular lessons first, then AI-generated
  static Future<Map<String, dynamic>> getLesson(String lessonId) async {
    try {
      final token = await _getToken();

      // Try regular lessons endpoint first
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.lessonURL(lessonId)}');
      debugPrint('📚 Fetching lesson from: $url');

      var response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      var data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data?['data'] != null) {
        debugPrint('✅ Lesson fetched from regular endpoint');
        return {
          'success': true,
          'data': data?['data'],
        };
      }

      // Try lessons/{id} endpoint
      debugPrint('📚 Trying lessons/{id} endpoint...');
      final aiUrl = Uri.parse('${Endpoints.baseURL}${Endpoints.aiLessonURL(lessonId)}');
      debugPrint('📚 Fetching lesson from: $aiUrl');

      response = await http.get(
        aiUrl,
        headers: _getHeaders(token),
      );

      debugPrint('📚 Response status: ${response.statusCode}');
      debugPrint('📚 Response body: ${response.body.length > 1000 ? response.body.substring(0, 1000) : response.body}');

      data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data?['data'] != null) {
        debugPrint('✅ Lesson fetched from lessons/{id} endpoint');
        debugPrint('📚 Lesson data keys: ${data?['data']?.keys?.toList()}');
        return {
          'success': true,
          'data': data?['data'],
        };
      }

      // Try direct data structure (some APIs return lesson directly)
      if ((response.statusCode == 200 || response.statusCode == 201) && data != null && data['_id'] != null) {
        debugPrint('✅ Lesson fetched directly (no data wrapper)');
        debugPrint('📚 Lesson data keys: ${data.keys.toList()}');
        return {
          'success': true,
          'data': data,
        };
      }

      // Try lessons/ai-generated/{id} endpoint
      debugPrint('📚 Trying lessons/ai-generated/{id} endpoint...');
      final aiGenUrl = Uri.parse('${Endpoints.baseURL}lessons/ai-generated/$lessonId');
      debugPrint('📚 Fetching lesson from: $aiGenUrl');

      response = await http.get(
        aiGenUrl,
        headers: _getHeaders(token),
      );

      data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data?['data'] != null) {
        debugPrint('✅ Lesson fetched from lessons/ai-generated/{id} endpoint');
        return {
          'success': true,
          'data': data?['data'],
        };
      }

      // Try direct data structure
      if ((response.statusCode == 200 || response.statusCode == 201) && data != null && data['_id'] != null) {
        debugPrint('✅ Lesson fetched directly from ai-generated endpoint');
        return {
          'success': true,
          'data': data,
        };
      }

      // Last resort: fetch all AI-generated lessons and filter by ID
      debugPrint('📚 Trying to find lesson in AI-generated list...');
      final aiLessonsResult = await getAIGeneratedLessons(limit: 100);
      if (aiLessonsResult['success'] == true && aiLessonsResult['data'] != null) {
        final lessons = aiLessonsResult['data'] as List;
        for (var lesson in lessons) {
          final id = lesson['_id']?.toString() ?? lesson['id']?.toString();
          if (id == lessonId) {
            debugPrint('✅ Found lesson in AI-generated list');
            return {
              'success': true,
              'data': lesson,
            };
          }
        }
      }

      debugPrint('❌ Failed to fetch lesson from all endpoints');
      return {
        'success': false,
        'error': _getErrorMessage(data, 'Failed to fetch lesson'),
      };
    } catch (e) {
      debugPrint('❌ Error fetching lesson: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Start lesson - tries multiple endpoints
  static Future<Map<String, dynamic>> startLesson(String lessonId) async {
    try {
      final token = await _getToken();

      // Try regular lessons endpoint first
      var url = Uri.parse('${Endpoints.baseURL}${Endpoints.lessonStartURL(lessonId)}');
      debugPrint('📚 Starting lesson from: $url');

      var response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      var data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data != null) {
        debugPrint('✅ Lesson started from regular endpoint');
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      }

      // Try AI-generated lessons start endpoint
      debugPrint('📚 Trying AI lessons start endpoint...');
      url = Uri.parse('${Endpoints.baseURL}lessons/$lessonId/start');
      debugPrint('📚 Starting lesson from: $url');

      response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data != null) {
        debugPrint('✅ Lesson started from AI lessons endpoint');
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      }

      // Try lessons/ai-generated/{id}/start endpoint
      debugPrint('📚 Trying lessons/ai-generated/{id}/start endpoint...');
      url = Uri.parse('${Endpoints.baseURL}lessons/ai-generated/$lessonId/start');
      debugPrint('📚 Starting lesson from: $url');

      response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data != null) {
        debugPrint('✅ Lesson started from ai-generated start endpoint');
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      }

      debugPrint('❌ Failed to start lesson from all endpoints');
      return {
        'success': false,
        'error': _getErrorMessage(data, 'Failed to start lesson'),
      };
    } catch (e) {
      debugPrint('❌ Error starting lesson: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Submit lesson - tries multiple endpoints for AI-generated lessons
  static Future<Map<String, dynamic>> submitLesson({
    required String lessonId,
    required List<LessonAnswer> answers,
    required int timeSpent,
  }) async {
    try {
      final token = await _getToken();
      final body = jsonEncode({
        'answers': answers.map((a) => a.toJson()).toList(),
        'timeSpent': timeSpent,
      });

      debugPrint('📝 Submitting lesson with body: $body');

      // Try regular lessons endpoint first
      var url = Uri.parse('${Endpoints.baseURL}${Endpoints.lessonSubmitURL(lessonId)}');
      debugPrint('📝 [1/3] Submitting lesson to: $url');

      var response = await http.post(
        url,
        headers: _getHeaders(token),
        body: body,
      );

      debugPrint('📝 [1/3] Response status: ${response.statusCode}');
      debugPrint('📝 [1/3] Response body preview: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      var data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        debugPrint('✅ Lesson submitted successfully via learning/lessons/{id}/submit');
        return {
          'success': true,
          'data': data['data'],
        };
      }

      // Try lessons/{id}/complete endpoint
      url = Uri.parse('${Endpoints.baseURL}lessons/$lessonId/complete');
      debugPrint('📝 [2/3] Trying lessons/{id}/complete endpoint: $url');

      response = await http.post(
        url,
        headers: _getHeaders(token),
        body: body,
      );

      debugPrint('📝 [2/3] Response status: ${response.statusCode}');
      debugPrint('📝 [2/3] Response body preview: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        debugPrint('✅ Lesson completed successfully via lessons/{id}/complete');
        return {
          'success': true,
          'data': data['data'],
        };
      }

      // Try lessons/{id}/submit endpoint
      url = Uri.parse('${Endpoints.baseURL}lessons/$lessonId/submit');
      debugPrint('📝 [3/3] Trying lessons/{id}/submit endpoint: $url');

      response = await http.post(
        url,
        headers: _getHeaders(token),
        body: body,
      );

      debugPrint('📝 [3/3] Response status: ${response.statusCode}');
      debugPrint('📝 [3/3] Response body preview: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        debugPrint('✅ Lesson submitted via lessons/{id}/submit');
        return {
          'success': true,
          'data': data['data'],
        };
      }

      // If all endpoints fail, return success with no XP (graceful degradation)
      debugPrint('⚠️ All lesson submit endpoints failed (statuses: 1st=${response.statusCode}), using local completion');
      return {
        'success': true,
        'data': {'xpEarned': 0},
      };
    } catch (e) {
      debugPrint('❌ Error submitting lesson: $e');
      // Return success anyway to not break the UI
      return {
        'success': true,
        'data': {'xpEarned': 0},
      };
    }
  }

  // ==================== QUIZZES ====================

  /// Get quizzes
  static Future<Map<String, dynamic>> getQuizzes({
    String? language,
    String? type,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        if (language != null) 'language': language,
        if (type != null) 'type': type,
      };
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.quizzesURL}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch quizzes'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get single quiz
  static Future<Map<String, dynamic>> getQuiz(String quizId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.quizURL(quizId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch quiz'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Submit quiz
  static Future<Map<String, dynamic>> submitQuiz({
    required String quizId,
    required List<QuizAnswer> answers,
    required int timeSpent,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.quizSubmitURL(quizId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'answers': answers.map((a) => a.toJson()).toList(),
          'timeSpent': timeSpent,
        }),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to submit quiz'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== ACHIEVEMENTS ====================

  /// Get achievements
  static Future<Map<String, dynamic>> getAchievements() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.achievementsURL}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch achievements'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== CHALLENGES ====================

  /// Get challenges
  static Future<Map<String, dynamic>> getChallenges() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.challengesURL}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data?['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch challenges'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
