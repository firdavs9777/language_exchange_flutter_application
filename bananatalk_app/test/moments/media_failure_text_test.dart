import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/services/video_compression_service.dart';
import 'package:bananatalk_app/utils/media_failure_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Video processing and story posting used to hand the screen English
/// sentences ("Video is too long (95s). Maximum is 60s (1 minutes).",
/// "Failed to create story (500)"), shown untranslated. They now carry a
/// typed reason that the screen localizes.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ko = lookupAppLocalizations(const Locale('ko'));

  group('videoProcessFailureText', () {
    test('too long names the limit, localized', () {
      final r = VideoProcessResult(
        success: false,
        failure: VideoProcessFailure.tooLong,
        maxDurationSeconds: 60,
        error: 'Video is too long (95s), max 60s',
      );
      expect(videoProcessFailureText(en, r), en.videoTooLongMax(60));
      expect(videoProcessFailureText(ko, r), ko.videoTooLongMax(60));
      expect(videoProcessFailureText(ko, r), isNot(contains('too long')));
    });

    test('too large and other failures use existing keys', () {
      expect(
        videoProcessFailureText(
          en,
          VideoProcessResult(success: false, failure: VideoProcessFailure.tooLarge),
        ),
        en.chatVideoTooLarge,
      );
      for (final f in [VideoProcessFailure.notFound, VideoProcessFailure.failed, null]) {
        final r = VideoProcessResult(
          success: false,
          failure: f,
          error: 'PlatformException(...)',
        );
        expect(videoProcessFailureText(en, r), en.failedToProcessVideo);
      }
    });

    test('every stage has localized text', () {
      for (final stage in VideoProcessStage.values) {
        expect(videoProcessStageText(ko, stage), isNotEmpty);
      }
    });
  });

  group('storyPostFailureText', () {
    test('client-side refusals map to their own keys', () {
      expect(
        storyPostFailureText(ko, SingleStoryResponse(success: false, failure: StoryPostFailure.noMedia)),
        ko.pleaseSelectMedia,
      );
      expect(
        storyPostFailureText(ko, SingleStoryResponse(success: false, failure: StoryPostFailure.noText)),
        ko.pleaseEnterSomeText,
      );
      expect(
        storyPostFailureText(ko, SingleStoryResponse(success: false, failure: StoryPostFailure.videoTooLarge)),
        ko.chatVideoTooLarge,
      );
    });

    test('no server sentence leaves the localized prefix alone', () {
      expect(
        storyPostFailureText(ko, SingleStoryResponse(success: false)),
        ko.storyPostFailed,
      );
    });

    test('a server sentence is kept behind the prefix', () {
      expect(
        storyPostFailureText(en, SingleStoryResponse(success: false, error: 'Daily story limit reached')),
        '${en.storyPostFailed}: Daily story limit reached',
      );
    });
  });

  group('StoriesService.serverErrorOf', () {
    test('returns the backend message', () {
      expect(
        StoriesService.serverErrorOf(http.Response('{"message":"Daily story limit reached"}', 429)),
        'Daily story limit reached',
      );
      expect(
        StoriesService.serverErrorOf(http.Response('{"error":"Bad privacy"}', 400)),
        'Bad privacy',
      );
    });

    test('returns null instead of an English "Failed to create story (500)"', () {
      expect(StoriesService.serverErrorOf(http.Response('<html>502</html>', 502)), isNull);
      expect(StoriesService.serverErrorOf(http.Response('{}', 500)), isNull);
      expect(StoriesService.serverErrorOf(http.Response('{"message":""}', 500)), isNull);
    });
  });
}
