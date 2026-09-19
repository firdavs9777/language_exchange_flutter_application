/// How many times a failed media upload may be retried, and what to say.
///
/// Extracted from create_moment.dart, where the audio retry was unbounded
/// MUTUAL RECURSION: the failure dialog awaited a retry, and a failed retry
/// called the dialog again from inside that await. Ten taps meant ten nested
/// dialog futures, none of which unwound until the user finally gave up — and
/// the message said "Upload failed again" on the tenth attempt exactly as it
/// did on the second.
library;

/// Attempts after the first upload has already failed.
///
/// Three, not unlimited. A transient failure clears within a retry or two; a
/// persistent one is a network or a server problem that tapping will not fix,
/// and offering an infinite button pretends otherwise.
const int kMaxUploadRetries = 3;

/// What to do after an upload attempt failed.
enum UploadRetryDecision {
  /// Offer the user another attempt.
  offerRetry,

  /// Out of attempts — say so plainly and stop offering.
  giveUp,
}

UploadRetryDecision decideRetry({required int attemptsMade}) =>
    attemptsMade >= kMaxUploadRetries
    ? UploadRetryDecision.giveUp
    : UploadRetryDecision.offerRetry;

/// How many tries are left, never negative.
int retriesRemaining({required int attemptsMade}) {
  final left = kMaxUploadRetries - attemptsMade;
  return left < 0 ? 0 : left;
}

/// The message for a failed attempt.
///
/// Carries the attempt number rather than a fixed "again", because a user on
/// their third try being told the same thing as on their first is what makes
/// a retry button feel broken.
String uploadFailureMessage({
  required int attemptsMade,
  required String reason,
}) {
  final cleaned = reason.replaceFirst('Exception: ', '').trim();
  final detail = cleaned.isEmpty ? 'The upload did not complete.' : cleaned;

  if (decideRetry(attemptsMade: attemptsMade) == UploadRetryDecision.giveUp) {
    return "$detail\n\nThat's $attemptsMade attempts — it's likely the "
        'connection rather than the file. Your moment is already posted; you '
        'can add the voice note later by editing it.';
  }

  final left = retriesRemaining(attemptsMade: attemptsMade);
  return '$detail\n\n$left ${left == 1 ? 'try' : 'tries'} left.';
}
