import 'package:flutter/widgets.dart';
import 'package:bananatalk_app/main.dart' show languageProvider;
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/services/learning_service.dart';
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
