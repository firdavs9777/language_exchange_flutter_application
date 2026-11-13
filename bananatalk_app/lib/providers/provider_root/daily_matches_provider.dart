import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/community_first_page_cache.dart';
import 'package:bananatalk_app/services/matching_daily_service.dart';

/// Today's batch from `matching/daily`.
///
/// With the fast-list flag off (read, never watched) this is exactly the
/// plain fetch it always was. With it on, the fetch also keeps the batch on
/// disk for the next cold open, and starts [dailyMatchesCachedProvider] (read
/// from disk once per session; later fetches reuse it). What keeps the disk
/// copy from ever painting late or over live state is the Matches tab's gate:
/// it shows that copy only while this provider has neither a value nor an
/// error, and only if the copy exists -- i.e. a flag-on fetch has started.
final dailyMatchesProvider = FutureProvider<DailyMatchesResult>((ref) {
  if (!ref.read(communityFastListEnabledProvider)) {
    return MatchingDailyService.getDaily();
  }
  ref.read(dailyMatchesCachedProvider);
  return _fetchAndKeep(ref.read(communityFirstPageCacheProvider));
});

Future<DailyMatchesResult> _fetchAndKeep(CommunityFirstPageCache cache) async {
  // Taken first: a sign-out (cache cleared) during the fetch drops the write.
  final epoch = cache.epoch;
  final userId = await cache.signedInUserId();
  final fetched = await MatchingDailyService.getDailyWithRaw();
  if (userId != null) unawaited(_keep(cache, userId, fetched.raw, epoch));
  return fetched.result;
}

/// Writes [raw] as [userId]'s cached batch -- only while they are still the
/// signed-in user. A batch without a usable `nextRefreshAt`, or the kill
/// switch's 404 (no [raw]), removes the entry instead.
Future<void> _keep(
  CommunityFirstPageCache cache,
  String userId,
  Map<String, dynamic>? raw,
  int epoch,
) async {
  if (await cache.signedInUserId() != userId || cache.epoch != epoch) return;
  final next = raw?['nextRefreshAt'];
  final rows = raw?['matches'];
  if (next is! String || DateTime.tryParse(next) == null || rows is! List) {
    await cache.remove(userId: userId, slot: CommunityFirstPageCache.daily);
    return;
  }
  await cache.write(
    userId: userId,
    slot: CommunityFirstPageCache.daily,
    rows: rows.whereType<Map<String, dynamic>>().toList(),
    meta: {CommunityFirstPageCache.nextRefreshAtKey: next},
    epoch: epoch,
  );
}

/// Today's batch as kept on disk for the signed-in user, read once; null with
/// the flag off, when there is none, or when it is past its `nextRefreshAt`.
/// The Matches tab shows it only while [dailyMatchesProvider]'s first fetch
/// has produced nothing (no value, no error) -- never over live state.
final dailyMatchesCachedProvider = FutureProvider<DailyMatchesResult?>((
  ref,
) async {
  if (!ref.read(communityFastListEnabledProvider)) return null;
  final cache = ref.read(communityFirstPageCacheProvider);
  final userId = await cache.signedInUserId();
  if (userId == null) return null;
  final snapshot = await cache.read(
    userId: userId,
    slot: CommunityFirstPageCache.daily,
  );
  if (snapshot == null) return null;
  final result = DailyMatchesResult.fromJson({
    'nextRefreshAt': snapshot.meta[CommunityFirstPageCache.nextRefreshAtKey],
    'matches': snapshot.rows,
  });
  final matches = result.matches
      .where((m) => m.user.id.isNotEmpty && m.user.id != userId)
      .toList();
  if (matches.isEmpty) return null;
  return DailyMatchesResult(
    nextRefreshAt: result.nextRefreshAt,
    matches: matches,
  );
});

/// User ids skipped from the daily batch this session. Outlives the tab's
/// State (TabBarView rebuilds it on remount) so a skip sticks until the
/// server, which drops skipped users from the cached batch, takes over.
final dailyMatchesSkippedProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);
