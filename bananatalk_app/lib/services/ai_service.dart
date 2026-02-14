import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/models/ai/ai_conversation_model.dart';
import 'package:bananatalk_app/models/ai/grammar_feedback_model.dart';
import 'package:bananatalk_app/models/ai/speech_model.dart';
import 'package:bananatalk_app/models/ai/translation_model.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/models/ai/lesson_assistant_model.dart';
import 'package:bananatalk_app/models/ai/lesson_builder_model.dart';

/// AI Service for all AI-powered features
class AIService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

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
      debugPrint('⚠️ AI Service: Received HTML response instead of JSON');
      return null;
    }

    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ AI Service JSON decode error: $e');
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

  // ============================================
  // AI CONVERSATION PARTNER
  // ============================================

  /// Start a new AI conversation
  static Future<Map<String, dynamic>> startConversation(
      StartConversationRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}ai-conversation/start'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      debugPrint('🚀 Start conversation response: ${response.body}');

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = data['data'] ?? data;
        if (responseData == null) {
          return {'success': false, 'message': 'No conversation data returned'};
        }

        // API may return: { conversation: {...}, initialMessage: {...} }
        // Or directly: { _id: ..., messages: [...], ... }
        Map<String, dynamic>? convJson;
        dynamic initialMsgJson;

        if (responseData['conversation'] != null && responseData['conversation'] is Map) {
          convJson = Map<String, dynamic>.from(responseData['conversation']);
          initialMsgJson = responseData['initialMessage'];
        } else if (responseData['_id'] != null || responseData['id'] != null) {
          // Direct conversation format
          convJson = Map<String, dynamic>.from(responseData);
        }

        if (convJson == null) {
          debugPrint('❌ No conversation found in response: $responseData');
          return {'success': false, 'message': 'No conversation data returned'};
        }

        // Build conversation data with initial message included
        final convData = Map<String, dynamic>.from(convJson);
        if (initialMsgJson != null && convData['messages'] == null) {
          convData['messages'] = [initialMsgJson];
        }

        debugPrint('📝 Parsed conversation with ${convData['messages']?.length ?? 0} messages');

        return {
          'success': true,
          'conversation': AIConversation.fromJson(convData),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to start conversation')};
    } catch (e) {
      debugPrint('❌ Start conversation error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Send a message in conversation
  static Future<Map<String, dynamic>> sendMessage(
      String conversationId, SendMessageRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}ai-conversation/$conversationId/message'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      debugPrint('📨 Send message response: ${response.body}');

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // API may return data directly or nested in 'data' field
        final msgData = data['data'] ?? data;
        if (msgData == null) {
          return {'success': false, 'message': 'No message data returned'};
        }

        // Parse AI response - could be in 'aiResponse', 'response', 'message', or direct
        AIMessage? aiMessage;
        Map<String, dynamic>? aiResponseData;

        if (msgData['aiResponse'] != null) {
          aiResponseData = msgData['aiResponse'] is Map
              ? Map<String, dynamic>.from(msgData['aiResponse'])
              : null;
        } else if (msgData['response'] != null) {
          aiResponseData = msgData['response'] is Map
              ? Map<String, dynamic>.from(msgData['response'])
              : null;
        } else if (msgData['message'] != null && msgData['message'] is Map) {
          aiResponseData = Map<String, dynamic>.from(msgData['message']);
        } else if (msgData['content'] != null) {
          // Direct message format
          aiResponseData = Map<String, dynamic>.from(msgData);
        }

        if (aiResponseData != null) {
          aiMessage = AIMessage.fromJson(aiResponseData);
        }

        // Parse user message feedback if available
        MessageFeedback? userFeedback;
        if (msgData['feedback'] != null && msgData['feedback'] is Map) {
          userFeedback = MessageFeedback.fromJson(
            Map<String, dynamic>.from(msgData['feedback']),
          );
        } else if (msgData['userFeedback'] != null && msgData['userFeedback'] is Map) {
          userFeedback = MessageFeedback.fromJson(
            Map<String, dynamic>.from(msgData['userFeedback']),
          );
        }

        return {
          'success': true,
          'data': msgData,
          'message': aiMessage,
          'feedback': userFeedback,
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to send message')};
    } catch (e) {
      debugPrint('❌ Send message error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// End conversation and get summary
  static Future<Map<String, dynamic>> endConversation(String conversationId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}ai-conversation/$conversationId/end'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200) {
        final resData = data['data'];
        return {
          'success': true,
          'data': resData,
          'summary': resData != null && resData['summary'] != null
              ? ConversationSummary.fromJson(resData['summary'])
              : null,
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to end conversation')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get conversation history
  static Future<Map<String, dynamic>> getConversationHistory({
    int limit = 10,
    int offset = 0,
    String status = 'all',
  }) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}ai-conversation?limit=$limit&offset=$offset&status=$status'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': true, 'data': <AIConversation>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        if (listData is! List) {
          return {'success': true, 'data': <AIConversation>[]};
        }
        final conversations = listData
            .map((e) => AIConversation.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': conversations};
      }
      return {'success': true, 'data': <AIConversation>[]};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get conversation by ID
  static Future<Map<String, dynamic>> getConversation(String conversationId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}ai-conversation/$conversationId'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': AIConversation.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to fetch conversation')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get available topics
  static Future<Map<String, dynamic>> getTopics({String? level}) async {
    try {
      final token = await _getToken();
      final url = level != null
          ? '${Endpoints.baseURL}ai-conversation/topics?level=$level'
          : '${Endpoints.baseURL}ai-conversation/topics';
      final response = await http.get(Uri.parse(url), headers: _getHeaders(token));

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': true, 'data': <ConversationTopic>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        if (listData is! List) {
          return {'success': true, 'data': <ConversationTopic>[]};
        }
        final topics = listData
            .map((e) => ConversationTopic.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': topics};
      }
      return {'success': true, 'data': <ConversationTopic>[]};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get practice scenarios
  static Future<Map<String, dynamic>> getScenarios({String? level}) async {
    try {
      final token = await _getToken();
      final url = level != null
          ? '${Endpoints.baseURL}ai-conversation/scenarios?level=$level'
          : '${Endpoints.baseURL}ai-conversation/scenarios';
      final response = await http.get(Uri.parse(url), headers: _getHeaders(token));

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': true, 'data': <PracticeScenario>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        if (listData is! List) {
          return {'success': true, 'data': <PracticeScenario>[]};
        }
        final scenarios = listData
            .map((e) => PracticeScenario.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': scenarios};
      }
      return {'success': true, 'data': <PracticeScenario>[]};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================
  // GRAMMAR FEEDBACK
  // ============================================

  /// Analyze text for grammar
  static Future<Map<String, dynamic>> analyzeGrammar(AnalyzeGrammarRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}grammar-feedback'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // API may return data directly or nested in 'data' field
        final feedbackData = data['data'] ?? data;
        if (feedbackData == null) {
          return {'success': false, 'message': 'No feedback data returned'};
        }

        GrammarFeedback? feedback;
        if (feedbackData is Map) {
          feedback = GrammarFeedback.fromJson(Map<String, dynamic>.from(feedbackData));
        }

        if (feedback != null) {
          return {
            'success': true,
            'data': feedback,
          };
        }
        return {'success': false, 'message': 'Invalid feedback format'};
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to analyze grammar')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get feedback by ID
  static Future<Map<String, dynamic>> getFeedback(String feedbackId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}grammar-feedback/$feedbackId'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': GrammarFeedback.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to fetch feedback')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get feedback history
  static Future<Map<String, dynamic>> getFeedbackHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}grammar-feedback/history?limit=$limit&offset=$offset'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': true, 'data': <GrammarFeedback>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        if (listData is! List) {
          return {'success': true, 'data': <GrammarFeedback>[]};
        }
        final feedbacks = listData
            .map((e) => GrammarFeedback.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': feedbacks};
      }
      return {'success': true, 'data': <GrammarFeedback>[]};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Mark feedback as viewed
  static Future<Map<String, dynamic>> markFeedbackViewed(String feedbackId) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${Endpoints.baseURL}grammar-feedback/$feedbackId/viewed'),
        headers: _getHeaders(token),
      );

      return {'success': response.statusCode == 200};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Explain grammar rule
  static Future<Map<String, dynamic>> explainRule(ExplainRuleRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}grammar-feedback/explain-rule'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': GrammarRuleExplanation.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to explain rule')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================
  // SPEECH FEATURES
  // ============================================

  /// Generate TTS audio
  static Future<Map<String, dynamic>> generateTTS(TTSRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}speech/tts'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': TTSResponse.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to generate audio')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Transcribe audio (STT)
  static Future<Map<String, dynamic>> transcribeAudio(File audioFile, {String? language}) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Endpoints.baseURL}speech/stt'),
      );

      request.headers.addAll({
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
      if (language != null) {
        request.fields['language'] = language;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = _safeJsonDecode(response.body);

      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': STTResponse.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to transcribe audio')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Evaluate pronunciation
  static Future<Map<String, dynamic>> evaluatePronunciation(
    File audioFile,
    String targetText,
    String language, {
    String source = 'practice',
    String? vocabularyId,
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Endpoints.baseURL}speech/pronunciation/evaluate'),
      );

      request.headers.addAll({
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
      request.fields['targetText'] = targetText;
      request.fields['language'] = language;
      request.fields['source'] = source;
      if (vocabularyId != null) {
        request.fields['vocabularyId'] = vocabularyId;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = _safeJsonDecode(response.body);

      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': PronunciationResult.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to evaluate pronunciation')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get pronunciation history
  static Future<Map<String, dynamic>> getPronunciationHistory({
    String? language,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      String url = '${Endpoints.baseURL}speech/pronunciation/history?limit=$limit&offset=$offset';
      if (language != null) url += '&language=$language';

      final response = await http.get(Uri.parse(url), headers: _getHeaders(token));
      final data = _safeJsonDecode(response.body);

      if (data == null) {
        return {'success': true, 'data': <PronunciationResult>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        if (listData is! List) {
          return {'success': true, 'data': <PronunciationResult>[]};
        }
        final results = listData
            .map((e) => PronunciationResult.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': results};
      }
      return {'success': true, 'data': <PronunciationResult>[]};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get pronunciation stats
  static Future<Map<String, dynamic>> getPronunciationStats({String? language}) async {
    try {
      final token = await _getToken();
      String url = '${Endpoints.baseURL}speech/pronunciation/stats';
      if (language != null) url += '?language=$language';

      final response = await http.get(Uri.parse(url), headers: _getHeaders(token));
      final data = _safeJsonDecode(response.body);

      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': PronunciationStats.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to fetch stats')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get available voices
  static Future<Map<String, dynamic>> getAvailableVoices({String? language}) async {
    try {
      final token = await _getToken();
      String url = '${Endpoints.baseURL}speech/voices';
      if (language != null) url += '?language=$language';

      final response = await http.get(Uri.parse(url), headers: _getHeaders(token));
      final data = _safeJsonDecode(response.body);

      if (data == null) {
        return {'success': true, 'data': <VoiceOption>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        if (listData is! List) {
          return {'success': true, 'data': <VoiceOption>[]};
        }
        final voices = listData
            .map((e) => VoiceOption.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': voices};
      }
      return {'success': true, 'data': <VoiceOption>[]};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================
  // ENHANCED TRANSLATION
  // ============================================

  /// Get enhanced translation
  static Future<Map<String, dynamic>> getEnhancedTranslation(
      EnhancedTranslationRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}translate/enhanced'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final translationData = data['data'];
        if (translationData == null) {
          return {'success': false, 'message': 'No translation data returned'};
        }
        // Handle if data is a map or extract from nested structure
        Map<String, dynamic> jsonData;
        if (translationData is Map<String, dynamic>) {
          jsonData = translationData;
        } else if (translationData is Map) {
          jsonData = Map<String, dynamic>.from(translationData);
        } else {
          return {'success': false, 'message': 'Invalid translation data format'};
        }
        return {
          'success': true,
          'data': EnhancedTranslation.fromJson(jsonData),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to translate')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Detect idioms
  static Future<Map<String, dynamic>> detectIdioms(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}translate/idioms'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'text': text,
          'sourceLanguage': sourceLanguage,
          'targetLanguage': targetLanguage,
        }),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': true, 'data': <IdiomInfo>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        if (listData is! List) {
          return {'success': true, 'data': <IdiomInfo>[]};
        }
        final idioms = listData
            .map((e) => IdiomInfo.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': idioms};
      }
      return {'success': true, 'data': <IdiomInfo>[]};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get contextual translation
  static Future<Map<String, dynamic>> getContextualTranslation(
      ContextualTranslationRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}translate/contextual'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': EnhancedTranslation.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to translate')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get popular translations
  static Future<Map<String, dynamic>> getPopularTranslations({
    required String language,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}translate/popular?language=$language&limit=$limit'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': true, 'data': <PopularTranslation>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        if (listData is! List) {
          return {'success': true, 'data': <PopularTranslation>[]};
        }
        final translations = listData
            .map((e) => PopularTranslation.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': translations};
      }
      return {'success': true, 'data': <PopularTranslation>[]};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================
  // AI-GENERATED QUIZZES
  // ============================================

  /// Generate AI quiz
  static Future<Map<String, dynamic>> generateQuiz(GenerateQuizRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}learning/quizzes/generate'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      final data = _safeJsonDecode(response.body);
      debugPrint('🎯 Generate quiz response: $data');
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final quizData = data['data'];
        if (quizData == null) {
          return {'success': false, 'message': 'No quiz data returned'};
        }
        // Handle different response structures
        Map<String, dynamic> jsonData;
        if (quizData is Map) {
          final converted = Map<String, dynamic>.from(quizData);
          // Check if quiz is nested
          jsonData = converted['quiz'] is Map
              ? Map<String, dynamic>.from(converted['quiz'])
              : converted;
        } else if (quizData is List && quizData.isNotEmpty) {
          // API might return array - use first quiz
          jsonData = Map<String, dynamic>.from(quizData.first);
        } else {
          return {'success': false, 'message': 'Invalid quiz data format'};
        }
        debugPrint('🎯 Quiz json data: questions count = ${(jsonData['questions'] as List?)?.length ?? 0}');
        final quiz = AIQuiz.fromJson(jsonData);
        debugPrint('🎯 Parsed quiz: ${quiz.questions.length} questions');
        return {
          'success': true,
          'data': quiz,
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to generate quiz')};
    } catch (e) {
      debugPrint('🎯 Generate quiz error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get AI quizzes
  static Future<Map<String, dynamic>> getAIQuizzes({int limit = 10}) async {
    try {
      final token = await _getToken();
      final url = '${Endpoints.baseURL}learning/quizzes/ai?limit=$limit';
      debugPrint('📋 Fetching AI quizzes from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      debugPrint('📋 AI quizzes response status: ${response.statusCode}');
      debugPrint('📋 AI quizzes response body: ${response.body}');

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        debugPrint('📋 AI quizzes: null data');
        return {'success': true, 'data': <AIQuiz>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        debugPrint('📋 AI quizzes listData type: ${listData?.runtimeType}, length: ${listData is List ? listData.length : 'N/A'}');
        if (listData is! List) {
          // Check if data is nested differently (e.g., data.quizzes)
          if (data['data'] is Map && data['data']['quizzes'] is List) {
            final quizzesList = data['data']['quizzes'] as List;
            debugPrint('📋 Found nested quizzes: ${quizzesList.length}');
            final quizzes = quizzesList
                .map((e) => AIQuiz.fromJson(e as Map<String, dynamic>))
                .toList();
            return {'success': true, 'data': quizzes};
          }
          return {'success': true, 'data': <AIQuiz>[]};
        }
        final quizzes = listData
            .map((e) => AIQuiz.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint('📋 Parsed ${quizzes.length} quizzes');
        return {'success': true, 'data': quizzes};
      }
      debugPrint('📋 AI quizzes: non-200 status code');
      return {'success': true, 'data': <AIQuiz>[]};
    } catch (e) {
      debugPrint('📋 AI quizzes error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Start AI quiz
  static Future<Map<String, dynamic>> startAIQuiz(String quizId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}learning/quizzes/ai/$quizId/start'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      debugPrint('🎯 Start quiz response: $data');
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        final responseData = data['data'];
        Map<String, dynamic> jsonData;

        // Handle nested structure: data.quiz or data directly
        if (responseData is Map) {
          final converted = Map<String, dynamic>.from(responseData);
          // Check if quiz is nested inside data.quiz
          if (converted['quiz'] is Map) {
            jsonData = Map<String, dynamic>.from(converted['quiz']);
            debugPrint('🎯 Found nested quiz structure');
          } else {
            jsonData = converted;
          }
        } else if (responseData is List && responseData.isNotEmpty) {
          jsonData = Map<String, dynamic>.from(responseData.first);
        } else {
          return {'success': false, 'message': 'Invalid quiz data format'};
        }

        debugPrint('🎯 Start quiz: questions count = ${(jsonData['questions'] as List?)?.length ?? 0}');
        final quiz = AIQuiz.fromJson(jsonData);
        debugPrint('🎯 Parsed started quiz: ${quiz.questions.length} questions');
        return {
          'success': true,
          'data': quiz,
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to start quiz')};
    } catch (e) {
      debugPrint('🎯 Start quiz error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Submit quiz answer
  static Future<Map<String, dynamic>> submitQuizAnswer(
      String quizId, SubmitAnswerRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}learning/quizzes/ai/$quizId/answer'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200) {
        final answerData = data['data'];
        return {
          'success': true,
          'data': answerData,
          'isCorrect': answerData?['isCorrect'] ?? false,
          'feedback': answerData?['feedback'],
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to submit answer')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Complete AI quiz
  static Future<Map<String, dynamic>> completeAIQuiz(
      String quizId, CompleteQuizRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}learning/quizzes/ai/$quizId/complete'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200) {
        final resData = data['data'];
        if (resData == null) {
          return {'success': false, 'message': 'No result data returned'};
        }
        return {
          'success': true,
          'data': resData,
          'result': AIQuizResult.fromJson(resData['result'] ?? resData),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to complete quiz')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get AI quiz stats
  static Future<Map<String, dynamic>> getAIQuizStats() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}learning/quizzes/ai/stats'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': AIQuizStats.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to fetch stats')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================
  // ADAPTIVE RECOMMENDATIONS
  // ============================================

  /// Get adaptive recommendations
  static Future<Map<String, dynamic>> getAdaptiveRecommendations() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}learning/recommendations/adaptive'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to fetch recommendations')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Refresh recommendations
  static Future<Map<String, dynamic>> refreshRecommendations() async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}learning/recommendations/refresh'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to refresh')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get weak areas
  static Future<Map<String, dynamic>> getWeakAreas() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}learning/progress/weak-areas'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': true, 'data': <WeakArea>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        if (listData is! List) {
          return {'success': true, 'data': <WeakArea>[]};
        }
        final weakAreas = listData
            .map((e) => WeakArea.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': weakAreas};
      }
      return {'success': true, 'data': <WeakArea>[]};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================
  // AI LESSON ASSISTANT
  // ============================================

  /// Get exercise hint
  static Future<Map<String, dynamic>> getExerciseHint(
    String lessonId,
    int exerciseIndex, {
    int hintLevel = 1,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}learning/lessons/$lessonId/assistant/hint'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'exerciseIndex': exerciseIndex,
          'hintLevel': hintLevel,
        }),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': HintResponse.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to get hint')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Explain a concept
  static Future<Map<String, dynamic>> explainConcept(
    String lessonId,
    String concept, {
    String? context,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}learning/lessons/$lessonId/assistant/explain'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'concept': concept,
          if (context != null) 'context': context,
        }),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': ExplanationResponse.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to explain concept')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get feedback on wrong answer
  static Future<Map<String, dynamic>> getAnswerFeedback(
    String lessonId,
    int exerciseIndex,
    dynamic userAnswer,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}learning/lessons/$lessonId/assistant/feedback'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'exerciseIndex': exerciseIndex,
          'userAnswer': userAnswer,
        }),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': FeedbackResponse.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to get feedback')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Ask a question about the lesson
  static Future<Map<String, dynamic>> askLessonQuestion(
    String lessonId,
    String question,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}learning/lessons/$lessonId/assistant/ask'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'question': question,
        }),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': AskQuestionResponse.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to get answer')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Generate practice variations
  static Future<Map<String, dynamic>> generatePracticeVariations(
    String lessonId,
    int exerciseIndex, {
    int count = 3,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}learning/lessons/$lessonId/assistant/practice'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'exerciseIndex': exerciseIndex,
          'count': count,
        }),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': PracticeVariationsResponse.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to generate practice')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get lesson summary
  static Future<Map<String, dynamic>> getLessonSummary(String lessonId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}learning/lessons/$lessonId/assistant/summary'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': LessonSummaryResponse.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to get summary')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get translation help with word breakdown
  static Future<Map<String, dynamic>> getTranslationHelp(
    String text,
    String sourceLanguage,
    String targetLanguage, {
    String? context,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}assistant/translate'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'text': text,
          'sourceLanguage': sourceLanguage,
          'targetLanguage': targetLanguage,
          if (context != null) 'context': context,
        }),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': TranslationHelpResponse.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to translate')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================
  // AI LESSON BUILDER
  // ============================================

  /// Generate a complete lesson using AI
  static Future<Map<String, dynamic>> generateLesson(GenerateLessonRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}lessons/generate'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      debugPrint('🎓 Generate lesson response: ${response.body}');

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = data['data'];
        if (responseData == null) {
          return {'success': false, 'message': 'No lesson data returned'};
        }
        return {
          'success': true,
          'data': GeneratedLessonResponse.fromJson(
            responseData is Map<String, dynamic>
                ? responseData
                : Map<String, dynamic>.from(responseData),
          ),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to generate lesson')};
    } catch (e) {
      debugPrint('🎓 Generate lesson error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Generate exercises for a topic
  static Future<Map<String, dynamic>> generateExercises(GenerateExercisesRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}lessons/generate/exercises'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      debugPrint('🎓 Generate exercises response: ${response.body}');

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = data['data'];
        if (responseData == null) {
          return {'success': false, 'message': 'No exercises data returned'};
        }
        return {
          'success': true,
          'data': GeneratedExercisesResponse.fromJson(
            responseData is Map<String, dynamic>
                ? responseData
                : Map<String, dynamic>.from(responseData),
          ),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to generate exercises')};
    } catch (e) {
      debugPrint('🎓 Generate exercises error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Generate vocabulary for a topic
  static Future<Map<String, dynamic>> generateVocabulary(GenerateVocabularyRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}lessons/generate/vocabulary'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      debugPrint('🎓 Generate vocabulary response: ${response.body}');

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = data['data'];
        if (responseData == null) {
          return {'success': false, 'message': 'No vocabulary data returned'};
        }
        return {
          'success': true,
          'data': GeneratedVocabularyResponse.fromJson(
            responseData is Map<String, dynamic>
                ? responseData
                : Map<String, dynamic>.from(responseData),
          ),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to generate vocabulary')};
    } catch (e) {
      debugPrint('🎓 Generate vocabulary error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Generate full curriculum (Admin only)
  static Future<Map<String, dynamic>> generateCurriculum(GenerateCurriculumRequest request) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}lessons/generate/curriculum'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      debugPrint('🎓 Generate curriculum response: ${response.body}');

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = data['data'];
        if (responseData == null) {
          return {'success': false, 'message': 'No curriculum data returned'};
        }
        return {
          'success': true,
          'data': CurriculumResponse.fromJson(
            responseData is Map<String, dynamic>
                ? responseData
                : Map<String, dynamic>.from(responseData),
          ),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to generate curriculum')};
    } catch (e) {
      debugPrint('🎓 Generate curriculum error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Enhance existing lesson with AI
  static Future<Map<String, dynamic>> enhanceLesson(
    String lessonId,
    EnhanceLessonRequest request,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Endpoints.baseURL}lessons/$lessonId/enhance'),
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      debugPrint('🎓 Enhance lesson response: ${response.body}');

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200) {
        final responseData = data['data'];
        if (responseData == null) {
          return {'success': false, 'message': 'No data returned'};
        }
        return {
          'success': true,
          'data': EnhanceLessonResponse.fromJson(
            responseData is Map<String, dynamic>
                ? responseData
                : Map<String, dynamic>.from(responseData),
          ),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to enhance lesson')};
    } catch (e) {
      debugPrint('🎓 Enhance lesson error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get AI-generated lessons
  static Future<Map<String, dynamic>> getAIGeneratedLessons({
    String? language,
    String? level,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (language != null) 'language': language,
        if (level != null) 'level': level,
        if (category != null) 'category': category,
      };
      final uri = Uri.parse('${Endpoints.baseURL}lessons/ai-generated')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: _getHeaders(token));

      debugPrint('🎓 Get AI lessons response: ${response.body}');

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': true, 'data': <GeneratedLesson>[]};
      }

      if (response.statusCode == 200) {
        final listData = data['data'];
        if (listData is! List) {
          return {'success': true, 'data': <GeneratedLesson>[]};
        }
        final lessons = listData
            .map((e) => GeneratedLesson.fromJson(e as Map<String, dynamic>))
            .toList();
        return {
          'success': true,
          'data': lessons,
          'total': data['total'] ?? lessons.length,
        };
      }
      return {'success': true, 'data': <GeneratedLesson>[]};
    } catch (e) {
      debugPrint('🎓 Get AI lessons error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get lesson templates and configuration
  static Future<Map<String, dynamic>> getLessonTemplates() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}lessons/templates'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': LessonTemplatesResponse.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to fetch templates')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get lesson generation stats (Admin only)
  static Future<Map<String, dynamic>> getLessonGenerationStats() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Endpoints.baseURL}lessons/stats'),
        headers: _getHeaders(token),
      );

      final data = _safeJsonDecode(response.body);
      if (data == null) {
        return {'success': false, 'message': 'Invalid response from server'};
      }

      if (response.statusCode == 200 && data['data'] != null) {
        return {
          'success': true,
          'data': LessonGenerationStats.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': _getErrorMessage(data, 'Failed to fetch stats')};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
