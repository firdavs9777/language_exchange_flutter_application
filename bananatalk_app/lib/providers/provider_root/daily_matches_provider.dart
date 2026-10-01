import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/services/matching_daily_service.dart';

final dailyMatchesProvider = FutureProvider<DailyMatchesResult>((ref) {
  return MatchingDailyService.getDaily();
});
