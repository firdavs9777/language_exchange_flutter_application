import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/user_limits.dart';
import 'package:bananatalk_app/services/user_limits_service.dart';

/// FutureProvider for fetching user limits
final userLimitsProvider = FutureProvider.family<UserLimits, String>(
  (ref, userId) async {
    return await UserLimitsService.getUserLimits(userId);
  },
);

/// StateNotifier for managing limits state with auto-refresh
class UserLimitsNotifier extends StateNotifier<AsyncValue<UserLimits>> {
  final String userId;

  UserLimitsNotifier(this.userId) : super(const AsyncValue.loading()) {
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    try {
      state = const AsyncValue.loading();
      final limits = await UserLimitsService.getUserLimits(userId);
      state = AsyncValue.data(limits);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh limits from API
  Future<void> refresh() async {
    await _loadLimits();
  }

  /// Check if user can perform an action
  Future<bool> canPerformAction(String actionType) async {
    try {
      return await UserLimitsService.canPerformAction(userId, actionType);
    } catch (e) {
      // On error, allow action (fail open)
      return true;
    }
  }
}

/// StateNotifierProvider for user limits
final userLimitsNotifierProvider =
    StateNotifierProvider.family<UserLimitsNotifier, AsyncValue<UserLimits>, String>(
  (ref, userId) {
    return UserLimitsNotifier(userId);
  },
);

/// Helper provider to get current limits or null
final currentUserLimitsProvider = Provider.family<UserLimits?, String>(
  (ref, userId) {
    final limitsAsync = ref.watch(userLimitsProvider(userId));
    return limitsAsync.valueOrNull;
  },
);

