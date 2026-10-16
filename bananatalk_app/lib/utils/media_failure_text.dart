import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/video_compression_service.dart';
import 'package:bananatalk_app/utils/friendly_error.dart';

/// Localized text for the video processing dialog.
///
/// The service used to report progress as English sentences ("Checking
/// video duration...") which the composer showed as-is.
String videoProcessStageText(AppLocalizations l10n, VideoProcessStage stage) {
  switch (stage) {
    case VideoProcessStage.checkingDuration:
      return l10n.processingVideo;
    case VideoProcessStage.compressing:
      return l10n.chatCompressingVideo;
    case VideoProcessStage.ready:
      return l10n.momentVideoReady;
  }
}

/// Localized text for a failed [VideoProcessResult].
///
/// Replaces the service's English sentences ("Video is too long (95s).
/// Maximum is 60s (1 minutes).") which reached the snackbar untranslated.
String videoProcessFailureText(
  AppLocalizations l10n,
  VideoProcessResult result,
) {
  switch (result.failure) {
    case VideoProcessFailure.tooLong:
      final max = result.maxDurationSeconds;
      return max == null ? l10n.failedToProcessVideo : l10n.videoTooLongMax(max);
    case VideoProcessFailure.tooLarge:
      return l10n.chatVideoTooLarge;
    case VideoProcessFailure.notFound:
    case VideoProcessFailure.failed:
    case null:
      return l10n.failedToProcessVideo;
  }
}

/// Localized text for a failed story post.
///
/// Client-side refusals map to their own keys; anything else goes through
/// [friendlyErrorMessage] behind the "couldn't post story" prefix, so a
/// backend sentence is kept and a missing one leaves the prefix alone.
String storyPostFailureText(
  AppLocalizations l10n,
  SingleStoryResponse result,
) {
  switch (result.failure) {
    case StoryPostFailure.noMedia:
      return l10n.pleaseSelectMedia;
    case StoryPostFailure.noText:
      return l10n.pleaseEnterSomeText;
    case StoryPostFailure.videoTooLarge:
      return l10n.chatVideoTooLarge;
    case null:
      return friendlyErrorMessage(
        l10n,
        result.error,
        prefix: l10n.storyPostFailed,
      );
  }
}
