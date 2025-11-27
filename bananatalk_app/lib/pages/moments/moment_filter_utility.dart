import 'dart:math';

import 'package:bananatalk_app/pages/moments/moment_filter_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

class MomentFilterUtility {
  static List<Moments> filterMoments(
    List<Moments> moments,
    MomentFilter filter,
  ) {
    final filtered = moments.where((moment) {
      if (filter.languages.isNotEmpty) {
        final language = moment.language.toLowerCase();
        final matchesLanguage = filter.languages
            .any((lang) => language == lang.toLowerCase());
        if (!matchesLanguage) return false;
      }

      if (filter.categories.isNotEmpty) {
        final category = moment.category.toLowerCase();
        final matchesCategory = filter.categories
            .any((cat) => category == cat.toLowerCase());
        if (!matchesCategory) return false;
      }

      if (filter.moods.isNotEmpty) {
        final mood = moment.mood.toLowerCase();
        final matchesMood =
            filter.moods.any((m) => mood == m.toLowerCase());
        if (!matchesMood) return false;
      }

      if (!_matchesDateFilter(moment.createdAt, filter.dateFilter)) {
        return false;
      }

      return true;
    }).toList();

    switch (filter.sortBy) {
      case 'popular':
        filtered.sort(
          (a, b) => b.likeCount.compareTo(a.likeCount),
        );
        break;
      case 'trending':
        filtered.sort(
          (a, b) =>
              _calculateTrendingScore(b).compareTo(_calculateTrendingScore(a)),
        );
        break;
      case 'recent':
      default:
        filtered.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
        break;
    }

    return filtered;
  }

  static bool _matchesDateFilter(
    DateTime createdAt,
    DateFilterType type,
  ) {
    final now = DateTime.now();
    switch (type) {
      case DateFilterType.today:
        final startOfDay = DateTime(now.year, now.month, now.day);
        return createdAt.isAfter(startOfDay);
      case DateFilterType.thisWeek:
        final startOfWeek =
            now.subtract(Duration(days: now.weekday - 1));
        final normalized =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return createdAt.isAfter(normalized);
      case DateFilterType.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return createdAt.isAfter(startOfMonth);
      case DateFilterType.allTime:
      default:
        return true;
    }
  }

  static double _calculateTrendingScore(Moments moment) {
    final engagementScore =
        (moment.likeCount * 2) + (moment.commentCount * 3);
    final hours = max(
      1,
      DateTime.now().difference(moment.createdAt).inHours,
    );

    double recencyMultiplier;
    if (hours <= 24) {
      recencyMultiplier = 2.0;
    } else if (hours <= 72) {
      recencyMultiplier = 1.5;
    } else {
      recencyMultiplier = 1.0;
    }

    return engagementScore * recencyMultiplier;
  }

  static List<Moments> searchMoments(
    List<Moments> moments,
    String query,
  ) {
    if (query.isEmpty) return moments;
    final lowerQuery = query.toLowerCase();

    return moments.where((moment) {
      final userMatches =
          moment.user.name.toLowerCase().contains(lowerQuery);
      final titleMatches =
          moment.title.toLowerCase().contains(lowerQuery);
      final descriptionMatches =
          moment.description.toLowerCase().contains(lowerQuery);
      final tagMatches = moment.tags
          .whereType<String>()
          .any((tag) => tag.toLowerCase().contains(lowerQuery));

      return userMatches || titleMatches || descriptionMatches || tagMatches;
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

