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

  /// Predefined topics for language exchange
  static List<Topic> get defaultTopics => [
    // Food & Drink
    const Topic(id: 'eating_out', name: 'Eating Out', icon: '🍽️', category: 'food_drink'),
    const Topic(id: 'cooking', name: 'Cooking', icon: '🍳', category: 'food_drink'),
    const Topic(id: 'drinking', name: 'Drinking', icon: '🍻', category: 'food_drink'),
    const Topic(id: 'coffee', name: 'Coffee', icon: '☕', category: 'food_drink'),
    const Topic(id: 'tea', name: 'Tea', icon: '🍵', category: 'food_drink'),
    const Topic(id: 'baking', name: 'Baking', icon: '🧁', category: 'food_drink'),
    const Topic(id: 'wine', name: 'Wine', icon: '🍷', category: 'food_drink'),
    const Topic(id: 'vegetarian', name: 'Vegetarian', icon: '🥗', category: 'food_drink'),
    const Topic(id: 'desserts', name: 'Desserts', icon: '🍰', category: 'food_drink'),
    const Topic(id: 'street_food', name: 'Street Food', icon: '🌮', category: 'food_drink'),

    // Travel & Adventure
    const Topic(id: 'travel', name: 'Travel', icon: '✈️', category: 'travel'),
    const Topic(id: 'backpacking', name: 'Backpacking', icon: '🎒', category: 'travel'),
    const Topic(id: 'road_trips', name: 'Road Trips', icon: '🚗', category: 'travel'),
    const Topic(id: 'beaches', name: 'Beaches', icon: '🏖️', category: 'travel'),
    const Topic(id: 'mountains', name: 'Mountains', icon: '🏔️', category: 'travel'),
    const Topic(id: 'camping', name: 'Camping', icon: '⛺', category: 'travel'),
    const Topic(id: 'city_trips', name: 'City Trips', icon: '🏙️', category: 'travel'),
    const Topic(id: 'culture_travel', name: 'Cultural Travel', icon: '🏛️', category: 'travel'),

    // Sports & Fitness
    const Topic(id: 'gym', name: 'Gym', icon: '🏋️', category: 'sports'),
    const Topic(id: 'running', name: 'Running', icon: '🏃', category: 'sports'),
    const Topic(id: 'yoga', name: 'Yoga', icon: '🧘', category: 'sports'),
    const Topic(id: 'swimming', name: 'Swimming', icon: '🏊', category: 'sports'),
    const Topic(id: 'football', name: 'Football', icon: '⚽', category: 'sports'),
    const Topic(id: 'basketball', name: 'Basketball', icon: '🏀', category: 'sports'),
    const Topic(id: 'tennis', name: 'Tennis', icon: '🎾', category: 'sports'),
    const Topic(id: 'hiking', name: 'Hiking', icon: '🥾', category: 'sports'),
    const Topic(id: 'cycling', name: 'Cycling', icon: '🚴', category: 'sports'),
    const Topic(id: 'dancing', name: 'Dancing', icon: '💃', category: 'sports'),
    const Topic(id: 'martial_arts', name: 'Martial Arts', icon: '🥋', category: 'sports'),
    const Topic(id: 'skiing', name: 'Skiing', icon: '⛷️', category: 'sports'),

    // Entertainment
    const Topic(id: 'movies', name: 'Movies', icon: '🎬', category: 'entertainment'),
    const Topic(id: 'tv_shows', name: 'TV Shows', icon: '📺', category: 'entertainment'),
    const Topic(id: 'music', name: 'Music', icon: '🎵', category: 'entertainment'),
    const Topic(id: 'concerts', name: 'Concerts', icon: '🎤', category: 'entertainment'),
    const Topic(id: 'gaming', name: 'Gaming', icon: '🎮', category: 'entertainment'),
    const Topic(id: 'anime', name: 'Anime', icon: '🎌', category: 'entertainment'),
    const Topic(id: 'manga', name: 'Manga', icon: '📖', category: 'entertainment'),
    const Topic(id: 'kpop', name: 'K-Pop', icon: '🇰🇷', category: 'entertainment'),
    const Topic(id: 'kdrama', name: 'K-Drama', icon: '🎭', category: 'entertainment'),
    const Topic(id: 'netflix', name: 'Netflix', icon: '🍿', category: 'entertainment'),
    const Topic(id: 'podcasts', name: 'Podcasts', icon: '🎧', category: 'entertainment'),
    const Topic(id: 'comedy', name: 'Comedy', icon: '😂', category: 'entertainment'),

    // Arts & Culture
    const Topic(id: 'art', name: 'Art', icon: '🎨', category: 'arts'),
    const Topic(id: 'photography', name: 'Photography', icon: '📷', category: 'arts'),
    const Topic(id: 'books', name: 'Books', icon: '📚', category: 'arts'),
    const Topic(id: 'writing', name: 'Writing', icon: '✍️', category: 'arts'),
    const Topic(id: 'poetry', name: 'Poetry', icon: '📝', category: 'arts'),
    const Topic(id: 'museums', name: 'Museums', icon: '🏛️', category: 'arts'),
    const Topic(id: 'theater', name: 'Theater', icon: '🎭', category: 'arts'),
    const Topic(id: 'history', name: 'History', icon: '📜', category: 'arts'),
    const Topic(id: 'design', name: 'Design', icon: '🖌️', category: 'arts'),

    // Lifestyle
    const Topic(id: 'fashion', name: 'Fashion', icon: '👗', category: 'lifestyle'),
    const Topic(id: 'beauty', name: 'Beauty', icon: '💄', category: 'lifestyle'),
    const Topic(id: 'shopping', name: 'Shopping', icon: '🛍️', category: 'lifestyle'),
    const Topic(id: 'skincare', name: 'Skincare', icon: '🧴', category: 'lifestyle'),
    const Topic(id: 'home_decor', name: 'Home Decor', icon: '🏠', category: 'lifestyle'),
    const Topic(id: 'gardening', name: 'Gardening', icon: '🌱', category: 'lifestyle'),
    const Topic(id: 'diy', name: 'DIY', icon: '🔨', category: 'lifestyle'),
    const Topic(id: 'minimalism', name: 'Minimalism', icon: '✨', category: 'lifestyle'),

    // Pets & Nature
    const Topic(id: 'dogs', name: 'Dogs', icon: '🐕', category: 'pets_nature'),
    const Topic(id: 'cats', name: 'Cats', icon: '🐈', category: 'pets_nature'),
    const Topic(id: 'pets', name: 'Pets', icon: '🐾', category: 'pets_nature'),
    const Topic(id: 'nature', name: 'Nature', icon: '🌿', category: 'pets_nature'),
    const Topic(id: 'animals', name: 'Animals', icon: '🦁', category: 'pets_nature'),
    const Topic(id: 'birds', name: 'Birds', icon: '🐦', category: 'pets_nature'),
    const Topic(id: 'aquarium', name: 'Aquarium', icon: '🐠', category: 'pets_nature'),

    // Learning & Career
    const Topic(id: 'language_exchange', name: 'Language Exchange', icon: '🗣️', category: 'learning'),
    const Topic(id: 'language_tips', name: 'Language Tips', icon: '💡', category: 'learning'),
    const Topic(id: 'study_abroad', name: 'Study Abroad', icon: '🎓', category: 'learning'),
    const Topic(id: 'career', name: 'Career', icon: '💼', category: 'learning'),
    const Topic(id: 'technology', name: 'Technology', icon: '💻', category: 'learning'),
    const Topic(id: 'programming', name: 'Programming', icon: '👨‍💻', category: 'learning'),
    const Topic(id: 'business', name: 'Business', icon: '📊', category: 'learning'),
    const Topic(id: 'startups', name: 'Startups', icon: '🚀', category: 'learning'),
    const Topic(id: 'science', name: 'Science', icon: '🔬', category: 'learning'),
    const Topic(id: 'finance', name: 'Finance', icon: '💰', category: 'learning'),

    // Social & Lifestyle
    const Topic(id: 'daily_life', name: 'Daily Life', icon: '☀️', category: 'social'),
    const Topic(id: 'making_friends', name: 'Making Friends', icon: '🤝', category: 'social'),
    const Topic(id: 'relationships', name: 'Relationships', icon: '💕', category: 'social'),
    const Topic(id: 'family', name: 'Family', icon: '👨‍👩‍👧‍👦', category: 'social'),
    const Topic(id: 'parenting', name: 'Parenting', icon: '👶', category: 'social'),
    const Topic(id: 'news', name: 'News & Events', icon: '📰', category: 'social'),
    const Topic(id: 'politics', name: 'Politics', icon: '🏛️', category: 'social'),
    const Topic(id: 'volunteering', name: 'Volunteering', icon: '🙋', category: 'social'),
    const Topic(id: 'nightlife', name: 'Nightlife', icon: '🌃', category: 'social'),

    // Health & Wellness
    const Topic(id: 'mental_health', name: 'Mental Health', icon: '🧠', category: 'health'),
    const Topic(id: 'meditation', name: 'Meditation', icon: '🧘‍♂️', category: 'health'),
    const Topic(id: 'nutrition', name: 'Nutrition', icon: '🥑', category: 'health'),
    const Topic(id: 'wellness', name: 'Wellness', icon: '💆', category: 'health'),
    const Topic(id: 'self_improvement', name: 'Self Improvement', icon: '📈', category: 'health'),
    const Topic(id: 'sleep', name: 'Sleep', icon: '😴', category: 'health'),

    // Music & Instruments
    const Topic(id: 'guitar', name: 'Guitar', icon: '🎸', category: 'music'),
    const Topic(id: 'piano', name: 'Piano', icon: '🎹', category: 'music'),
    const Topic(id: 'singing', name: 'Singing', icon: '🎤', category: 'music'),
    const Topic(id: 'djing', name: 'DJing', icon: '🎧', category: 'music'),
    const Topic(id: 'classical_music', name: 'Classical Music', icon: '🎻', category: 'music'),
    const Topic(id: 'rock', name: 'Rock', icon: '🤘', category: 'music'),
    const Topic(id: 'hiphop', name: 'Hip Hop', icon: '🎤', category: 'music'),
    const Topic(id: 'electronic', name: 'Electronic', icon: '🎛️', category: 'music'),
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
    'music',
  ];

  static String getCategoryLabel(String category) {
    switch (category) {
      case 'food_drink':
        return 'Food & Drink';
      case 'travel':
        return 'Travel & Adventure';
      case 'sports':
        return 'Sports & Fitness';
      case 'entertainment':
        return 'Entertainment';
      case 'arts':
        return 'Arts & Culture';
      case 'lifestyle':
        return 'Lifestyle';
      case 'pets_nature':
        return 'Pets & Nature';
      case 'learning':
        return 'Learning & Career';
      case 'social':
        return 'Social';
      case 'health':
        return 'Health & Wellness';
      case 'music':
        return 'Music';
      default:
        return category;
    }
  }
}
