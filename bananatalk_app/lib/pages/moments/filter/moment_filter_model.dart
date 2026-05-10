import 'package:bananatalk_app/utils/language_flags.dart';

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
  // Popular languages (shown first in filter)
  static const List<Map<String, String>> popularLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'ru', 'name': 'Russian'},
  ];

  // All supported languages (comprehensive list)
  static const List<Map<String, String>> allLanguages = [
    // Popular languages first
    {'code': 'en', 'name': 'English'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'ru', 'name': 'Russian'},
    // Additional languages (alphabetically)
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'bn', 'name': 'Bengali'},
    {'code': 'cs', 'name': 'Czech'},
    {'code': 'da', 'name': 'Danish'},
    {'code': 'nl', 'name': 'Dutch'},
    {'code': 'fi', 'name': 'Finnish'},
    {'code': 'el', 'name': 'Greek'},
    {'code': 'he', 'name': 'Hebrew'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'hu', 'name': 'Hungarian'},
    {'code': 'id', 'name': 'Indonesian'},
    {'code': 'ms', 'name': 'Malay'},
    {'code': 'no', 'name': 'Norwegian'},
    {'code': 'fa', 'name': 'Persian'},
    {'code': 'pl', 'name': 'Polish'},
    {'code': 'ro', 'name': 'Romanian'},
    {'code': 'sv', 'name': 'Swedish'},
    {'code': 'th', 'name': 'Thai'},
    {'code': 'tr', 'name': 'Turkish'},
    {'code': 'uk', 'name': 'Ukrainian'},
    {'code': 'ur', 'name': 'Urdu'},
    {'code': 'vi', 'name': 'Vietnamese'},
  ];

  // Get flag for a language code using LanguageFlags utility
  static String getFlag(String code) => LanguageFlags.getFlag(code);

  // Legacy getter for backward compatibility
  static List<Map<String, String>> get languages => allLanguages.map((lang) {
        return {
          'code': lang['code']!,
          'name': lang['name']!,
          'flag': LanguageFlags.getFlag(lang['code']!),
        };
      }).toList();

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

