import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'app_language';
  
  // Supported languages
  static const List<String> supportedLanguages = ['en', 'zh', 'ko', 'ru', 'es', 'ar'];
  
  // Language names in their native language
  static const Map<String, String> languageNames = {
    'en': 'English',
    'zh': '中文',
    'ko': '한국어',
    'ru': 'Русский',
    'es': 'Español',
    'ar': 'العربية',
  };
  
  // Language flags
  static const Map<String, String> languageFlags = {
    'en': '🇺🇸',
    'zh': '🇨🇳',
    'ko': '🇰🇷',
    'ru': '🇷🇺',
    'es': '🇪🇸',
    'ar': '🇸🇦',
  };
  
  /// Get device language and map to supported language
  static String getDeviceLanguage() {
    try {
      final locale = Platform.localeName;
      final languageCode = locale.split('_').first.toLowerCase();
      
      // Map device language to supported language
      if (supportedLanguages.contains(languageCode)) {
        return languageCode;
      }
      
      // Handle language variants
      if (languageCode.startsWith('zh')) return 'zh';
      if (languageCode.startsWith('ko')) return 'ko';
      if (languageCode.startsWith('ru')) return 'ru';
      if (languageCode.startsWith('es')) return 'es';
      if (languageCode.startsWith('ar')) return 'ar';
      
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
      case 'zh':
        return const Locale('zh', 'CN');
      case 'ko':
        return const Locale('ko', 'KR');
      case 'ru':
        return const Locale('ru', 'RU');
      case 'es':
        return const Locale('es', 'ES');
      case 'ar':
        return const Locale('ar', 'SA');
      case 'en':
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

