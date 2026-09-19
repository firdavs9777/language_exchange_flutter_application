import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/pages/stories/highlights/highlight_editor_sheet.dart';
import 'package:bananatalk_app/pages/stories/archive/story_archive_screen.dart';

/// Horizontal row of story-highlight circles shown under a profile header.
///
/// - Own profile: shows a leading "+ New" circle that opens the create
///   sheet, plus one circle per highlight; long-pressing a highlight opens
///   the edit (rename/delete) sheet.
/// - Public profile: shows only existing highlights (no "+ New" circle, no
///   long-press). Renders nothing if the user has no highlights.
///
/// Tapping a circle opens [StoryViewerScreen] scoped to just that
/// highlight's stories via the `stories` list-source parameter.
class HighlightsRow extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;
  final Community? user;

  const HighlightsRow({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.user,
  });

  @override
  State<HighlightsRow> createState() => _HighlightsRowState();
}

class _HighlightsRowState extends State<HighlightsRow> {
  List<StoryHighlight> _highlights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    try {
      final response = widget.isOwnProfile
          ? await StoriesService.getMyHighlights()
          : await StoriesService.getUserHighlights(userId: widget.userId);

      if (mounted) {
        setState(() {
          _highlights = response.success ? response.data : [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openHighlight(StoryHighlight highlight) {
    if (highlight.stories.isEmpty) return;

    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => StoryViewerScreen(
          userStories: const [],
          stories: highlight.stories,
          storiesUser: widget.user,
          isOwnStory: widget.isOwnProfile,
        ),
      ),
    ).then((_) => _loadHighlights());
  }

  Future<void> _createHighlight() async {
    final created = await HighlightEditorSheet.showCreate(context);
    if (created != null) _loadHighlights();
  }

  Future<void> _editHighlight(StoryHighlight highlight) async {
    HapticFeedback.selectionClick();
    final result = await HighlightEditorSheet.showEdit(
      context,
      highlight: highlight,
    );
    if (result == 'deleted' || result == 'renamed') {
      _loadHighlights();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    // Nothing to show and nothing to add.
    if (_highlights.isEmpty && !widget.isOwnProfile) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (widget.isOwnProfile) _NewHighlightCircle(onTap: _createHighlight),
          // The archive sits beside "+ New" because it is what FEEDS
          // highlights: a highlight is made from one story id, and before
          // this the only place offering that was the live viewer — so a
          // story could be highlighted during its 24 hours and never again.
          if (widget.isOwnProfile)
            _ArchiveCircle(onTap: () async {
              await Navigator.of(context).push(
                AppPageRoute(builder: (_) => const StoryArchiveScreen()),
              );
              // A highlight may have been created in there.
              if (mounted) _loadHighlights();
            }),
          ..._highlights.map(
            (h) => _HighlightCircleItem(
              highlight: h,
              onTap: () => _openHighlight(h),
              onLongPress: widget.isOwnProfile ? () => _editHighlight(h) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewHighlightCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _NewHighlightCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Icon(Icons.add, size: 26, color: context.textMuted),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                l10n.highlightNewBadge,
                style: context.captionSmall.copyWith(
                  color: context.textMuted,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightCircleItem extends StatelessWidget {
  final StoryHighlight highlight;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _HighlightCircleItem({
    required this.highlight,
    required this.onTap,
    this.onLongPress,
  });

  String? get _coverUrl {
    if (highlight.coverImage != null && highlight.coverImage!.isNotEmpty) {
      return highlight.coverImage;
    }
    if (highlight.stories.isNotEmpty) {
      return highlight.stories.first.thumbnail;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _coverUrl;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? ClipOval(
                      child: CachedImageWidget(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: Icon(
                          Icons.auto_stories,
                          size: 22,
                          color: context.textMuted,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.auto_stories,
                      size: 22,
                      color: context.textMuted,
                    ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                highlight.title,
                style: context.captionSmall.copyWith(
                  color: context.textMuted,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Way into the story archive, shown only on your own profile.
///
/// Styled as a circle to sit in the same row as the highlights it creates,
/// rather than hidden in a menu — the archive is only useful if someone can
/// find it while looking at the highlights they want to add to.
class _ArchiveCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _ArchiveCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      key: const Key('highlights-archive-circle'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 24,
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                l10n.storyArchiveTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.captionSmall.copyWith(color: context.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
