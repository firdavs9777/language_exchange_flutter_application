import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';

/// Opens the story viewer for a single user's avatar tap (from the
/// community list widgets or the chat list) — used whenever
/// `hasActiveStory` lit the gradient ring around their avatar.
///
/// Fetches that user's active stories fresh (the ring can be stale by the
/// time of the tap — e.g. the story expired between the list load and the
/// tap, or the request is blocked); when there's nothing to show, [fallback]
/// runs instead (the original avatar tap behavior: open the profile /
/// conversation), so the tap never dead-ends.
class StoryViewerLauncher {
  StoryViewerLauncher._();

  /// Loading guard — prevents overlapping fetches if the avatar is tapped
  /// again before the first request resolves.
  static bool _isOpening = false;

  static Future<void> open(
    BuildContext context, {
    required String userId,
    required VoidCallback fallback,
    VoidCallback? onStoriesUpdated,
  }) async {
    if (_isOpening) return;
    _isOpening = true;
    try {
      final response = await StoriesService.getUserStories(userId: userId);
      if (!context.mounted) return;

      if (response.success && !response.blocked && response.data.isNotEmpty) {
        await Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return StoryViewerScreen(
                userStories: response.data,
                initialUserIndex: 0,
                onStoriesUpdated: onStoriesUpdated,
              );
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        // No active stories (expired/blocked race) — fall back to the
        // original tap behavior instead of dead-ending the tap.
        fallback();
      }
    } catch (_) {
      fallback();
    } finally {
      _isOpening = false;
    }
  }
}
