import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/pages/stories/story_viewer_screen.dart';

/// Instagram-style highlights row for user profiles
class ProfileHighlights extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;
  final ValueNotifier<int>? refreshNotifier;
  final Community? user;

  const ProfileHighlights({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.refreshNotifier,
    this.user,
  });

  @override
  State<ProfileHighlights> createState() => _ProfileHighlightsState();
}

class _ProfileHighlightsState extends State<ProfileHighlights> {
  List<StoryHighlight> _highlights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier?.addListener(_onRefresh);
    _loadHighlights();
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefresh);
    super.dispose();
  }

  DateTime _lastLoadTime = DateTime.now();

  void _onRefresh() {
    // Only reload if more than 30 seconds since last load
    if (DateTime.now().difference(_lastLoadTime).inSeconds > 30) {
      _loadHighlights();
    }
  }

  Future<void> _loadHighlights() async {
    _lastLoadTime = DateTime.now();


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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openHighlight(StoryHighlight highlight) {
    if (highlight.stories.isEmpty) return;

    // Use widget.user if available, fallback to story's user
    final storyUser = (widget.user != null && widget.user!.name.isNotEmpty)
        ? widget.user!
        : highlight.stories.first.user;

    // Convert stories to UserStories format for the viewer
    final userStories = UserStories(
      user: storyUser,
      stories: highlight.stories,
      hasUnviewed: false,
      unviewedCount: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          userStories: [userStories],
          initialUserIndex: 0,
          isOwnStory: widget.isOwnProfile,
        ),
      ),
    ).then((_) => _loadHighlights());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Don't show if no highlights and not own profile
    if (_highlights.isEmpty && !widget.isOwnProfile) {
      return const SizedBox.shrink();
    }

    // Don't show empty "+" button in feed — only show when there are highlights or on profile
    if (_highlights.isEmpty && widget.refreshNotifier != null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (widget.isOwnProfile) _buildAddHighlight(context),
          ..._highlights.map((h) {
            return HighlightCircle(
            coverImage: h.coverImage,
            title: h.title,
            onTap: () => _openHighlight(h),
            onLongPress: widget.isOwnProfile ? () => _deleteHighlight(h) : null,
          );
          }),
        ],
      ),
    );
  }

  void _deleteHighlight(StoryHighlight highlight) async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLG,
        ),
        title: Text(
          l10n.deleteHighlightTitle,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.deleteHighlightConfirm(highlight.title),
          style: context.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: context.labelLarge.copyWith(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              l10n.delete,
              style: context.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StoriesService.deleteHighlight(highlightId: highlight.id);
        _loadHighlights(); // Refresh list
        if (mounted) {
          _showSuccessSnackBar(l10n.highlightDeletedSuccess);
        }
      } catch (e) {
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${l10n.error}: ${e.toString().replaceFirst("Exception: ", "")}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAddHighlight(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.add,
              size: 24,
              color: context.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.highlightNewBadge,
            style: context.captionSmall.copyWith(color: context.textMuted, fontSize: 10),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

/// Single highlight circle widget
class HighlightCircle extends StatelessWidget {
  final String? coverImage;
  final String title;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const HighlightCircle({
    super.key,
    this.coverImage,
    required this.title,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: coverImage != null && coverImage!.isNotEmpty
                  ? ClipOval(
                      child: CachedImageWidget(
                        imageUrl: coverImage!,
                        fit: BoxFit.cover,
                        errorWidget: Icon(
                          Icons.auto_stories,
                          size: 20,
                          color: context.textMuted,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.auto_stories,
                      size: 20,
                      color: context.textMuted,
                    ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(
                title.length > 8 ? '${title.substring(0, 8)}...' : title,
                style: context.captionSmall.copyWith(color: context.textMuted, fontSize: 10),
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
