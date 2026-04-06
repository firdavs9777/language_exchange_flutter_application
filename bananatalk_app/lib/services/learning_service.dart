import 'dart:convert';
import 'dart:developer' as developer;
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
  static const String _tag = '🏆 LearningService';

  static void _log(String message) {
    developer.log(message, name: _tag);
    // ignore: avoid_print
    print('$_tag: $message');
  }
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
      return null;
    }

    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
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


      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data == null || data['data'] == null) {
          return {'success': true, 'data': null};
        }
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch progress'),
        };
      }
    } catch (e) {
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

  /// Get XP leaderboard with period filter
  static Future<Map<String, dynamic>> getXpLeaderboard({
    String period = 'all', // 'all', 'weekly', 'monthly'
    String? language,
    int limit = 50,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        'period': period,
        'limit': limit.toString(),
        if (language != null) 'language': language,
      };
      final url = Uri.parse('${Endpoints.baseURL}leaderboard/xp')
          .replace(queryParameters: queryParams);

      _log('📤 GET $url (period: $period)');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      _log('📥 Response Status: ${response.statusCode}');
      _log('📥 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final entries = (data?['data']?['entries'] as List?)?.length ?? 0;
        _log('✅ Success: Got $entries XP leaderboard entries');
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        final error = _getErrorMessage(data, 'Failed to fetch XP leaderboard');
        _log('❌ Error: $error');
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      _log('❌ Exception: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get streak leaderboard
  static Future<Map<String, dynamic>> getStreakLeaderboard({
    String type = 'current', // 'current', 'longest'
    int limit = 50,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        'type': type,
        'limit': limit.toString(),
      };
      final url = Uri.parse('${Endpoints.baseURL}leaderboard/streaks')
          .replace(queryParameters: queryParams);

      _log('📤 GET $url (type: $type)');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      _log('📥 Response Status: ${response.statusCode}');
      _log('📥 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final entries = (data?['data']?['entries'] as List?)?.length ?? 0;
        _log('✅ Success: Got $entries streak leaderboard entries');
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        final error = _getErrorMessage(data, 'Failed to fetch streak leaderboard');
        _log('❌ Error: $error');
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      _log('❌ Exception: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get friends leaderboard
  static Future<Map<String, dynamic>> getFriendsLeaderboard({
    int limit = 50,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      final url = Uri.parse('${Endpoints.baseURL}leaderboard/friends')
          .replace(queryParameters: queryParams);

      _log('📤 GET $url');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      _log('📥 Response Status: ${response.statusCode}');
      _log('📥 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final entries = (data?['data']?['entries'] as List?)?.length ?? 0;
        _log('✅ Success: Got $entries friends leaderboard entries');
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        final error = _getErrorMessage(data, 'Failed to fetch friends leaderboard');
        _log('❌ Error: $error');
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      _log('❌ Exception: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get current user's ranks
  static Future<Map<String, dynamic>> getMyRanks() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}leaderboard/me');

      _log('📤 GET $url');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      _log('📥 Response Status: ${response.statusCode}');
      _log('📥 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        _log('✅ Success: Got my ranks data');
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        final error = _getErrorMessage(data, 'Failed to fetch your ranks');
        _log('❌ Error: $error');
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      _log('❌ Exception: $e');
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


      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );


      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final vocabData = data?['data'];
        if (vocabData is Map) {
        }

        // Handle both array and object with items
        List<dynamic> items = [];
        if (vocabData is List) {
          items = vocabData;
        } else if (vocabData is Map) {
          // Try different possible keys
          if (vocabData['items'] != null) {
            items = vocabData['items'] as List;
          } else if (vocabData['words'] != null) {
            items = vocabData['words'] as List;
          } else if (vocabData['vocabulary'] != null) {
            items = vocabData['vocabulary'] as List;
          } else {
            // Maybe the data itself contains the items at a different structure
          }
        }

        return {
          'success': true,
          'data': items,
          'pagination': data?['pagination'] ?? vocabData?['pagination'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch vocabulary'),
        };
      }
    } catch (e) {
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


      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data?['data'],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to add vocabulary'),
        };
      }
    } catch (e) {
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


      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );


      // Check if response is HTML (likely 404 page)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
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
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== LESSONS ====================

  /// Get lessons - tries regular lessons first, then AI-generated
  static Future<Map<String, dynamic>> getLessons({
    String? language,
    String? sourceLanguage,
    String? level,
    String? category,
    int? unit,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        if (language != null) 'language': language,
        if (sourceLanguage != null) 'sourceLanguage': sourceLanguage,
        if (level != null) 'level': level,
        if (category != null) 'category': category,
        if (unit != null) 'unit': unit.toString(),
      };

      // Try regular lessons endpoint first
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.lessonsURL}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);


      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );


      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        var lessonsData = data?['data'];

        // Handle nested structure like { lessons: [...] }
        if (lessonsData is Map && lessonsData['lessons'] != null) {
          lessonsData = lessonsData['lessons'];
        }


        // If no lessons found, try AI-generated lessons
        if (lessonsData == null || (lessonsData is List && lessonsData.isEmpty)) {
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
        // Try AI-generated lessons as fallback
        return await getAIGeneratedLessons(
          language: language,
          level: level,
          category: category,
        );
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get AI-generated lessons
  static Future<Map<String, dynamic>> getAIGeneratedLessons({
    String? language,
    String? sourceLanguage,
    String? level,
    String? category,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        if (language != null) 'language': language,
        if (sourceLanguage != null) 'sourceLanguage': sourceLanguage,
        if (level != null) 'level': level,
        if (category != null) 'category': category,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final url = Uri.parse('${Endpoints.baseURL}lessons/ai-generated')
          .replace(queryParameters: queryParams);


      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );


      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        var lessonsData = data?['data'];

        // Handle nested structure like { lessons: [...] }
        if (lessonsData is Map && lessonsData['lessons'] != null) {
          lessonsData = lessonsData['lessons'];
        }


        return {
          'success': true,
          'data': lessonsData ?? [],
        };
      } else {
        return {
          'success': true,
          'data': [], // Return empty list, not error
        };
      }
    } catch (e) {
      return {'success': true, 'data': []}; // Return empty, not error
    }
  }

  /// Get recommended lessons
  static Future<Map<String, dynamic>> getRecommendedLessons({
    String? language,
    String? sourceLanguage,
    int limit = 5,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        if (language != null) 'language': language,
        if (sourceLanguage != null) 'sourceLanguage': sourceLanguage,
        'limit': limit.toString(),
      };
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.lessonsRecommendedURL}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);


      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );


      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final lessonsData = data?['data'];
        return {
          'success': true,
          'data': lessonsData ?? [],
        };
      } else {
        return {
          'success': false,
          'error': _getErrorMessage(data, 'Failed to fetch recommended lessons'),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get single lesson - tries regular lessons first, then AI-generated
  static Future<Map<String, dynamic>> getLesson(String lessonId) async {
    try {
      final token = await _getToken();

      // Try regular lessons endpoint first
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.lessonURL(lessonId)}');

      var response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      var data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data?['data'] != null) {
        return {
          'success': true,
          'data': data?['data'],
        };
      }

      // Try lessons/{id} endpoint
      final aiUrl = Uri.parse('${Endpoints.baseURL}${Endpoints.aiLessonURL(lessonId)}');

      response = await http.get(
        aiUrl,
        headers: _getHeaders(token),
      );


      data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data?['data'] != null) {
        return {
          'success': true,
          'data': data?['data'],
        };
      }

      // Try direct data structure (some APIs return lesson directly)
      if ((response.statusCode == 200 || response.statusCode == 201) && data != null && data['_id'] != null) {
        return {
          'success': true,
          'data': data,
        };
      }

      // Try lessons/ai-generated/{id} endpoint
      final aiGenUrl = Uri.parse('${Endpoints.baseURL}lessons/ai-generated/$lessonId');

      response = await http.get(
        aiGenUrl,
        headers: _getHeaders(token),
      );

      data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data?['data'] != null) {
        return {
          'success': true,
          'data': data?['data'],
        };
      }

      // Try direct data structure
      if ((response.statusCode == 200 || response.statusCode == 201) && data != null && data['_id'] != null) {
        return {
          'success': true,
          'data': data,
        };
      }

      // Last resort: fetch all AI-generated lessons and filter by ID
      final aiLessonsResult = await getAIGeneratedLessons(limit: 100);
      if (aiLessonsResult['success'] == true && aiLessonsResult['data'] != null) {
        final lessons = aiLessonsResult['data'] as List;
        for (var lesson in lessons) {
          final id = lesson['_id']?.toString() ?? lesson['id']?.toString();
          if (id == lessonId) {
            return {
              'success': true,
              'data': lesson,
            };
          }
        }
      }

      return {
        'success': false,
        'error': _getErrorMessage(data, 'Failed to fetch lesson'),
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Start lesson - tries multiple endpoints
  static Future<Map<String, dynamic>> startLesson(String lessonId) async {
    try {
      final token = await _getToken();

      // Try regular lessons endpoint first
      var url = Uri.parse('${Endpoints.baseURL}${Endpoints.lessonStartURL(lessonId)}');

      var response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      var data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data != null) {
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      }

      // Try AI-generated lessons start endpoint
      url = Uri.parse('${Endpoints.baseURL}lessons/$lessonId/start');

      response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data != null) {
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      }

      // Try lessons/ai-generated/{id}/start endpoint
      url = Uri.parse('${Endpoints.baseURL}lessons/ai-generated/$lessonId/start');

      response = await http.post(
        url,
        headers: _getHeaders(token),
      );

      data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data != null) {
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'error': _getErrorMessage(data, 'Failed to start lesson'),
      };
    } catch (e) {
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


      // Try regular lessons endpoint first
      var url = Uri.parse('${Endpoints.baseURL}${Endpoints.lessonSubmitURL(lessonId)}');

      var response = await http.post(
        url,
        headers: _getHeaders(token),
        body: body,
      );


      var data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        return {
          'success': true,
          'data': data['data'],
        };
      }

      // Try lessons/{id}/complete endpoint
      url = Uri.parse('${Endpoints.baseURL}lessons/$lessonId/complete');

      response = await http.post(
        url,
        headers: _getHeaders(token),
        body: body,
      );


      data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        return {
          'success': true,
          'data': data['data'],
        };
      }

      // Try lessons/{id}/submit endpoint
      url = Uri.parse('${Endpoints.baseURL}lessons/$lessonId/submit');

      response = await http.post(
        url,
        headers: _getHeaders(token),
        body: body,
      );


      data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        return {
          'success': true,
          'data': data['data'],
        };
      }

      // If all endpoints fail, return success with no XP (graceful degradation)
      return {
        'success': true,
        'data': {'xpEarned': 0},
      };
    } catch (e) {
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
