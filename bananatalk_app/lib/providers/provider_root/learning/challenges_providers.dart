import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/models/learning/challenge_model.dart';

// ==================== CHALLENGE PROVIDERS ====================

/// Challenges provider
final challengesProvider = FutureProvider<List<Challenge>>((ref) async {
  try {
    final result = await LearningService.getChallenges();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List) {
        return data.map((e) => Challenge.fromJson(e)).toList();
      } else if (data is Map) {
        // Combine daily, weekly, and special challenges
        final List<Challenge> all = [];
        if (data['daily'] != null && data['daily'] is List) {
          all.addAll(
              (data['daily'] as List).map((e) => Challenge.fromJson(e)));
        }
        if (data['weekly'] != null && data['weekly'] is List) {
          all.addAll(
              (data['weekly'] as List).map((e) => Challenge.fromJson(e)));
        }
        if (data['special'] != null && data['special'] is List) {
          all.addAll(
              (data['special'] as List).map((e) => Challenge.fromJson(e)));
        }
        return all;
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Daily challenges provider
final dailyChallengesProvider = Provider<List<Challenge>>((ref) {
  final challenges = ref.watch(challengesProvider);
  return challenges.valueOrNull
          ?.where((c) => c.type.toLowerCase() == 'daily')
          .toList() ??
      [];
});

/// Weekly challenges provider
final weeklyChallengesProvider = Provider<List<Challenge>>((ref) {
  final challenges = ref.watch(challengesProvider);
  return challenges.valueOrNull
          ?.where((c) => c.type.toLowerCase() == 'weekly')
          .toList() ??
      [];
});
