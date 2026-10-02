import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

const reviewPromptPrefsKey = 'review_prompt_at';
const _minMessagesEach = 3;
const _cooldown = Duration(days: 60);

/// Pure decision, testable without plugins: a real two-sided conversation
/// (both sides sent at least [_minMessagesEach]) and no prompt in the last
/// 60 days.
bool shouldPromptForReview({
  required int myMessages,
  required int theirMessages,
  required DateTime? lastPromptedAt,
  required DateTime now,
}) {
  if (myMessages < _minMessagesEach || theirMessages < _minMessagesEach) {
    return false;
  }
  if (lastPromptedAt == null) return true;
  return now.difference(lastPromptedAt) >= _cooldown;
}

class ReviewPromptService {
  /// Never throws: a review dialog must not crash a chat screen.
  Future<void> maybePrompt({
    required int myMessages,
    required int theirMessages,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(reviewPromptPrefsKey);
      final now = DateTime.now();
      final ok = shouldPromptForReview(
        myMessages: myMessages,
        theirMessages: theirMessages,
        lastPromptedAt:
            lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
        now: now,
      );
      if (!ok) return;
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await review.requestReview();
      await prefs.setInt(reviewPromptPrefsKey, now.millisecondsSinceEpoch);
    } catch (_) {}
  }
}
