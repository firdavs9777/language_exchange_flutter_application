import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Topic Model for community interests
class Topic {
  final String id;
  final String name;
  final String icon;
  final String category;
  final int userCount;

  const Topic({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    this.userCount = 0,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      userCount: json['userCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'category': category,
      'userCount': userCount,
    };
  }

  /// [name] in the app language for the predefined topics; a topic the
  /// server added (unknown id) keeps its own [name].
  String localizedName(AppLocalizations l10n) => switch (id) {
      'cooking' => l10n.topicNameCooking,
      'coffee' => l10n.topicNameCoffee,
      'eating_out' => l10n.topicNameEatingOut,
      'baking' => l10n.topicNameBaking,
      'drinking' => l10n.topicNameDrinking,
      'street_food' => l10n.topicNameStreetFood,
      'travel' => l10n.topicNameTravel,
      'backpacking' => l10n.topicNameBackpacking,
      'beaches' => l10n.topicNameBeaches,
      'mountains' => l10n.topicNameMountains,
      'camping' => l10n.topicNameCamping,
      'gym' => l10n.topicNameGym,
      'running' => l10n.topicNameRunning,
      'yoga' => l10n.topicNameYoga,
      'football' => l10n.topicNameFootball,
      'basketball' => l10n.topicNameBasketball,
      'hiking' => l10n.topicNameHiking,
      'cycling' => l10n.topicNameCycling,
      'dancing' => l10n.topicNameDancing,
      'swimming' => l10n.topicNameSwimming,
      'movies' => l10n.topicNameMovies,
      'tv_shows' => l10n.topicNameTvShows,
      'music' => l10n.topicNameMusic,
      'gaming' => l10n.topicNameGaming,
      'anime' => l10n.topicNameAnime,
      'kpop' => l10n.topicNameKpop,
      'kdrama' => l10n.topicNameKdrama,
      'podcasts' => l10n.topicNamePodcasts,
      'art' => l10n.topicNameArt,
      'photography' => l10n.topicNamePhotography,
      'books' => l10n.topicNameBooks,
      'writing' => l10n.topicNameWriting,
      'history' => l10n.topicNameHistory,
      'design' => l10n.topicNameDesign,
      'fashion' => l10n.topicNameFashion,
      'beauty' => l10n.topicNameBeauty,
      'shopping' => l10n.topicNameShopping,
      'gardening' => l10n.topicNameGardening,
      'diy' => l10n.topicNameDiy,
      'dogs' => l10n.topicNameDogs,
      'cats' => l10n.topicNameCats,
      'nature' => l10n.topicNameNature,
      'animals' => l10n.topicNameAnimals,
      'language_exchange' => l10n.topicNameLanguageExchange,
      'study_abroad' => l10n.topicNameStudyAbroad,
      'technology' => l10n.topicNameTechnology,
      'programming' => l10n.topicNameProgramming,
      'business' => l10n.topicNameBusiness,
      'science' => l10n.topicNameScience,
      'daily_life' => l10n.topicNameDailyLife,
      'making_friends' => l10n.topicNameMakingFriends,
      'relationships' => l10n.topicNameRelationships,
      'family' => l10n.topicNameFamily,
      'nightlife' => l10n.topicNameNightlife,
      'mental_health' => l10n.topicNameMentalHealth,
      'meditation' => l10n.topicNameMeditation,
      'nutrition' => l10n.topicNameNutrition,
      'self_improvement' => l10n.topicNameSelfImprovement,
      _ => name,
    };

  /// Predefined topics for language exchange
  static List<Topic> get defaultTopics => [
    // Food & Drink
    const Topic(id: 'cooking', name: 'Cooking', icon: '🍳', category: 'food_drink'),
    const Topic(id: 'coffee', name: 'Coffee & Tea', icon: '☕', category: 'food_drink'),
    const Topic(id: 'eating_out', name: 'Eating Out', icon: '🍽️', category: 'food_drink'),
    const Topic(id: 'baking', name: 'Baking', icon: '🧁', category: 'food_drink'),
    const Topic(id: 'drinking', name: 'Drinking', icon: '🍻', category: 'food_drink'),
    const Topic(id: 'street_food', name: 'Street Food', icon: '🌮', category: 'food_drink'),

    // Travel & Adventure
    const Topic(id: 'travel', name: 'Travel', icon: '✈️', category: 'travel'),
    const Topic(id: 'backpacking', name: 'Backpacking', icon: '🎒', category: 'travel'),
    const Topic(id: 'beaches', name: 'Beaches', icon: '🏖️', category: 'travel'),
    const Topic(id: 'mountains', name: 'Mountains', icon: '🏔️', category: 'travel'),
    const Topic(id: 'camping', name: 'Camping', icon: '⛺', category: 'travel'),

    // Sports & Fitness
    const Topic(id: 'gym', name: 'Gym', icon: '🏋️', category: 'sports'),
    const Topic(id: 'running', name: 'Running', icon: '🏃', category: 'sports'),
    const Topic(id: 'yoga', name: 'Yoga', icon: '🧘', category: 'sports'),
    const Topic(id: 'football', name: 'Football', icon: '⚽', category: 'sports'),
    const Topic(id: 'basketball', name: 'Basketball', icon: '🏀', category: 'sports'),
    const Topic(id: 'hiking', name: 'Hiking', icon: '🥾', category: 'sports'),
    const Topic(id: 'cycling', name: 'Cycling', icon: '🚴', category: 'sports'),
    const Topic(id: 'dancing', name: 'Dancing', icon: '💃', category: 'sports'),
    const Topic(id: 'swimming', name: 'Swimming', icon: '🏊', category: 'sports'),

    // Entertainment & Music
    const Topic(id: 'movies', name: 'Movies', icon: '🎬', category: 'entertainment'),
    const Topic(id: 'tv_shows', name: 'TV Shows', icon: '📺', category: 'entertainment'),
    const Topic(id: 'music', name: 'Music', icon: '🎵', category: 'entertainment'),
    const Topic(id: 'gaming', name: 'Gaming', icon: '🎮', category: 'entertainment'),
    const Topic(id: 'anime', name: 'Anime & Manga', icon: '🎌', category: 'entertainment'),
    const Topic(id: 'kpop', name: 'K-Pop', icon: '🇰🇷', category: 'entertainment'),
    const Topic(id: 'kdrama', name: 'K-Drama', icon: '🎭', category: 'entertainment'),
    const Topic(id: 'podcasts', name: 'Podcasts', icon: '🎧', category: 'entertainment'),

    // Arts & Culture
    const Topic(id: 'art', name: 'Art', icon: '🎨', category: 'arts'),
    const Topic(id: 'photography', name: 'Photography', icon: '📷', category: 'arts'),
    const Topic(id: 'books', name: 'Books', icon: '📚', category: 'arts'),
    const Topic(id: 'writing', name: 'Writing', icon: '✍️', category: 'arts'),
    const Topic(id: 'history', name: 'History', icon: '📜', category: 'arts'),
    const Topic(id: 'design', name: 'Design', icon: '🖌️', category: 'arts'),

    // Lifestyle
    const Topic(id: 'fashion', name: 'Fashion', icon: '👗', category: 'lifestyle'),
    const Topic(id: 'beauty', name: 'Beauty & Skincare', icon: '💄', category: 'lifestyle'),
    const Topic(id: 'shopping', name: 'Shopping', icon: '🛍️', category: 'lifestyle'),
    const Topic(id: 'gardening', name: 'Gardening', icon: '🌱', category: 'lifestyle'),
    const Topic(id: 'diy', name: 'DIY', icon: '🔨', category: 'lifestyle'),

    // Pets & Nature
    const Topic(id: 'dogs', name: 'Dogs', icon: '🐕', category: 'pets_nature'),
    const Topic(id: 'cats', name: 'Cats', icon: '🐈', category: 'pets_nature'),
    const Topic(id: 'nature', name: 'Nature', icon: '🌿', category: 'pets_nature'),
    const Topic(id: 'animals', name: 'Animals', icon: '🦁', category: 'pets_nature'),

    // Learning & Career
    const Topic(id: 'language_exchange', name: 'Language Exchange', icon: '🗣️', category: 'learning'),
    const Topic(id: 'study_abroad', name: 'Study Abroad', icon: '🎓', category: 'learning'),
    const Topic(id: 'technology', name: 'Technology', icon: '💻', category: 'learning'),
    const Topic(id: 'programming', name: 'Programming', icon: '👨‍💻', category: 'learning'),
    const Topic(id: 'business', name: 'Business', icon: '📊', category: 'learning'),
    const Topic(id: 'science', name: 'Science', icon: '🔬', category: 'learning'),

    // Social
    const Topic(id: 'daily_life', name: 'Daily Life', icon: '☀️', category: 'social'),
    const Topic(id: 'making_friends', name: 'Making Friends', icon: '🤝', category: 'social'),
    const Topic(id: 'relationships', name: 'Relationships', icon: '💕', category: 'social'),
    const Topic(id: 'family', name: 'Family', icon: '👨‍👩‍👧‍👦', category: 'social'),
    const Topic(id: 'nightlife', name: 'Nightlife', icon: '🌃', category: 'social'),

    // Health & Wellness
    const Topic(id: 'mental_health', name: 'Mental Health', icon: '🧠', category: 'health'),
    const Topic(id: 'meditation', name: 'Meditation', icon: '🧘‍♂️', category: 'health'),
    const Topic(id: 'nutrition', name: 'Nutrition', icon: '🥑', category: 'health'),
    const Topic(id: 'self_improvement', name: 'Self Improvement', icon: '📈', category: 'health'),
  ];

  static List<String> get categories => [
    'food_drink',
    'travel',
    'sports',
    'entertainment',
    'arts',
    'lifestyle',
    'pets_nature',
    'learning',
    'social',
    'health',
  ];

  static String getCategoryLabel(String category, AppLocalizations l10n) {
    return switch (category) {
      'food_drink' => l10n.topicCategoryFoodDrink,
      'travel' => l10n.topicCategoryTravel,
      'sports' => l10n.topicCategorySports,
      'entertainment' => l10n.topicCategoryEntertainment,
      'arts' => l10n.topicCategoryArts,
      'lifestyle' => l10n.topicCategoryLifestyle,
      'pets_nature' => l10n.topicCategoryPetsNature,
      'learning' => l10n.topicCategoryLearning,
      'social' => l10n.topicCategorySocial,
      'health' => l10n.topicCategoryHealth,
      _ => category,
    };
  }
}
