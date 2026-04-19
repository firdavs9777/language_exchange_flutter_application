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
import 'package:bananatalk_app/utils/app_page_route.dart';

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
  bool _showHeartAnimation = false;
  bool _showTranslation = false;
  String _cachedUserId = '';
  final GlobalKey _likeButtonKey = GlobalKey();

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
        _cachedUserId = currentUserId;
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

  void _showReactionPicker(BuildContext context) {
    final renderBox = _likeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          // Reaction bar positioned above the like button
          Positioned(
            left: buttonPos.dx - 20,
            top: buttonPos.dy - 52,
            child: Material(
              elevation: 12,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(28),
              color: Theme.of(this.context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['❤️', '🔥', '😂', '😢', '😮', '👏'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        entry.remove();
                        _reactToMoment(emoji);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  Future<void> _reactToMoment(String emoji) async {
    try {
      await api.MomentsService.reactToMoment(
        momentId: widget.moments.id,
        emoji: emoji,
      );
      ref.invalidate(momentsFeedProvider);
    } catch (e) {
      debugPrint('React to moment error: $e');
    }
  }

  Map<String, int> _groupMomentReactions() {
    final map = <String, int>{};
    for (final r in widget.moments.reactions) {
      map[r.emoji] = (map[r.emoji] ?? 0) + 1;
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  String _getCurrentUserId() {
    // SharedPreferences is async; userId is loaded during initState via _initLikeStatus/_loadSavedStatus.
    // We read it synchronously from a cached field populated in initState.
    return _cachedUserId;
  }

  void _shareMoment(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    final descriptionSnippet = widget.moments.description.length > 100
        ? '${widget.moments.description.substring(0, 100)}...'
        : widget.moments.description;
    final momentText = l10n.checkOutMoment;
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
                      AppPageRoute(
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
    final fullText = widget.moments.description;
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
          AppPageRoute(
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
                        AppPageRoute(
                          builder: (context) =>
                              SingleCommunity(community: community),
                        ),
                      );
                    },
                    child: CachedCircleAvatar(
                      imageUrl: widget.moments.user.imageUrls.isNotEmpty
                          ? widget.moments.user.imageUrls[0]
                          : null,
                      radius: 24,
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
                  if (_showTranslation)
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
                    )
                  else
                    Text(
                      displayText,
                      style: Theme.of(context).textTheme.bodyMedium,
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

            // Media area: text-only gradient, video, or images
            if (widget.moments.mediaType == 'text' &&
                widget.moments.images.isEmpty &&
                !widget.moments.hasVideo)
              _buildDoubleTapLikeArea(
                _buildGradientTextCard(widget.moments),
              )
            // Video (if available)
            else if (widget.moments.hasVideo && widget.moments.video != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildDoubleTapLikeArea(
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
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
                ),
              )
            // Images (if no video)
            else if (widget.moments.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDoubleTapLikeArea(_buildImageGrid()),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    key: _likeButtonKey,
                    onTap: toggleLike,
                    onLongPress: () => _showReactionPicker(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 22,
                            color: isLiked ? AppColors.error : context.iconColor,
                          ),
                          if (likeCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              likeCount > 999
                                  ? '${(likeCount / 1000).toStringAsFixed(1)}k'
                                  : '$likeCount',
                              style: TextStyle(
                                fontSize: 13,
                                color: isLiked ? AppColors.error : context.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    count: widget.moments.commentCount,
                    color: context.iconColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageRoute(
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
                      color: _showTranslation ? AppColors.primary : context.iconColor,
                      size: 22,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() => _showTranslation = !_showTranslation);
                    },
                  ),
                  // Gift icon
                  IconButton(
                    icon: Icon(
                      Icons.card_giftcard_outlined,
                      color: context.iconColor,
                      size: 22,
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
                      size: 22,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () => _shareMoment(context, widget.moments.id),
                  ),
                  // Save/bookmark button
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 22,
                      color: isSaved ? AppColors.primary : context.iconColor,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: _toggleSave,
                  ),
                ],
              ),
            ),

            // Engagement counts
            if (likeCount > 0 || widget.moments.commentCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (likeCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '$likeCount ${likeCount == 1 ? "like" : "likes"}',
                          style: context.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (widget.moments.commentCount > 0)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) => SingleMoment(moment: widget.moments),
                            ),
                          );
                        },
                        child: Text(
                          widget.moments.commentCount == 1
                              ? '1 comment'
                              : '${widget.moments.commentCount} comments',
                          style: context.bodySmall.copyWith(color: context.textMuted),
                        ),
                      ),
                  ],
                ),
              ),

            // Moment reaction chips
            if (widget.moments.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _groupMomentReactions().entries.map((entry) {
                    final currentUserId = _getCurrentUserId();
                    final isMyReaction = widget.moments.reactions.any(
                      (r) => r.emoji == entry.key && r.userId == currentUserId,
                    );
                    return GestureDetector(
                      onTap: () => _reactToMoment(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMyReaction
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: isMyReaction
                              ? Border.all(color: AppColors.primary, width: 1)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.key, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text('${entry.value}', style: TextStyle(fontSize: 12, color: context.textMuted)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientTextCard(Moments moment) {
    final colors = MomentGradients.getColors(
      moment.backgroundColor.isNotEmpty
          ? moment.backgroundColor
          : MomentGradients.defaultGradient,
    );
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.map((c) => Color(c)).toList(),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          moment.description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: 10,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDoubleTapLikeArea(Widget child) {
    return GestureDetector(
      onDoubleTap: () {
        toggleLike();
        setState(() => _showHeartAnimation = true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _showHeartAnimation = false);
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          if (_showHeartAnimation)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value < 0.5 ? value * 2 : (1 - value) * 2,
                  child: Transform.scale(
                    scale: 0.5 + value * 0.5,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 80,
                      shadows: [
                        Shadow(blurRadius: 20, color: Colors.black38),
                      ],
                    ),
                  ),
                );
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
            Icon(icon, size: 22, color: color),
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
            AppPageRoute(
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
          AppPageRoute(
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
