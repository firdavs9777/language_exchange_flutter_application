import 'package:flutter/material.dart';

/// Defines the supported date filter options.
enum DateFilterType { allTime, today, thisWeek, thisMonth }

class MomentFilter {
  final List<String> languages;
  final List<String> categories;
  final List<String> moods;
  final String sortBy; // recent, popular, trending
  final DateFilterType dateFilter;

  const MomentFilter({
    this.languages = const [],
    this.categories = const [],
    this.moods = const [],
    this.sortBy = 'recent',
    this.dateFilter = DateFilterType.allTime,
  });

  bool get hasActiveFilters =>
      languages.isNotEmpty ||
      categories.isNotEmpty ||
      moods.isNotEmpty ||
      dateFilter != DateFilterType.allTime;

  int get activeFilterCount {
    int count = languages.length + categories.length + moods.length;
    if (dateFilter != DateFilterType.allTime) {
      count += 1;
    }
    return count;
  }

  MomentFilter copyWith({
    List<String>? languages,
    List<String>? categories,
    List<String>? moods,
    String? sortBy,
    DateFilterType? dateFilter,
  }) {
    return MomentFilter(
      languages: languages ?? this.languages,
      categories: categories ?? this.categories,
      moods: moods ?? this.moods,
      sortBy: sortBy ?? this.sortBy,
      dateFilter: dateFilter ?? this.dateFilter,
    );
  }

  MomentFilter clearAll() => const MomentFilter();

  Map<String, dynamic> toJson() => {
        'languages': languages,
        'categories': categories,
        'moods': moods,
        'sortBy': sortBy,
        'dateFilter': dateFilter.name,
      };

  factory MomentFilter.fromJson(Map<String, dynamic> json) {
    return MomentFilter(
      languages:
          (json['languages'] as List<dynamic>?)?.cast<String>() ?? const [],
      categories:
          (json['categories'] as List<dynamic>?)?.cast<String>() ?? const [],
      moods: (json['moods'] as List<dynamic>?)?.cast<String>() ?? const [],
      sortBy: json['sortBy'] as String? ?? 'recent',
      dateFilter:
          DateFilterType.values.firstWhere((type) => type.name == json['dateFilter'],
              orElse: () => DateFilterType.allTime),
    );
  }
}

class FilterOptions {
  static const List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ko', 'name': 'Korean', 'flag': '🇰🇷'},
    {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵'},
    {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'French', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Portuguese', 'flag': '🇵🇹'},
    {'code': 'ru', 'name': 'Russian', 'flag': '🇷🇺'},
    {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦'},
    {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳'},
    {'code': 'th', 'name': 'Thai', 'flag': '🇹🇭'},
    {'code': 'vi', 'name': 'Vietnamese', 'flag': '🇻🇳'},
    {'code': 'nl', 'name': 'Dutch', 'flag': '🇳🇱'},
    {'code': 'sv', 'name': 'Swedish', 'flag': '🇸🇪'},
  ];

  static const List<String> categories = [
    'language-learning',
    'travel',
    'daily-life',
    'food',
    'culture',
    'technology',
    'entertainment',
    'sports',
    'music',
    'books',
    'movies',
    'study',
    'work',
    'hobbies',
    'question',
    'general',
  ];

  static const Map<String, String> categoryIcons = {
    'language-learning': '📚',
    'travel': '✈️',
    'daily-life': '☀️',
    'food': '🍜',
    'culture': '🎎',
    'technology': '💻',
    'entertainment': '🎬',
    'sports': '⚽',
    'music': '🎵',
    'books': '📖',
    'movies': '🎥',
    'study': '✏️',
    'work': '💼',
    'hobbies': '🎨',
    'question': '❓',
    'general': '🌐',
  };

  static const Map<String, String> categoryLabels = {
    'language-learning': 'Language Learning',
    'travel': 'Travel',
    'daily-life': 'Daily Life',
    'food': 'Food',
    'culture': 'Culture',
    'technology': 'Technology',
    'entertainment': 'Entertainment',
    'sports': 'Sports',
    'music': 'Music',
    'books': 'Books',
    'movies': 'Movies',
    'study': 'Study',
    'work': 'Work',
    'hobbies': 'Hobbies',
    'question': 'Question',
    'general': 'General',
  };

  static const List<String> moods = [
    'happy',
    'excited',
    'sad',
    'love',
    'funny',
    'thoughtful',
    'cool',
    'tired',
    'motivated',
    'grateful',
  ];

  static const Map<String, String> moodEmojis = {
    'happy': '😊',
    'excited': '🤩',
    'sad': '😢',
    'love': '😍',
    'funny': '😂',
    'thoughtful': '🤔',
    'cool': '😎',
    'tired': '😴',
    'motivated': '💪',
    'grateful': '🙏',
  };

  static const List<Map<String, String>> sortOptions = [
    {'label': 'Most Recent', 'value': 'recent'},
    {'label': 'Most Popular', 'value': 'popular'},
    {'label': 'Trending', 'value': 'trending'},
  ];

  static const List<Map<String, dynamic>> dateFilters = [
    {'label': 'All Time', 'value': DateFilterType.allTime},
    {'label': 'Today', 'value': DateFilterType.today},
    {'label': 'This Week', 'value': DateFilterType.thisWeek},
    {'label': 'This Month', 'value': DateFilterType.thisMonth},
  ];
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

