import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/models/learning/leaderboard_model.dart';

// ==================== LEADERBOARD PROVIDERS ====================

/// Leaderboard provider
final leaderboardProvider =
    FutureProvider.family<LeaderboardResponse?, LeaderboardFilter>(
        (ref, filter) async {
  try {
    final result = await LearningService.getLeaderboard(
      type: filter.type,
      language: filter.language,
      limit: filter.limit,
    );
    if (result['success'] == true && result['data'] != null) {
      return LeaderboardResponse.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Selected leaderboard type
final leaderboardTypeProvider = StateProvider<String>((ref) {
  return 'weekly';
});

/// XP Leaderboard with period filter
final xpLeaderboardProvider =
    FutureProvider.family<LeaderboardResponse?, LeaderboardFilter>(
        (ref, filter) async {
  try {
    final result = await LearningService.getXpLeaderboard(
      period: filter.period ?? 'all',
      language: filter.language,
      limit: filter.limit,
    );
    if (result['success'] == true && result['data'] != null) {
      return LeaderboardResponse.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Streak Leaderboard provider
final streakLeaderboardProvider =
    FutureProvider.family<LeaderboardResponse?, String>((ref, type) async {
  try {
    final result = await LearningService.getStreakLeaderboard(type: type);
    if (result['success'] == true && result['data'] != null) {
      return LeaderboardResponse.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Friends Leaderboard provider
final friendsLeaderboardProvider =
    FutureProvider<LeaderboardResponse?>((ref) async {
  try {
    final result = await LearningService.getFriendsLeaderboard();
    if (result['success'] == true && result['data'] != null) {
      return LeaderboardResponse.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// My Ranks provider
final myRanksProvider = FutureProvider<MyRanksData?>((ref) async {
  try {
    final result = await LearningService.getMyRanks();
    if (result['success'] == true && result['data'] != null) {
      return MyRanksData.fromJson(result['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Selected leaderboard period (for XP tab)
final leaderboardPeriodProvider = StateProvider<String>((ref) {
  return 'all';
});

/// Selected streak type (for streaks tab)
final streakTypeProvider = StateProvider<String>((ref) {
  return 'current';
});

/// Selected leaderboard tab index
final leaderboardTabIndexProvider = StateProvider<int>((ref) {
  return 0;
});
