import 'package:bananatalk_app/pages/stories/archive/story_archive_screen.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewers_sheet.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `/story-insights/:storyId` (the story_did_well push). Shows the viewers
/// sheet's content (views, completions, sticker results) for one of the
/// user's own stories, which has expired by the time the push arrives. When
/// the views cannot be loaded the story archive takes its place, so the tap
/// never ends on an error screen. A signed-out visitor (no stored token) is
/// sent to the login screen.
class StoryInsightsScreen extends ConsumerStatefulWidget {
  const StoryInsightsScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<StoryInsightsScreen> createState() =>
      _StoryInsightsScreenState();
}

class _StoryInsightsScreenState extends ConsumerState<StoryInsightsScreen> {
  bool _showArchive = false;

  /// A stored token, not the in-memory flag: on a cold start from the push
  /// that flag only turns true after the token is validated over the network.
  late final Future<bool> _signedIn = _hasStoredToken();

  Future<bool> _hasStoredToken() async {
    if (ref.read(authServiceProvider).isLoggedIn) return true;
    try {
      final token = (await SharedPreferences.getInstance()).getString('token');
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _signedIn.then((signedIn) {
      if (!signedIn && mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showArchive) return const StoryArchiveScreen();
    return FutureBuilder<bool>(
      future: _signedIn,
      builder: (context, signedIn) {
        if (signedIn.data != true) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return Scaffold(
          appBar: AppBar(),
          body: StoryViewersSheet(
            storyId: widget.storyId,
            initialViewCount: 0,
            embedded: true,
            onLoadFailed: () {
              if (mounted) setState(() => _showArchive = true);
            },
          ),
        );
      },
    );
  }
}
