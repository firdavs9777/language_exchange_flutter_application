import 'package:bananatalk_app/pages/comments/comments_main.dart';
import 'package:bananatalk_app/pages/comments/create_comment.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/moments/create_moment.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/moments_service.dart' as api;

class SingleMoment extends ConsumerStatefulWidget {
  final Moments moment;

  const SingleMoment({
    super.key,
    required this.moment,
  });

  @override
  ConsumerState<SingleMoment> createState() => _SingleMomentState();
}

class _SingleMomentState extends ConsumerState<SingleMoment> {
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0;
  bool isSaved = false;
  bool _likePending = false;
  TextEditingController commentController = TextEditingController();
  bool showCommentField = false;
  final FocusNode commentFocusNode = FocusNode();
  String? _replyToCommentId;
  String? _replyToUserName;

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
    'japanese': '🇯🇵',
    'da': '🇩🇰',
    'nl': '🇳🇱',
    'th': '🇹🇭',
    'vi': '🇻🇳',
  };

  String _getLanguageCode(String language) {
    final langLower = language.toLowerCase();
    if (langLower.contains('japan') || langLower == 'jp') return 'JP';
    if (langLower.contains('english') || langLower == 'en') return 'EN';
    if (langLower.contains('korean') || langLower == 'ko') return 'KO';
    if (langLower.contains('chinese') || langLower == 'zh') return 'ZH';
    if (langLower.contains('spanish') || langLower == 'es') return 'ES';
    if (langLower.contains('french') || langLower == 'fr') return 'FR';
    if (langLower.contains('german') || langLower == 'de') return 'DE';
    if (langLower.contains('italian') || langLower == 'it') return 'IT';
    if (langLower.contains('portuguese') || langLower == 'pt') return 'PT';
    if (langLower.contains('russian') || langLower == 'ru') return 'RU';
    if (langLower.contains('arabic') || langLower == 'ar') return 'AR';
    if (langLower.contains('hindi') || langLower == 'hi') return 'HI';
    return language.toUpperCase().substring(0, language.length > 2 ? 2 : language.length);
  }

  String _getFlagEmoji(String language) {
    final langLower = language.toLowerCase();
    if (langLower.contains('japan') || langLower == 'jp') return '🇯🇵';
    if (langLower.contains('english') || langLower == 'en') return '🇺🇸';
    if (langLower.contains('korean') || langLower == 'ko') return '🇰🇷';
    if (langLower.contains('chinese') || langLower == 'zh') return '🇨🇳';
    if (langLower.contains('spanish') || langLower == 'es') return '🇪🇸';
    if (langLower.contains('french') || langLower == 'fr') return '🇫🇷';
    if (langLower.contains('german') || langLower == 'de') return '🇩🇪';
    if (langLower.contains('italian') || langLower == 'it') return '🇮🇹';
    if (langLower.contains('portuguese') || langLower == 'pt') return '🇵🇹';
    if (langLower.contains('russian') || langLower == 'ru') return '🇷🇺';
    if (langLower.contains('arabic') || langLower == 'ar') return '🇸🇦';
    if (langLower.contains('hindi') || langLower == 'hi') return '🇮🇳';
    return _languageFlags[langLower] ?? '🌍';
  }

  String _getRelativeTime(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inMinutes < 60) {
      return l10n.minutesAgo('${difference.inMinutes}');
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo('${difference.inHours}');
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return l10n.weeksAgo((difference.inDays / 7).floor());
    }
  }

  @override
  void initState() {
    super.initState();
    likeCount = widget.moment.likeCount;
    commentCount = widget.moment.commentCount;
    _initLikeAndSaveStatus();
  }

  Future<void> _initLikeAndSaveStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    if (mounted && currentUserId != null) {
      setState(() {
        isLiked = widget.moment.likedUsers?.contains(currentUserId) ?? false;
        isSaved = widget.moment.savedBy.contains(currentUserId);
      });
    }
  }

  Future<void> _toggleSave() async {
    HapticFeedback.mediumImpact();

    final previousSaved = isSaved;
    setState(() => isSaved = !isSaved);

    final result = await api.MomentsService.toggleSave(
      momentId: widget.moment.id,
      currentlySaved: previousSaved,
    );

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSaved ? AppLocalizations.of(context)!.momentSaved : AppLocalizations.of(context)!.momentUnsaved),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF00BFA5),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => isSaved = previousSaved);
      }
    }
  }

  void incrementLike() async {
    // Prevent rapid double-taps
    if (_likePending) return;
    _likePending = true;

    // Haptic feedback for like action
    HapticFeedback.lightImpact();

    final previousLiked = isLiked;
    final previousCount = likeCount;

    setState(() {
      if (isLiked) {
        likeCount--;
      } else {
        likeCount++;
      }
      isLiked = !isLiked;
    });

    try {
      Map<String, dynamic> result;
      if (previousLiked) {
        result = await ref
            .read(momentsServiceProvider)
            .dislikeMoment(widget.moment.id);
      } else {
        result = await ref
            .read(momentsServiceProvider)
            .likeMoment(widget.moment.id);
      }

      if (mounted) {
        setState(() {
          isLiked = result['isLiked'] ?? !previousLiked;
          likeCount = result['likeCount'] ?? previousCount;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLiked = previousLiked;
          likeCount = previousCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _likePending = false;
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

  void _shareMoment() {
    final l10n = AppLocalizations.of(context)!;
    final momentText = l10n.checkOutMoment(widget.moment.title);
    final momentUrl = 'https://banatalk.com/moment/${widget.moment.id}';
    Share.share('$momentText\n\n$momentUrl');
  }

  void _showMoreOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    final isOwnMoment = currentUserId == widget.moment.user.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: AppRadius.borderXS,
                ),
              ),
              ListTile(
                leading: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: const Color(0xFF00BFA5),
                ),
                title: Text(isSaved ? AppLocalizations.of(context)!.removeFromSaved : AppLocalizations.of(context)!.saveMoment),
                onTap: () {
                  Navigator.pop(context);
                  _toggleSave();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFF00BFA5)),
                title: Text(AppLocalizations.of(context)!.share),
                onTap: () {
                  Navigator.pop(context);
                  _shareMoment();
                },
              ),
              if (!isOwnMoment)
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: Colors.orange[700]),
                  title: Text(AppLocalizations.of(context)!.report),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => ReportDialog(
                        type: 'moment',
                        reportedId: widget.moment.id,
                        reportedUserId: widget.moment.user.id,
                      ),
                    );
                  },
                ),
              if (isOwnMoment) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: Text(AppLocalizations.of(context)!.edit),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateMoment(
                          momentToEdit: widget.moment,
                        ),
                      ),
                    );
                    // Pop back to list if edit was successful
                    if (result == true && mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title:
                      Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: Text(AppLocalizations.of(context)!.deleteMoment),
                        content: Text(AppLocalizations.of(context)!.thisActionCannotBeUndone),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: Text(AppLocalizations.of(context)!.delete),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      try {
                        await ref
                            .read(momentsServiceProvider)
                            .deleteUserMoment(id: widget.moment.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.momentDeleted)),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.details,
          style: context.titleMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: context.textPrimary),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: () async {
                      final community = await ref
                          .read(communityServiceProvider)
                          .getSingleCommunity(id: widget.moment.user.id);

                      if (community == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.userNotFound)),
                          );
                        }
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SingleCommunity(community: community),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          CachedCircleAvatar(
                            imageUrl: widget.moment.user.imageUrls.isNotEmpty
                                ? widget.moment.user.imageUrls[0]
                                : null,
                            radius: 24,
                            backgroundColor: context.containerColor,
                            errorWidget: Icon(
                              Icons.person,
                              size: 24,
                              color: context.textSecondary,
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
                                      widget.moment.user.name.toUpperCase(),
                                      style: context.titleSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(bottom: 1),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: AppColors.success,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _getLanguageCode(
                                            widget.moment.user.native_language),
                                        style: context.captionSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 12,
                                      color: context.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getLanguageCode(widget
                                          .moment.user.language_to_learn),
                                      style: context.captionSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(left: 2),
                                          width: 3,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: index < 3
                                                ? context.textSecondary
                                                : context.dividerColor,
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _getRelativeTime(context, widget.moment.createdAt),
                            style: context.captionSmall.copyWith(color: context.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      widget.moment.description.isEmpty
                          ? widget.moment.title
                          : widget.moment.description,
                      style: context.bodyMedium,
                    ),
                  ),
                  if (widget.moment.imageUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildImageGrid(),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        _buildActionButton(
                          icon: isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          count: likeCount,
                          color: isLiked ? Colors.red[400]! : Colors.grey[600]!,
                          onTap: incrementLike,
                        ),
                        const SizedBox(width: 4),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          count: commentCount,
                          color: Colors.grey[600]!,
                          onTap: focusCommentField,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.translate,
                            color: context.iconColor,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.card_giftcard_outlined,
                            color: context.iconColor,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.share_outlined,
                            color: context.iconColor,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: _shareMoment,
                        ),
                      ],
                    ),
                  ),
                  if (likeCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Text(
                            '$likeCount ${AppLocalizations.of(context)!.giftsLikes}',
                            style: context.labelMedium.copyWith(color: context.textSecondary),
                          ),
                          Spacing.hGapSM,
                          Icon(Icons.arrow_forward_ios,
                              size: 12, color: context.textMuted),
                        ],
                      ),
                    ),
                  Container(
                    height: 8,
                    color: context.containerColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${AppLocalizations.of(context)!.comments} (${commentCount})',
                      style: context.titleSmall,
                    ),
                  ),
                  CommentsMain(
                    id: widget.moment.id,
                    onReply: (commentId, userName) {
                      setState(() {
                        _replyToCommentId = commentId;
                        _replyToUserName = userName;
                      });
                      commentFocusNode.requestFocus();
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          CreateComment(
            focusNode: commentFocusNode,
            id: widget.moment.id,
            onCommentAdded: updateCommentCount,
            parentCommentId: _replyToCommentId,
            replyToUserName: _replyToUserName,
            onCancelReply: () {
              setState(() {
                _replyToCommentId = null;
                _replyToUserName = null;
              });
            },
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
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count > 999
                    ? '${(count / 1000).toStringAsFixed(1)}k'
                    : '$count',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final imageCount = widget.moment.imageUrls.length;

    if (imageCount == 1) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageGallery(
                imageUrls: widget.moment.imageUrls,
                initialIndex: 0,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CachedImageWidget(
            imageUrl: widget.moment.imageUrls[0],
            width: double.infinity,
            height: 280,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8),
            errorWidget: Container(
              width: double.infinity,
              height: 280,
              color: context.containerColor,
              child: Icon(
                Icons.broken_image,
                size: 50,
                color: context.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    if (imageCount == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildImageItem(widget.moment.imageUrls[0], 0),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildImageItem(widget.moment.imageUrls[1], 1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: 1,
        ),
        itemCount: imageCount > 6 ? 6 : imageCount,
        itemBuilder: (context, index) {
          final isLastItem = index == 5 && imageCount > 6;
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildImageItem(
              widget.moment.imageUrls[index],
              index,
              isLastItem: isLastItem,
              remainingCount: isLastItem ? imageCount - 6 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageItem(String url, int index,
      {bool isLastItem = false, int remainingCount = 0}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageGallery(
              imageUrls: widget.moment.imageUrls,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedImageWidget(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: context.containerColor,
              child: Icon(
                Icons.broken_image,
                size: 30,
                color: context.textMuted,
              ),
            ),
          ),
          if (isLastItem)
            Container(
              color: Colors.black54,
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
