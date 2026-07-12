import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/shimmer_loading.dart';
import 'package:bananatalk_app/pages/stories/widgets/stories_snackbar.dart';
import 'package:bananatalk_app/pages/community/single/single_community_screen.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// One row in the viewers list: a viewer, optionally merged with the emoji
/// they reacted with (if any).
class _ViewerRow {
  final String userId;
  final Community? user;
  final DateTime viewedAt;
  final String? emoji;

  const _ViewerRow({
    required this.userId,
    required this.user,
    required this.viewedAt,
    this.emoji,
  });
}

/// Draggable bottom sheet showing who viewed an own story, with reaction
/// emojis merged in for viewers who also reacted.
///
/// Call [StoryViewersSheet.show] rather than constructing this widget
/// directly — it wires up `showModalBottomSheet` with the right shape/theme
/// and resolves gracefully on network errors.
class StoryViewersSheet extends StatefulWidget {
  final String storyId;
  final int initialViewCount;

  const StoryViewersSheet({
    super.key,
    required this.storyId,
    required this.initialViewCount,
  });

  /// Shows the sheet modally. Returns after the sheet is dismissed so the
  /// caller can resume story playback.
  static Future<void> show(
    BuildContext context, {
    required String storyId,
    required int initialViewCount,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryViewersSheet(
        storyId: storyId,
        initialViewCount: initialViewCount,
      ),
    );
  }

  @override
  State<StoryViewersSheet> createState() => _StoryViewersSheetState();
}

class _StoryViewersSheetState extends State<StoryViewersSheet> {
  bool _loading = true;
  bool _hasError = false;
  int _viewCount = 0;
  List<_ViewerRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _viewCount = widget.initialViewCount;
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        StoriesService.getStoryViewers(storyId: widget.storyId),
        StoriesService.getStoryReactions(storyId: widget.storyId),
      ]);

      final viewersResult = results[0];
      final reactionsResult = results[1];

      if (viewersResult['success'] != true) {
        if (mounted) {
          setState(() {
            _loading = false;
            _hasError = true;
          });
          _closeWithError();
        }
        return;
      }

      final views = (viewersResult['views'] as List?) ?? [];
      final reactions = reactionsResult['success'] == true
          ? ((reactionsResult['reactions'] as List?) ?? [])
          : [];

      // Merge reactions by user id so a viewer who also reacted shows their emoji.
      final emojiByUserId = <String, String>{};
      for (final r in reactions) {
        if (r is StoryReaction && r.userId.isNotEmpty) {
          emojiByUserId[r.userId] = r.emoji;
        }
      }

      final rows = views.whereType<StoryView>().map((v) {
        return _ViewerRow(
          userId: v.userId,
          user: v.user,
          viewedAt: v.viewedAt,
          emoji: emojiByUserId[v.userId],
        );
      }).toList()
        ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));

      if (mounted) {
        setState(() {
          _rows = rows;
          _viewCount = (viewersResult['viewCount'] as int?) ?? _viewCount;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
        _closeWithError();
      }
    }
  }

  void _closeWithError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showStoriesSnackBar(
        context,
        message: 'Failed to load viewers',
        type: StoriesSnackBarType.error,
      );
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 20, color: colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Text(
                      'Seen by $_viewCount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              Expanded(
                child: _buildBody(scrollController, colorScheme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController, ColorScheme colorScheme) {
    if (_loading) {
      return ListView.builder(
        controller: scrollController,
        itemCount: 6,
        itemBuilder: (context, index) => _buildShimmerRow(colorScheme),
      );
    }

    if (_hasError) {
      // Sheet is being popped via _closeWithError; show a blank placeholder
      // in the meantime to avoid a flash of "No views yet".
      return const SizedBox.shrink();
    }

    if (_rows.isEmpty) {
      return ListView(
        controller: scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'No views yet',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: _rows.length,
      itemBuilder: (context, index) => _buildViewerRow(_rows[index], colorScheme),
    );
  }

  Widget _buildShimmerRow(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ShimmerSkeleton.circle(radius: 20),
          const SizedBox(width: 12),
          Expanded(child: ShimmerSkeleton.line(width: 120)),
          const SizedBox(width: 8),
          ShimmerSkeleton.line(width: 32, height: 12),
        ],
      ),
    );
  }

  Widget _buildViewerRow(_ViewerRow row, ColorScheme colorScheme) {
    final user = row.user;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'User';
    final userImage = user != null
        ? (user.imageUrls.isNotEmpty
            ? user.imageUrls.first
            : (user.images.isNotEmpty ? user.images.first : null))
        : null;

    return ListTile(
      onTap: user == null
          ? null
          : () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SingleCommunity(community: user),
                ),
              );
            },
      leading: CachedCircleAvatar(
        imageUrl: userImage,
        radius: 20,
        errorWidget: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?'),
      ),
      title: Text(
        userName,
        style: TextStyle(color: colorScheme.onSurface),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (row.emoji != null) ...[
            Text(row.emoji!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
          ],
          Text(
            _formatRelativeTime(row.viewedAt),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
}
