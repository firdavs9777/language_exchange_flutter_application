import 'package:bananatalk_app/pages/comments/comments_main.dart';
import 'package:bananatalk_app/pages/comments/create_comment.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/pages/profile/main/profile_moment_edit.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

class ProfileSingleMoment extends ConsumerStatefulWidget {
  final Moments moment;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const ProfileSingleMoment({
    super.key,
    required this.moment,
    this.onDeleted,
    this.onUpdated,
  });

  @override
  _ProfileSingleMomentState createState() => _ProfileSingleMomentState();
}

class _ProfileSingleMomentState extends ConsumerState<ProfileSingleMoment> {
  late Moments moment;
  late bool isLiked;
  late int likeCount;
  late int commentCount;
  bool showCommentField = false;
  final FocusNode commentFocusNode = FocusNode();

  // Language code to flag emoji mapping
  final Map<String, String> _languageFlags = {
    'en': '🇺🇸',
    'es': '🇪🇸',
    'fr': '🇫🇷',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'pt': '🇵🇹',
    'ru': '🇷🇺',
    'ja': '🇯🇵',
    'ko': '🇰🇷',
    'zh': '🇨🇳',
    'ar': '🇸🇦',
    'hi': '🇮🇳',
    'korean': '🇰🇷',
    'english': '🇺🇸',
    'spanish': '🇪🇸',
    'da': '🇩🇰',
  };

  // Mood to emoji mapping
  final Map<String, String> _moodEmojis = {
    'happy': '😊',
    'excited': '🤩',
    'sad': '😢',
    'love': '😍',
    'funny': '😂',
    'thoughtful': '🤔',
    'cool': '😎',
    'tired': '😴',
  };

  @override
  void initState() {
    super.initState();
    moment = widget.moment;
    likeCount = widget.moment.likeCount;
    commentCount = widget.moment.commentCount;
    isLiked =
        widget.moment.likedUsers?.contains(widget.moment.user.id) ?? false;
  }

  @override
  void dispose() {
    commentFocusNode.dispose();
    super.dispose();
  }

  void incrementLike() async {
    try {
      Map<String, dynamic> result;
      if (isLiked) {
        result =
            await ref.read(momentsServiceProvider).dislikeMoment(moment.id);
      } else {
        result = await ref.read(momentsServiceProvider).likeMoment(moment.id);
      }

      if (mounted) {
        setState(() {
          isLiked = result['isLiked'] ?? !isLiked;
          likeCount = result['likeCount'] ?? likeCount;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void updateCommentCount() {
    setState(() {
      commentCount++;
    });
  }

  void focusCommentField() {
    setState(() {
      showCommentField = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      commentFocusNode.requestFocus();
    });
  }

  void _shareMoment(BuildContext context) {
    final shareText = moment.description.length > 100
        ? '${moment.description.substring(0, 100)}...'
        : moment.description;
    final momentUrl = 'https://banatalk.com/moment/${moment.id}';
    Share.share('$shareText\n\n$momentUrl');
  }

  void _deleteMoment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
        context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLG,
        ),
        title: Text(
          'Delete Moment?',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This action cannot be undone.',
          style: context.bodyMedium,
        ),
            actions: [
              TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: context.labelLarge.copyWith(color: context.textSecondary),
            ),
          ),
              TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Delete',
              style: context.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final response = await ref
            .read(momentsServiceProvider)
            .deleteUserMoment(id: moment.id);
        if (response['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Moment deleted successfully'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Call the callback to refresh the list
            widget.onDeleted?.call();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _editMoment() async {
    final updatedMoment = await Navigator.push<Moments>(
      context,
      AppPageRoute(
        builder: (context) => EditMomentScreen(moment: moment),
      ),
    ).then((result) {
      // Refresh immediately when returning from edit screen
      if (mounted) {
        widget.onUpdated?.call();
      }
      return result;
    });

    if (updatedMoment != null && mounted) {
      setState(() {
        moment = updatedMoment;
      });

      // Call the callback again to ensure refresh happens
      widget.onUpdated?.call();

      // Also refresh after a small delay to ensure backend data is synced
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          widget.onUpdated?.call();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moment updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (mounted) {
      // Even if no update, refresh to ensure we have latest data
      widget.onUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageFlag =
        _languageFlags[moment.language.toLowerCase()] ?? '🌍';
    final moodEmoji = moment.mood.isNotEmpty
        ? _moodEmojis[moment.mood.toLowerCase()] ?? ''
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          GestureDetector(
            onTap: () async {
              try {
                final community = await ref
                    .read(communityServiceProvider)
                    .getSingleCommunity(id: moment.user.id);

                if (community == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not found')),
                    );
                  }
                  return;
                }

                if (mounted) {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (context) =>
                          SingleCommunity(community: community),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: Padding(
              padding: Spacing.paddingLG,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      backgroundImage: moment.user.imageUrls.isNotEmpty
                          ? NetworkImage(
                              ImageUtils.normalizeImageUrl(moment.user.imageUrls[0]))
                          : null,
                      child: moment.user.imageUrls.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 24,
                              color: AppColors.white,
                            )
                          : null,
                      onBackgroundImageError: (exception, stackTrace) {
                        // Image failed to load, will use icon fallback
                      },
                    ),
                  ),
                  Spacing.hGapMD,
                  Expanded(
        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              moment.user.name,
                              style: context.titleMedium,
                            ),
                            Spacing.hGapSM,
                            Text(
                              languageFlag,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Spacing.gapXS,
                        Row(
          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: AppRadius.borderXS,
                              ),
                              child: Text(
                                moment.category,
                                style: context.captionSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (moodEmoji.isNotEmpty) ...[
                              Spacing.hGapSM,
                              Text(moodEmoji, style: const TextStyle(fontSize: 16)),
                            ],
                            Spacing.hGapSM,
                            Text(
                              moment.createdAt.toLocal().toString().split(' ')[0],
                              style: context.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: context.textMuted),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteMoment(context);
                  } else if (value == 'edit') {
                    _editMoment();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20, color: AppColors.primary),
                            Spacing.hGapMD,
                            Text('Edit', style: context.bodyMedium),
                          ],
                    ),
                  ),
                  PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: AppColors.error),
                            Spacing.hGapMD,
                            Text('Delete', style: context.bodyMedium.copyWith(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: context.dividerColor),

          // Description
          Padding(
            padding: Spacing.paddingLG,
            child: Text(
              moment.description,
              style: context.bodyLarge.copyWith(
                color: context.textSecondary,
                height: 1.6,
              ),
            ),
          ),

          // Tags
          if (moment.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: moment.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.containerColor,
                      borderRadius: AppRadius.borderMD,
                    ),
              child: Text(
                      '#$tag',
                      style: context.labelMedium.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Images
          if (moment.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildImageGrid(),
            ),

          // Action Buttons
          Padding(
            padding: Spacing.paddingLG,
                child: Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_outline,
                  count: likeCount,
                  color: isLiked ? AppColors.error : context.textSecondary,
                  onTap: incrementLike,
                ),
                Spacing.hGapMD,
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: commentCount,
                  color: context.textSecondary,
                  onTap: focusCommentField,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  color: context.textSecondary,
                  onPressed: () => _shareMoment(context),
                ),
              ],
            ),
          ),

          // Comments Section
          if (showCommentField)
            Container(
              padding: Spacing.paddingLG,
              decoration: BoxDecoration(
                color: context.containerColor,
                border: Border(
                  top: BorderSide(color: context.dividerColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comments',
                    style: context.titleMedium,
                  ),
                  Spacing.gapMD,
                  CommentsMain(id: moment.id),
                  Spacing.gapMD,
                  CreateComment(
                    focusNode: commentFocusNode,
                    id: moment.id,
                    onCommentAdded: () {
                      updateCommentCount();
                      setState(() {
                        showCommentField = false;
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderXL,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            if (count > 0) ...[
              Spacing.hGapSM,
              Text(
                count > 999
                    ? '${(count / 1000).toStringAsFixed(1)}k'
                    : '$count',
                style: context.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final imageCount = moment.imageUrls.length;

    if (imageCount == 1) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            AppPageRoute(
              builder: (context) => ImageGallery(
                imageUrls: moment.imageUrls,
                initialIndex: 0,
              ),
            ),
          );
        },
        child: Image.network(
          ImageUtils.normalizeImageUrl(moment.imageUrls[0]),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 300,
              color: context.containerColor,
              child: Icon(
                Icons.broken_image,
                size: 50,
                color: context.textMuted,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 300,
              color: context.containerColor,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: imageCount == 2 ? 2 : 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: imageCount > 9 ? 9 : imageCount,
      itemBuilder: (context, index) {
        final url = ImageUtils.normalizeImageUrl(moment.imageUrls[index]);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              AppPageRoute(
                builder: (context) => ImageGallery(
                  imageUrls: moment.imageUrls,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: context.containerColor,
                    child: Icon(
                      Icons.broken_image,
                      size: 30,
                      color: context.textMuted,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: context.containerColor,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (index == 8 && imageCount > 9)
                Container(
                  color: AppColors.black.withOpacity(0.5),
                  child: Center(
                    child: Text(
                      '+${imageCount - 9}',
                      style: context.displaySmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
