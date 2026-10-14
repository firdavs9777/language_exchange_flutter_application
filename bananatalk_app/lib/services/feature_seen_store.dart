import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';

/// Which AI Study tiles this account has opened, for NEW badges (spec §4.5).
/// Keys are user-scoped: session_prefs clears everything not on its
/// device-level allow-list at logout. Fails closed like `GuideStore`: storage
/// unreadable -> everything seen -> no badges.
class FeatureSeenStore {
  static String keyFor(String slug) => 'study_feature_seen_$slug';

  static Future<Set<String>> readSeen({
    Future<SharedPreferences> Function()? prefs,
  }) async {
    final all = StudyFeature.values.map((f) => f.slug);
    try {
      final p = await (prefs ?? SharedPreferences.getInstance)();
      final seen = <String>{};
      for (final slug in all) {
        try {
          if (p.getBool(keyFor(slug)) ?? false) seen.add(slug);
        } catch (_) {}
      }
      return seen;
    } catch (_) {
      return all.toSet();
    }
  }

  static Future<void> markSeen(String slug) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(keyFor(slug), true);
    } catch (_) {}
  }
}

final featureSeenProvider =
    FutureProvider<Set<String>>((ref) => FeatureSeenStore.readSeen());
