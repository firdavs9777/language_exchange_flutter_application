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

  /// Translate a message to the target language
  static Future<Map<String, dynamic>> translateMessage({
    required String messageId,
    required String targetLanguage,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.translateMessageURL(messageId)}');

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

  /// Auto-translate content based on device language
  /// Returns target language code (device language or preferred language)
  static Future<String> getAutoTranslateLanguage() async {
    // First check if user has a preferred translation language
    final preferredLang = await getPreferredLanguage();
    if (preferredLang != null && preferredLang.isNotEmpty) {
      return preferredLang;
    }
    
    // Otherwise use device language
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

