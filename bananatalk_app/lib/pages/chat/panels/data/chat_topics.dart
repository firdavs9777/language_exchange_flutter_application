/// Static catalog of conversation-starter topics shown in the Topics tab
/// of the phrases panel. Mirrors HelloTalk's curated icebreaker bank.
///
/// v1: English-only. Other locales fall through to the English list until
/// localized catalogs land (planned per-locale ARB-driven list).
class ChatTopics {
  static const List<String> _all = [
    // Icebreakers / everyday
    "How's your day going? Working or chilling?",
    "What's the best part of your week so far?",
    "Long time no chatting — how have you been?",
    "What did you have for lunch today?",
    "What's the weather like where you are?",
    "Are you a morning person or a night owl?",
    "What was the last thing that made you laugh?",
    // Hobbies & lifestyle
    "What do you do to relax?",
    "Do you prefer coffee or tea?",
    "What's your favorite way to spend a weekend?",
    "Do you like cooking? What's your go-to dish?",
    "What kind of music do you listen to lately?",
    "What's the last show or movie you really enjoyed?",
    "Do you play any sports or games?",
    // Travel & culture
    "Where would you love to travel next?",
    "What's a place in your country a foreigner must visit?",
    "What's a local food I have to try if I visit?",
    "What's something tourists usually get wrong about your culture?",
    "Do you live in a big city or somewhere smaller?",
    "What's a holiday or festival you love?",
    // Learning & languages
    "Why did you start learning this language?",
    "What's the hardest part for you so far?",
    "How long have you been studying?",
    "Do you have a favorite word in your language?",
    "What helps you remember new vocabulary?",
    "Have you visited a country where this language is spoken?",
    // Self / values
    "Are you a confident person?",
    "Are older people more interested in art than younger people?",
    "Do you think you're more of an optimist or a pessimist?",
    "What is your first memory of your childhood?",
    "What's something you're proud of recently?",
    "What's a small habit that has made your life better?",
    "If you could learn any skill instantly, what would it be?",
    "What does a perfect day look like for you?",
  ];

  /// Returns a fresh sample of [count] topics, deterministic per [seed] so
  /// the same "Change" tap reproduces during state restoration. Use
  /// `DateTime.now().millisecondsSinceEpoch` as seed for a fresh shuffle.
  static List<String> sample({int count = 6, int seed = 0}) {
    final list = List<String>.from(_all);
    // Fisher-Yates with a seeded LCG so this stays pure (no Random import).
    var state = seed == 0 ? 0x9E3779B1 : seed;
    for (var i = list.length - 1; i > 0; i--) {
      state = (state * 1664525 + 1013904223) & 0xFFFFFFFF;
      final j = state % (i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list.take(count).toList();
  }
}
