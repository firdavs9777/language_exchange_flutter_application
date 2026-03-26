import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'app_language';

  // Supported languages (all 18 languages matching ARB files)
  static const List<String> supportedLanguages = [
    'en',    // English
    'ko',    // Korean
    'ja',    // Japanese
    'zh',    // Chinese Simplified
    'zh_TW', // Chinese Traditional
    'es',    // Spanish
    'fr',    // French
    'de',    // German
    'it',    // Italian
    'pt',    // Portuguese
    'ru',    // Russian
    'ar',    // Arabic
    'hi',    // Hindi
    'th',    // Thai
    'vi',    // Vietnamese
    'id',    // Indonesian
    'tl',    // Tagalog/Filipino
    'tr',    // Turkish
  ];

  // Language names in their native language
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ko': '한국어',
    'ja': '日本語',
    'zh': '简体中文',
    'zh_TW': '繁體中文',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'th': 'ไทย',
    'vi': 'Tiếng Việt',
    'id': 'Bahasa Indonesia',
    'tl': 'Filipino',
    'tr': 'Türkçe',
  };

  // Language flags
  static const Map<String, String> languageFlags = {
    'en': '🇺🇸',
    'ko': '🇰🇷',
    'ja': '🇯🇵',
    'zh': '🇨🇳',
    'zh_TW': '🇹🇼',
    'es': '🇪🇸',
    'fr': '🇫🇷',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'pt': '🇧🇷',
    'ru': '🇷🇺',
    'ar': '🇸🇦',
    'hi': '🇮🇳',
    'th': '🇹🇭',
    'vi': '🇻🇳',
    'id': '🇮🇩',
    'tl': '🇵🇭',
    'tr': '🇹🇷',
  };
  
  /// Get device language and map to supported language
  static String getDeviceLanguage() {
    try {
      final locale = Platform.localeName;
      final parts = locale.split('_');
      final languageCode = parts.first.toLowerCase();
      final countryCode = parts.length > 1 ? parts[1].toUpperCase() : '';

      // Handle Chinese variants (Traditional vs Simplified)
      if (languageCode == 'zh') {
        // Traditional Chinese regions: Taiwan, Hong Kong, Macau
        if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
          return 'zh_TW';
        }
        return 'zh'; // Simplified Chinese
      }

      // Check if exact match in supported languages
      if (supportedLanguages.contains(languageCode)) {
        return languageCode;
      }

      // Handle language variants - map to closest supported language
      final languageMapping = {
        'fil': 'tl', // Filipino -> Tagalog
        'in': 'id',  // Indonesian (old code)
        'iw': 'ar',  // Hebrew old code -> fallback to Arabic for RTL
        'nb': 'en',  // Norwegian Bokmål -> English fallback
        'nn': 'en',  // Norwegian Nynorsk -> English fallback
        'ms': 'id',  // Malay -> Indonesian (similar)
      };

      if (languageMapping.containsKey(languageCode)) {
        return languageMapping[languageCode]!;
      }

      // Default to English
      return 'en';
    } catch (e) {
      return 'en';
    }
  }
  
  /// Get saved language preference or device language
  static Future<String> getAppLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null && supportedLanguages.contains(savedLanguage)) {
        return savedLanguage;
      }
      
      // Use device language if no preference saved
      return getDeviceLanguage();
    } catch (e) {
      return 'en';
    }
  }
  
  /// Save language preference
  static Future<void> setAppLanguage(String languageCode) async {
    if (!supportedLanguages.contains(languageCode)) {
      throw ArgumentError('Unsupported language: $languageCode');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
  
  /// Get Locale from language code
  static Locale getLocale(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const Locale('en', 'US');
      case 'ko':
        return const Locale('ko', 'KR');
      case 'ja':
        return const Locale('ja', 'JP');
      case 'zh':
        return const Locale('zh', 'CN');
      case 'zh_TW':
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW');
      case 'es':
        return const Locale('es', 'ES');
      case 'fr':
        return const Locale('fr', 'FR');
      case 'de':
        return const Locale('de', 'DE');
      case 'it':
        return const Locale('it', 'IT');
      case 'pt':
        return const Locale('pt', 'BR');
      case 'ru':
        return const Locale('ru', 'RU');
      case 'ar':
        return const Locale('ar', 'SA');
      case 'hi':
        return const Locale('hi', 'IN');
      case 'th':
        return const Locale('th', 'TH');
      case 'vi':
        return const Locale('vi', 'VN');
      case 'id':
        return const Locale('id', 'ID');
      case 'tl':
        return const Locale('tl', 'PH');
      case 'tr':
        return const Locale('tr', 'TR');
      default:
        return const Locale('en', 'US');
    }
  }
  
  /// Get language name
  static String getLanguageName(String code) {
    return languageNames[code] ?? code.toUpperCase();
  }
  
  /// Get language flag
  static String getLanguageFlag(String code) {
    return languageFlags[code] ?? '🌐';
  }
  
  /// Get all supported languages as list
  static List<Map<String, String>> getSupportedLanguagesList() {
    return supportedLanguages.map((code) => {
      'code': code,
      'name': languageNames[code]!,
      'flag': languageFlags[code]!,
    }).toList();
  }
}

