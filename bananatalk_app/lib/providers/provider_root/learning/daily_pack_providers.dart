import 'package:flutter/widgets.dart';
import 'package:bananatalk_app/main.dart' show languageProvider;
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/models/learning/weekly_report_model.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/services/study/study_hub_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The locale keys pack content is authored in — the same mapping the daily
/// drop uses. Traditional Chinese maps to zh-Hans deliberately: no Traditional
/// explanations exist, and Simplified is far closer for that reader than an
/// English explanation of the language they are trying to learn.
String packLocaleTag(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'ar';
    case 'zh':
      return 'zh-Hans';
    default:
      return 'en';
  }
}

/// Today's pack for the signed-in learner, in the app's locale. Watches
/// [languageProvider] so switching app language refetches the explanations
/// rather than leaving stale ones on screen.
final dailyPackProvider = FutureProvider<DailyPack>((ref) async {
  final locale = ref.watch(languageProvider);
  return LearningService.getDailyPack(locale: packLocaleTag(locale));
});

/// Per-skill mastery for the signed-in learner.
final masteryProvider = FutureProvider<MasterySummary>((ref) async {
  return LearningService.getMastery();
});

/// The learner's most recently finished week in the pack.
///
/// autoDispose so a failed load (or last week's numbers) is not kept for the
/// whole session: each opening of the report fetches afresh.
final weeklyReportProvider = FutureProvider.autoDispose<WeeklyReport>((ref) async {
  return LearningService.getWeeklyReport();
});

/// What the AI Study tab paints from disk until the live answers arrive: the
/// signed-in user's snapshot, only when it was written today (device date).
/// Built once per session (user-scoped, so a sign-out starts it over), which
/// is what keeps the tab from repainting from disk after live data: nothing
/// invalidates it. Null when there is nothing usable; never throws.
final studyHubSnapshotProvider = FutureProvider<StudyHubSnapshot?>((ref) async {
  final cache = ref.read(studyHubCacheProvider);
  final userId = await cache.signedInUserId();
  if (userId == null) return null;
  final snapshot = await cache.read(userId);
  if (snapshot == null || snapshot.dateKey != cache.todayKey()) return null;
  return snapshot;
});
