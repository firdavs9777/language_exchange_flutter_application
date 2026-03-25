import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/matching/matching_model.dart';
import 'package:bananatalk_app/services/matching_service.dart';

// ==================== MATCHING PROVIDERS ====================

/// Recommendations provider
final matchingRecommendationsProvider =
    FutureProvider<List<MatchRecommendation>>((ref) async {
  print('🎯 Provider: Fetching recommendations...');
  final result = await MatchingService.getRecommendations();
  print('🎯 Provider: Result success=${result['success']}, hasData=${result['data'] != null}');
  if (result['success'] == true && result['data'] != null) {
    final response = MatchingResponse.fromJson(result['data']);
    print('🎯 Provider: Parsed ${response.data.length} recommendations');
    return response.data;
  }
  print('🎯 Provider: Returning empty list, error=${result['error']}');
  return [];
});

/// Quick matches provider (online users)
final quickMatchesProvider =
    FutureProvider<List<MatchRecommendation>>((ref) async {
  print('🎯 Provider: Fetching quick matches (online users)...');
  final result = await MatchingService.getQuickMatches();
  print('🎯 Provider: Result success=${result['success']}, hasData=${result['data'] != null}');
  print('🎯 Provider: Raw data keys: ${result['data']?.keys?.toList()}');
  if (result['success'] == true && result['data'] != null) {
    final response = MatchingResponse.fromJson(result['data']);
    print('🎯 Provider: Parsed ${response.data.length} quick matches');
    return response.data;
  }
  print('🎯 Provider: Returning empty list, error=${result['error']}');
  return [];
});

/// Find by language provider
final matchByLanguageProvider =
    FutureProvider.family<List<MatchRecommendation>, String>((ref, language) async {
  final result = await MatchingService.findByLanguage(language: language);
  if (result['success'] == true && result['data'] != null) {
    return MatchingResponse.fromJson(result['data']).data;
  }
  return [];
});

/// Similar users provider
final similarUsersProvider =
    FutureProvider.family<List<MatchRecommendation>, String>((ref, userId) async {
  final result = await MatchingService.getSimilarUsers(userId: userId);
  if (result['success'] == true && result['data'] != null) {
    return MatchingResponse.fromJson(result['data']).data;
  }
  return [];
});

/// Selected matching tab
final matchingTabProvider = StateProvider<int>((ref) => 0);

/// Selected language for language filter
final matchingLanguageFilterProvider = StateProvider<String?>((ref) => null);

/// Available languages for matching
final matchingLanguagesProvider = Provider<List<String>>((ref) {
  return [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Japanese',
    'Korean',
    'Chinese',
    'Arabic',
    'Hindi',
    'Turkish',
    'Vietnamese',
    'Thai',
    'Indonesian',
  ];
});
