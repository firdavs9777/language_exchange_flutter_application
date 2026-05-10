import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/models/learning/achievement_model.dart';

// ==================== ACHIEVEMENT PROVIDERS ====================

/// Achievements provider
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  try {
    final result = await LearningService.getAchievements();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List) {
        return data.map((e) => Achievement.fromJson(e)).toList();
      } else if (data is Map && data['achievements'] != null) {
        return (data['achievements'] as List)
            .map((e) => Achievement.fromJson(e))
            .toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Unlocked achievements count (for badge)
final unlockedAchievementsCountProvider = Provider<int>((ref) {
  final achievements = ref.watch(achievementsProvider);
  return achievements.valueOrNull?.where((a) => a.isUnlocked).length ?? 0;
});
