/// How many times a failed media upload may be retried, and what to say.
///
/// Extracted from create_moment.dart, where the audio retry was unbounded
/// MUTUAL RECURSION: the failure dialog awaited a retry, and a failed retry
/// called the dialog again from inside that await. Ten taps meant ten nested
/// dialog futures, none of which unwound until the user finally gave up — and
/// the message said "Upload failed again" on the tenth attempt exactly as it
/// did on the second.
library;

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/create/moment_media_rules.dart';

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
String uploadFailureMessage(
  AppLocalizations l10n, {
  required int attemptsMade,
  required String reason,
}) {
  final cleaned = reason.replaceFirst('Exception: ', '').trim();
  final detail = cleaned.isEmpty ? l10n.momentUploadDidNotComplete : cleaned;

  if (decideRetry(attemptsMade: attemptsMade) == UploadRetryDecision.giveUp) {
    return '$detail\n\n${l10n.momentUploadGiveUp}';
  }

  final left = retriesRemaining(attemptsMade: attemptsMade);
  return '$detail\n\n${l10n.momentUploadTriesLeft(left)}';
}

/// What to do with a just-created moment whose media upload failed.
enum MediaFailureAction {
  /// Delete the moment, so the user can post the whole thing again without
  /// leaving a caption-only (or empty) half behind.
  rollBack,

  /// Keep the moment and offer to retry just the media onto it.
  keepAndOfferRetry,
}

/// Policy for a media upload that failed after the moment was created.
///
/// Photos and video are rolled back: the user's natural recovery is to tap
/// Post again, and keeping the caption-only half is exactly what turned that
/// tap into a duplicate. A voice note on a captioned moment keeps the post —
/// the voice-note dialog says so and retries onto the same moment, and the
/// screen closes after it, so there is no second Post. A voice note that is
/// the whole post (no caption) is rolled back, or an empty moment would stay
/// in the feed.
MediaFailureAction afterMediaUploadFailed({
  required MomentMediaKind kind,
  required bool hasCaption,
}) {
  if (kind == MomentMediaKind.audio && hasCaption) {
    return MediaFailureAction.keepAndOfferRetry;
  }
  return MediaFailureAction.rollBack;
}
