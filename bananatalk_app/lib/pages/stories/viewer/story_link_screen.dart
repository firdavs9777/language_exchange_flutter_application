import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart'
    show userProvider;
import 'package:bananatalk_app/services/stories_service.dart';

typedef StoryLoader = Future<SingleStoryResponse> Function({
  required String storyId,
});

/// `/story/:storyId`, opened from a shared story link
/// (`https://banatalk.com/story/<id>`, links#1).
///
/// Loads that one story and plays it in the normal viewer. The server
/// refuses expired, deleted, blocked and privacy-restricted stories, and
/// all of those show "Content not available" rather than an empty viewer.
class StoryLinkScreen extends ConsumerStatefulWidget {
  const StoryLinkScreen({
    super.key,
    required this.storyId,
    this.load = StoriesService.getStory,
  });

  final String storyId;
  final StoryLoader load;

  @override
  ConsumerState<StoryLinkScreen> createState() => _StoryLinkScreenState();
}

class _StoryLinkScreenState extends ConsumerState<StoryLinkScreen> {
  late final Future<SingleStoryResponse> _future =
      widget.load(storyId: widget.storyId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SingleStoryResponse>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final story = snap.data?.data;
        if (snap.hasError ||
            snap.data?.success != true ||
            story == null ||
            story.user.id.isEmpty) {
          return const _StoryUnavailable();
        }
        final me = ref.read(userProvider).valueOrNull?.id;
        return StoryViewerScreen(
          stories: [story],
          storiesUser: story.user,
          isOwnStory: me != null && me == story.user.id,
        );
      },
    );
  }
}

class _StoryUnavailable extends StatelessWidget {
  const _StoryUnavailable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hide_source_rounded, size: 56),
            const SizedBox(height: 12),
            Text(
              l10n.contentNotAvailable,
              key: const Key('story-link-unavailable'),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.goBack),
            ),
          ],
        ),
      ),
    );
  }
}
