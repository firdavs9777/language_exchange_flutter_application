import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

class MomentFilterUtility {
  static List<Moments> filterMoments(
    List<Moments> moments,
    MomentFilter filter,
  ) {
    final filtered = moments.where((moment) {
      if (filter.languages.isNotEmpty) {
        final language = moment.language.toLowerCase();
        final matchesLanguage = filter.languages.any(
          (lang) => language == lang.toLowerCase(),
        );
        if (!matchesLanguage) return false;
      }

      if (filter.categories.isNotEmpty) {
        final category = moment.category.toLowerCase();
        final matchesCategory = filter.categories.any(
          (cat) => category == cat.toLowerCase(),
        );
        if (!matchesCategory) return false;
      }

      if (filter.moods.isNotEmpty) {
        final mood = moment.mood.toLowerCase();
        final matchesMood = filter.moods.any((m) => mood == m.toLowerCase());
        if (!matchesMood) return false;
      }

      if (!_matchesDateFilter(moment.createdAt, filter.dateFilter)) {
        return false;
      }

      return true;
    }).toList();

    // No client-side sort: each feed tab is already in its own order (For You
    // and Trending ranked by the server, Following newest first). Re-sorting
    // here by date overrode that ranking on every tab, and re-sorted the loaded
    // pages so posts jumped around as more pages arrived.
    return filtered;
  }

  static bool _matchesDateFilter(DateTime createdAt, DateFilterType type) {
    final now = DateTime.now();
    switch (type) {
      case DateFilterType.today:
        final startOfDay = DateTime(now.year, now.month, now.day);
        return createdAt.isAfter(startOfDay);
      case DateFilterType.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final normalized = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        return createdAt.isAfter(normalized);
      case DateFilterType.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return createdAt.isAfter(startOfMonth);
      case DateFilterType.allTime:
        return true;
    }
  }

  static List<Moments> searchMoments(List<Moments> moments, String query) {
    if (query.isEmpty) return moments;
    final lowerQuery = query.toLowerCase();

    return moments.where((moment) {
      final userMatches = moment.user.name.toLowerCase().contains(lowerQuery);
      final descriptionMatches = moment.description.toLowerCase().contains(
        lowerQuery,
      );
      final tagMatches = moment.tags.whereType<String>().any(
        (tag) => tag.toLowerCase().contains(lowerQuery),
      );

      return userMatches || descriptionMatches || tagMatches;
    }).toList();
  }

  static Map<String, int> getFilterCounts(List<Moments> moments) {
    final Map<String, int> counts = {};

    for (final lang in FilterOptions.languages) {
      final code = lang['code']!;
      counts['lang_$code'] = moments
          .where((moment) => moment.language.toLowerCase() == code)
          .length;
    }

    for (final category in FilterOptions.categories) {
      counts['cat_$category'] = moments
          .where((moment) => moment.category.toLowerCase() == category)
          .length;
    }

    return counts;
  }

  static List<String> getSuggestedLanguageFilters(String? languageToLearn) {
    if (languageToLearn == null || languageToLearn.isEmpty) {
      return const [];
    }

    final suggestions = <String>{
      languageToLearn.toLowerCase(),
      'en', // default to English for practice
    };

    return suggestions.toList();
  }
}
