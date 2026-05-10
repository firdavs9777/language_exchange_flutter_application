import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/models/learning/learning_progress_model.dart';
import 'package:bananatalk_app/pages/learning/models/weekly_digest.dart';

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

/// Weekly digest provider — last 7 days of learning activity.
final weeklyDigestProvider = FutureProvider.autoDispose<WeeklyDigest>((ref) async {
  return LearningService.getWeeklyDigest();
});
