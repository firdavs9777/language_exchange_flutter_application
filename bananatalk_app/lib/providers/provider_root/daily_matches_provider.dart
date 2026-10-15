import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/services/matching_daily_service.dart';

final dailyMatchesProvider = FutureProvider<DailyMatchesResult>((ref) {
  return MatchingDailyService.getDaily();
});

/// User ids skipped from the daily batch this session. Outlives the tab's
/// State (TabBarView rebuilds it on remount) so a skip sticks until the
/// server, which drops skipped users from the cached batch, takes over.
final dailyMatchesSkippedProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);
