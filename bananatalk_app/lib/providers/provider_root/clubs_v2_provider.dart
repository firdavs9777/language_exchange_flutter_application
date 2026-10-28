import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/services/gathering_api_client.dart';

/// The client the clubs v2 access check uses; overridden in tests.
final clubsV2ApiProvider = Provider<GatheringApiClient>((_) => GatheringApiClient());

/// Clubs v2 (rules, warnings, the language pair) is on for this user.
///
/// Per user, so not in app-config (which is unauthenticated). Any failure is
/// "no": the new UI never appears because a request failed.
final clubsV2AccessProvider = FutureProvider<bool>((ref) async {
  try {
    return await ref.watch(clubsV2ApiProvider).getClubsV2Access();
  } catch (_) {
    return false;
  }
});
