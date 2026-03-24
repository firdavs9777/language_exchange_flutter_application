import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/moments/create_moment.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/pages/moments/single_moment.dart';
import 'package:bananatalk_app/pages/moments/video_player_widget.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/services/moments_service.dart' as api;
import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/translated_moment_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MomentCard extends ConsumerStatefulWidget {
  final Moments moments;
  final VoidCallback? onRefresh;

  const MomentCard({super.key, required this.moments, this.onRefresh});

  @override
  _MomentCardState createState() => _MomentCardState();
}

class _MomentCardState extends ConsumerState<MomentCard> {
  bool isLiked = false;
  late int likeCount;
  bool isSaved = false;
  bool isExpanded = false;
  bool _likePending = false;

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
    'jp': '🇯🇵',
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
    return language.toUpperCase().substring(
      0,
      language.length > 2 ? 2 : language.length,
    );
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

  @override
  void initState() {
    super.initState();
    likeCount = widget.moments.likeCount;
    _initLikeStatus();
    _loadSavedStatus();
  }

  Future<void> _initLikeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    if (mounted && currentUserId != null) {
      setState(() {
        isLiked = widget.moments.likedUsers?.contains(currentUserId) ?? false;
      });
      debugPrint('❤️ _initLikeStatus: momentId=${widget.moments.id}, userId=$currentUserId, isLiked=$isLiked, likeCount=$likeCount, likedUsers=${widget.moments.likedUsers}');
    }
  }

  Future<void> _loadSavedStatus() async {
    // Check if moment is saved via the savedBy list from backend
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    if (mounted && currentUserId != null) {
      setState(() {
        isSaved = widget.moments.savedBy.contains(currentUserId);
      });
    }
  }

  Future<void> _toggleSave() async {
    // Optimistic update
    final previousSaved = isSaved;
    setState(() => isSaved = !isSaved);

    final result = await api.MomentsService.toggleSave(
      momentId: widget.moments.id,
      currentlySaved: previousSaved,
    );

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSaved ? AppLocalizations.of(context)!.momentSaved : AppLocalizations.of(context)!.momentUnsaved),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: const Color(0xFF00BFA5),
          ),
        );
      }
    } else {
      // Revert on error
      if (mounted) {
        setState(() => isSaved = previousSaved);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? AppLocalizations.of(context)!.failedToSave),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void toggleLike() async {
    // Prevent rapid double-taps
    if (_likePending) return;
    _likePending = true;

    // Optimistically update UI
    final previousLiked = isLiked;
    final previousCount = likeCount;

    debugPrint('❤️ toggleLike: momentId=${widget.moments.id}, wasLiked=$previousLiked, prevCount=$previousCount');

    setState(() {
      if (isLiked) {
        likeCount--;
      } else {
        likeCount++;
      }
      isLiked = !isLiked;
    });

    // Call API to persist the change
    try {
      Map<String, dynamic> result;
      if (previousLiked) {
        debugPrint('❤️ Calling dislikeMoment...');
        result = await ref
            .read(momentsServiceProvider)
            .dislikeMoment(widget.moments.id);
      } else {
        debugPrint('❤️ Calling likeMoment...');
        result = await ref
            .read(momentsServiceProvider)
            .likeMoment(widget.moments.id);
      }

      debugPrint('❤️ API result: $result');

      if (mounted) {
        setState(() {
          isLiked = result['isLiked'] ?? !previousLiked;
          likeCount = result['likeCount'] ?? previousCount;
        });
        debugPrint('❤️ Updated state: isLiked=$isLiked, likeCount=$likeCount');

        // Invalidate moments provider so fresh data (with updated likedUsers) is fetched on next load
        ref.invalidate(momentsFeedProvider);
      }
    } catch (e) {
      debugPrint('❤️ ERROR: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          isLiked = previousLiked;
          likeCount = previousCount;
        });
        debugPrint('❤️ Reverted to: isLiked=$previousLiked, likeCount=$previousCount');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      _likePending = false;
    }
  }

  void _shareMoment(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    final momentText = l10n.checkOutMoment(widget.moments.title);
    final momentUrl = 'https://banatalk.com/moment/$id';
    Share.share('$momentText\n\n$momentUrl');
  }

  void _showMoreOptions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    final isOwnMoment = currentUserId == widget.moments.user.id;

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
                  _shareMoment(context, widget.moments.id);
                },
              ),
              if (!isOwnMoment)
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: Colors.orange[700]),
                  title: Text(AppLocalizations.of(context)!.reportMoment),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => ReportDialog(
                        type: 'moment',
                        reportedId: widget.moments.id,
                        reportedUserId: widget.moments.user.id,
                      ),
                    );
                  },
                ),
              if (!isOwnMoment)
                ListTile(
                  leading: Icon(
                    Icons.report_problem,
                    color: Colors.orange[700],
                  ),
                  title: Text(AppLocalizations.of(context)!.reportUser),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => ReportDialog(
                        type: 'user',
                        reportedId: widget.moments.id,
                        reportedUserId: widget.moments.user.id,
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
                          momentToEdit: widget.moments,
                        ),
                      ),
                    );
                    // Refresh if edit was successful
                    if (result == true) {
                      widget.onRefresh?.call();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    AppLocalizations.of(context)!.delete,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final l10n = AppLocalizations.of(context)!;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(l10n.deleteMoment),
                        content: Text(l10n.thisActionCannotBeUndone),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      try {
                        await ref
                            .read(momentsServiceProvider)
                            .deleteUserMoment(id: widget.moments.id);
                        final l10n = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.momentDeleted)),
                        );
                        widget.onRefresh?.call();
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
  Widget build(BuildContext context) {
    final fullText = widget.moments.description.isEmpty
        ? widget.moments.title
        : widget.moments.description;
    final shouldShowMore = fullText.length > 150;
    final displayText = !isExpanded && shouldShowMore
        ? '${fullText.substring(0, 150)}...'
        : fullText;

    return GestureDetector(
      onTap: () async {
        Moments singleMoment = await ref
            .watch(momentsServiceProvider)
            .getSingleMoment(id: widget.moments.id);

        ref.refresh(commentsProvider(singleMoment.id));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleMoment(moment: singleMoment),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final community = await ref
                          .read(communityServiceProvider)
                          .getSingleCommunity(id: widget.moments.user.id);

                      if (community == null) {
                        if (mounted) {
                          final l10n = AppLocalizations.of(context)!;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.userNotFound)),
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
                    child: CachedCircleAvatar(
                      imageUrl: widget.moments.user.imageUrls.isNotEmpty
                          ? widget.moments.user.imageUrls[0]
                          : null,
                      radius: 22,
                      backgroundColor: context.containerColor,
                      errorWidget: Icon(
                        Icons.person,
                        size: 22,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.moments.user.name.toUpperCase(),
                              style: context.labelLarge,
                            ),
                            const SizedBox(width: 4),
                            // VIP Badge (conditionally shown)
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //       horizontal: 6, vertical: 2),
                            //   decoration: BoxDecoration(
                            //     gradient: const LinearGradient(
                            //       colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                            //     ),
                            //     borderRadius: BorderRadius.circular(4),
                            //   ),
                            //   child: const Text(
                            //     'VIP',
                            //     style: TextStyle(
                            //       fontSize: 9,
                            //       fontWeight: FontWeight.w700,
                            //       color: Colors.white,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // Native language with underline
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
                                  widget.moments.user.native_language,
                                ),
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
                            // Learning language with dots
                            Text(
                              _getLanguageCode(
                                widget.moments.user.language_to_learn,
                              ),
                              style: context.captionSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Language level dots (3 filled, 2 empty)
                            Row(
                              children: List.generate(5, (index) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 2),
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
                  // Time + More button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _showMoreOptions(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.more_horiz,
                          color: context.iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getRelativeTime(context, widget.moments.createdAt),
                        style: context.captionSmall.copyWith(color: context.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedMomentWidget(
                    momentId: widget.moments.id,
                    originalText: displayText,
                    originalLanguage: widget.moments.language,
                    existingTranslations: widget.moments.translations.isNotEmpty
                        ? widget.moments.translations
                        : null,
                    onTranslationAdded: () {
                      // Refresh the moment to get updated translations
                      if (widget.onRefresh != null) {
                        widget.onRefresh!();
                      }
                    },
                  ),
                  if (shouldShowMore)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          isExpanded
                              ? AppLocalizations.of(context)!.showLess
                              : AppLocalizations.of(context)!.showMore,
                          style: context.labelMedium.copyWith(color: context.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Video (if available)
            if (widget.moments.hasVideo && widget.moments.video != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenVideoPlayer(
                            video: widget.moments.video!,
                          ),
                        ),
                      );
                    },
                    child: MomentVideoPlayer(
                      video: widget.moments.video!,
                      height: 280,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            // Images (if no video)
            else if (widget.moments.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildImageGrid(),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    count: likeCount,
                    color: isLiked ? AppColors.error : context.iconColor,
                    onTap: toggleLike,
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    count: widget.moments.commentCount,
                    color: context.iconColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SingleMoment(
                            moment: widget.moments,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // Translate icon
                  IconButton(
                    icon: Icon(
                      Icons.translate,
                      color: context.iconColor,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Translation functionality
                    },
                  ),
                  // Gift icon
                  IconButton(
                    icon: Icon(
                      Icons.card_giftcard_outlined,
                      color: context.iconColor,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Gift functionality
                    },
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
                    onPressed: () => _shareMoment(context, widget.moments.id),
                  ),
                ],
              ),
            ),

            // Divider
            Container(height: 1, color: context.dividerColor),
          ],
        ),
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
    final imageCount = widget.moments.imageUrls.length;

    if (imageCount == 1) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageGallery(
                imageUrls: widget.moments.imageUrls,
                initialIndex: 0,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CachedImageWidget(
            imageUrl: widget.moments.imageUrls[0],
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

    // HelloTalk style: 2 images side-by-side with gap
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
                  child: _buildImageItem(widget.moments.imageUrls[0], 0),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildImageItem(widget.moments.imageUrls[1], 1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // For 3+ images, use grid
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
              widget.moments.imageUrls[index],
              index,
              isLastItem: isLastItem,
              remainingCount: isLastItem ? imageCount - 6 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageItem(
    String url,
    int index, {
    bool isLastItem = false,
    int remainingCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageGallery(
              imageUrls: widget.moments.imageUrls,
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
