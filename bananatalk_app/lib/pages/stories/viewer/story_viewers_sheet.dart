import 'package:bananatalk_app/l10n/app_localizations.dart';
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
  final bool completed;

  const _ViewerRow({
    required this.userId,
    required this.user,
    required this.viewedAt,
    this.emoji,
    this.completed = false,
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

  /// Hosts that show the sheet's content outside a modal (the story-insights
  /// screen) pass this to handle a failed load themselves; without it the
  /// sheet shows the error snackbar and pops itself.
  final VoidCallback? onLoadFailed;

  const StoryViewersSheet({
    super.key,
    required this.storyId,
    required this.initialViewCount,
    this.onLoadFailed,
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
  StoryViewsSummary? _summary;

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
          completed: v.completed,
        );
      }).toList()
        ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));

      if (mounted) {
        setState(() {
          _rows = rows;
          _summary = viewersResult['summary'] as StoryViewsSummary?;
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
    final handler = widget.onLoadFailed;
    if (handler != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) handler();
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showStoriesSnackBar(
        context,
        message: AppLocalizations.of(context)!.storyViewersLoadFailed,
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
                      AppLocalizations.of(context)!.storySeenBy(_viewCount),
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

    final summary = _summary;

    if (_rows.isEmpty) {
      return ListView(
        controller: scrollController,
        children: [
          if (summary != null) _buildSummary(summary, colorScheme),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.storyNoViewsYet,
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

    if (summary != null) {
      // The summary scrolls with the list so a short sheet never overflows.
      return ListView.builder(
        controller: scrollController,
        itemCount: _rows.length + 1,
        itemBuilder: (context, index) => index == 0
            ? _buildSummary(summary, colorScheme)
            : _buildViewerRow(_rows[index - 1], colorScheme),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: _rows.length,
      itemBuilder: (context, index) => _buildViewerRow(_rows[index], colorScheme),
    );
  }

  Widget _buildSummary(StoryViewsSummary summary, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final sticker = summary.sticker;
    final stickerBlock =
        sticker == null ? null : _buildStickerBlock(sticker, colorScheme);

    Widget stat(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );

    return Padding(
      key: const Key('story-insights-summary'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              stat(Icons.visibility_outlined,
                  l10n.storyInsightViews(summary.views)),
              stat(Icons.done_all, l10n.storyInsightCompleted(summary.completions)),
              stat(Icons.reply_outlined, l10n.storyInsightReplies(summary.replies)),
              stat(Icons.favorite_border,
                  l10n.storyInsightReactions(summary.reactions)),
            ],
          ),
          if (stickerBlock != null) ...[
            const SizedBox(height: 12),
            stickerBlock,
          ],
          const SizedBox(height: 4),
          Divider(
            height: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  /// Null when there is nothing to show (a word sticker has nothing to count).
  Widget? _buildStickerBlock(StorySummarySticker sticker, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final style = TextStyle(fontSize: 13, color: colorScheme.onSurface);
    final mutedStyle = TextStyle(
      fontSize: 13,
      color: colorScheme.onSurfaceVariant,
    );

    Widget block(List<Widget> children) => Column(
          key: const Key('story-insights-sticker'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );

    switch (sticker.type) {
      case 'poll':
      case 'quiz':
        if (sticker.options.isEmpty) return null;
        final isQuiz = sticker.type == 'quiz';
        return block([
          for (var i = 0; i < sticker.options.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  if (isQuiz && i == sticker.correctIndex)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: Icon(
                        Icons.check_circle,
                        key: Key('story-insights-correct-$i'),
                        size: 16,
                        color: Colors.green,
                        semanticLabel: l10n.storyQuizCorrect,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      sticker.options[i].text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${sticker.options[i].count}', style: mutedStyle),
                ],
              ),
            ),
          if (isQuiz && sticker.correctCount != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.storyInsightQuizCorrect(sticker.correctCount!),
                style: mutedStyle,
              ),
            ),
        ]);
      case 'correction':
        return block([
          Text(l10n.storyCorrectionsReceived(sticker.count), style: style),
        ]);
      case 'questionBox':
        // The responses list itself opens from the story viewer; the sheet
        // has no access to it, so it shows the count only.
        return block([
          Text('${l10n.storyResponsesTitle}: ${sticker.count}', style: style),
        ]);
      default:
        return null;
    }
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
          if (row.completed) ...[
            Icon(
              Icons.done_all,
              key: const Key('story-viewer-completed'),
              size: 16,
              color: colorScheme.primary,
              semanticLabel:
                  AppLocalizations.of(context)!.storyInsightCompletedMark,
            ),
            const SizedBox(width: 8),
          ],
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
