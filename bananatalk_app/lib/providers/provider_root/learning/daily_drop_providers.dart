import 'package:flutter/widgets.dart';
import 'package:bananatalk_app/main.dart' show languageProvider;
import 'package:bananatalk_app/models/learning/daily_drop_model.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The locale keys the daily-drop content is authored in.
///
/// Every curated item carries `en`, `zh-Hans` and `ar` explanations, written
/// for the Chinese- and Arabic-native majority of the audience. Nothing was
/// sending a locale, so the server's `'en'` default meant none of them were
/// ever served. The server falls back to `en` for any key it does not know,
/// so an unmapped language degrades safely.
///
/// Traditional Chinese maps to `zh-Hans` deliberately: no Traditional
/// explanations exist, and Simplified is far closer for that reader than an
/// English explanation of the language they are trying to learn.
String dailyDropLocaleTag(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'ar';
    case 'zh':
      return 'zh-Hans';
    default:
      return 'en';
  }
}

/// Today's grammar + vocabulary for the signed-in user, in the app's locale.
///
/// Watches [languageProvider] so switching the app language re-fetches the
/// explanations rather than leaving stale ones on screen.
final dailyDropProvider = FutureProvider<DailyDropState>((ref) async {
  final locale = ref.watch(languageProvider);
  return LearningService.getDailyDrop(locale: dailyDropLocaleTag(locale));
});
