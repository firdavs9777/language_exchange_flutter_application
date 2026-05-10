import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';

// ==================== PROGRESS PROVIDERS ====================

/// Learning progress provider
final learningProgressProvider = FutureProvider<LearningProgress?>((ref) async {
  try {
    final result = await LearningService.getProgress();
    if (result['success'] == true && result['data'] != null) {
      return LearningProgress.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Daily goals provider
final dailyGoalsProvider = FutureProvider<DailyGoalsResponse?>((ref) async {
  try {
    final result = await LearningService.getDailyGoals();
    if (result['success'] == true && result['data'] != null) {
      return DailyGoalsResponse.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});
