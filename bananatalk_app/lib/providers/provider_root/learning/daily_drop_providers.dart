import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Today's grammar + vocabulary for the signed-in user.
final dailyDropProvider = FutureProvider<DailyDropState>((ref) async {
  return LearningService.getDailyDrop();
});
