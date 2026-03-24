import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/language_service.dart';

class TranslationService {
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

  /// Translate a message to the target language (returns full enhanced translation)
  static Future<Map<String, dynamic>> translateMessage({
    required String messageId,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.translateMessageURL(messageId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'targetLanguage': targetLanguage,
          if (sourceLanguage != null) 'sourceLanguage': sourceLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = data['data'] as Map<String, dynamic>? ?? {};
        return {
          'success': true,
          'data': responseData,
          'cached': data['cached'] ?? responseData['cached'] ?? false,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Translation failed',
          'message': errorData['message'],
          'limit': errorData['limit'],
          'remaining': errorData['remaining'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get all translations for a message
  static Future<Map<String, dynamic>> getTranslations({
    required String messageId,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.getTranslationsURL(messageId)}');

      final response = await http.get(
        url,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': (data['data'] as List?)
                  ?.map((t) => MessageTranslation.fromJson(t))
                  .toList() ??
              [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get translations',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get the user's preferred translation language
  static Future<String?> getPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('preferred_translation_language');
  }

  /// Set the user's preferred translation language
  static Future<void> setPreferredLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_translation_language', languageCode);
  }

  /// Supported languages for translation
  static List<Map<String, String>> get supportedLanguages => [
        {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
        {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸'},
        {'code': 'fr', 'name': 'French', 'flag': '🇫🇷'},
        {'code': 'de', 'name': 'German', 'flag': '🇩🇪'},
        {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹'},
        {'code': 'pt', 'name': 'Portuguese', 'flag': '🇵🇹'},
        {'code': 'ru', 'name': 'Russian', 'flag': '🇷🇺'},
        {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳'},
        {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵'},
        {'code': 'ko', 'name': 'Korean', 'flag': '🇰🇷'},
        {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦'},
        {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳'},
        {'code': 'th', 'name': 'Thai', 'flag': '🇹🇭'},
        {'code': 'vi', 'name': 'Vietnamese', 'flag': '🇻🇳'},
        {'code': 'id', 'name': 'Indonesian', 'flag': '🇮🇩'},
        {'code': 'tr', 'name': 'Turkish', 'flag': '🇹🇷'},
        {'code': 'pl', 'name': 'Polish', 'flag': '🇵🇱'},
        {'code': 'nl', 'name': 'Dutch', 'flag': '🇳🇱'},
        {'code': 'sv', 'name': 'Swedish', 'flag': '🇸🇪'},
        {'code': 'uk', 'name': 'Ukrainian', 'flag': '🇺🇦'},
      ];

  /// Get language name from code
  static String getLanguageName(String code) {
    final lang = supportedLanguages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'code': code, 'name': code.toUpperCase(), 'flag': '🌐'},
    );
    return lang['name']!;
  }

  /// Get language flag from code
  static String getLanguageFlag(String code) {
    final lang = supportedLanguages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'code': code, 'name': code, 'flag': '🌐'},
    );
    return lang['flag']!;
  }

  /// Translate a moment to the target language
  static Future<Map<String, dynamic>> translateMoment({
    required String momentId,
    required String targetLanguage,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.translateMomentURL(momentId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'targetLanguage': targetLanguage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': MessageTranslation.fromJson(data['data']),
          'cached': data['cached'] ?? false,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Translation failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Translate a comment to the target language
  static Future<Map<String, dynamic>> translateComment({
    required String commentId,
    required String targetLanguage,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.translateCommentURL(commentId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'targetLanguage': targetLanguage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': MessageTranslation.fromJson(data['data']),
          'cached': data['cached'] ?? false,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Translation failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get TTS audio URL for a message
  static Future<Map<String, dynamic>> getMessageTTS({
    required String messageId,
    required String language,
    double speed = 1.0,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.messageTtsURL(messageId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'language': language,
          'speed': speed,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'TTS failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Save a word from translation breakdown to vocabulary
  static Future<Map<String, dynamic>> saveToVocabulary({
    required String messageId,
    required String word,
    required String translation,
    String? pronunciation,
    required String language,
    String? partOfSpeech,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.messageVocabularyURL(messageId)}');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'word': word,
          'translation': translation,
          if (pronunciation != null) 'pronunciation': pronunciation,
          'language': language,
          if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to save word',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Map language name (e.g. "English") to code (e.g. "en")
  static String? _languageNameToCode(String name) {
    final normalized = name.trim().toLowerCase();
    for (final lang in supportedLanguages) {
      if (lang['name']!.toLowerCase() == normalized) {
        return lang['code'];
      }
    }
    // Also check if it's already a code
    for (final lang in supportedLanguages) {
      if (lang['code'] == normalized) {
        return lang['code'];
      }
    }
    return null;
  }

  /// Auto-translate to the user's native language from their profile.
  /// Falls back to device language if native language is not available.
  static Future<String> getAutoTranslateLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Use native language from user profile (cached at login)
    final nativeLang = prefs.getString('user_native_language');
    if (nativeLang != null && nativeLang.isNotEmpty) {
      final code = _languageNameToCode(nativeLang);
      if (code != null) return code;
    }

    // 2. Fallback to device language
    return LanguageService.getDeviceLanguage();
  }

  /// Check if auto-translate should be enabled for content type
  static Future<bool> shouldAutoTranslate(String contentType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'auto_translate_${contentType}';
    return prefs.getBool(key) ?? true; // Default to true
  }

  /// Set auto-translate preference for content type
  static Future<void> setAutoTranslate(String contentType, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'auto_translate_${contentType}';
    await prefs.setBool(key, enabled);
  }
}

